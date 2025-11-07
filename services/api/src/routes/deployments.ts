import { Router } from 'express';
import { db } from '../database';
import { logger } from '../utils/logger';
import { AuthenticatedRequest } from '../middleware/auth';
import { deploymentWorkflow } from '../workflows/deployment';
import { Connection, WorkflowClient } from '@temporalio/client';
import { config } from '../config';

export const deploymentsRoutes = Router();

let temporalClient: WorkflowClient;

// Initialize Temporal client
async function getTemporalClient(): Promise<WorkflowClient> {
  if (!temporalClient) {
    const connection = await Connection.connect({ address: config.temporalAddress });
    temporalClient = new WorkflowClient({ connection, namespace: config.temporalNamespace });
  }
  return temporalClient;
}

// List deployments
deploymentsRoutes.get('/', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId } = req.params;
    const { status, orgId } = req.query;

    let query = `
      SELECT d.*, p.name as package_name, o.name as org_name
      FROM deployments d
      LEFT JOIN packages p ON d.package_id = p.id
      LEFT JOIN orgs o ON d.target_org_id = o.id
      WHERE d.tenant_id = $1
    `;

    const params: any[] = [tenantId];

    if (status) {
      params.push(status);
      query += ` AND d.status = $${params.length}`;
    }

    if (orgId) {
      params.push(orgId);
      query += ` AND d.target_org_id = $${params.length}`;
    }

    query += ` ORDER BY d.created_at DESC LIMIT 100`;

    const result = await db.query(query, params);

    res.json({ data: result.rows });
  } catch (error) {
    logger.error('Failed to list deployments:', error);
    res.status(500).json({ error: 'Failed to list deployments' });
  }
});

// Get deployment by ID
deploymentsRoutes.get('/:deployId', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId, deployId } = req.params;

    const result = await db.query(
      `SELECT d.*, p.name as package_name, o.name as org_name
       FROM deployments d
       LEFT JOIN packages p ON d.package_id = p.id
       LEFT JOIN orgs o ON d.target_org_id = o.id
       WHERE d.id = $1 AND d.tenant_id = $2`,
      [deployId, tenantId]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Deployment not found' });
      return;
    }

    // Get deployment results
    const resultsQuery = await db.query(
      `SELECT * FROM deployment_results WHERE deployment_id = $1 ORDER BY created_at`,
      [deployId]
    );

    const deployment = {
      ...result.rows[0],
      results: resultsQuery.rows,
    };

    res.json(deployment);
  } catch (error) {
    logger.error('Failed to get deployment:', error);
    res.status(500).json({ error: 'Failed to get deployment' });
  }
});

// Start deployment
deploymentsRoutes.post('/', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId } = req.params;
    const { packageId, targetOrgId, checkOnly, runTests, testLevel } = req.body;

    // Create deployment record
    const result = await db.query(
      `INSERT INTO deployments (tenant_id, package_id, target_org_id, check_only, run_tests, test_level, status, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, 'pending', $7)
       RETURNING *`,
      [tenantId, packageId, targetOrgId, checkOnly || false, runTests || false, testLevel || 'NoTestRun', req.user!.userId]
    );

    const deployment = result.rows[0];

    // Start Temporal workflow
    const client = await getTemporalClient();
    const handle = await client.start(deploymentWorkflow, {
      taskQueue: 'deployment-queue',
      workflowId: `deployment-${deployment.id}`,
      args: [{
        deploymentId: deployment.id,
        tenantId,
        packageId,
        targetOrgId,
        checkOnly: checkOnly || false,
        runTests: runTests || false,
        testLevel: testLevel || 'NoTestRun',
      }],
    });

    logger.info({ deploymentId: deployment.id, workflowId: handle.workflowId }, 'Deployment workflow started');

    res.status(202).json(deployment);
  } catch (error) {
    logger.error('Failed to start deployment:', error);
    res.status(500).json({ error: 'Failed to start deployment' });
  }
});

// Get deployment status (SSE)
deploymentsRoutes.get('/:deployId/status', async (req: AuthenticatedRequest, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  const { deployId } = req.params;

  // Send initial status
  const sendStatus = async () => {
    const result = await db.query(
      `SELECT * FROM deployments WHERE id = $1`,
      [deployId]
    );

    if (result.rows.length > 0) {
      res.write(`data: ${JSON.stringify(result.rows[0])}\n\n`);
    }
  };

  // Send status every 2 seconds
  const interval = setInterval(sendStatus, 2000);

  // Send initial status
  await sendStatus();

  // Clean up on close
  req.on('close', () => {
    clearInterval(interval);
    res.end();
  });
});

// Rollback deployment
deploymentsRoutes.post('/:deployId/rollback', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId, deployId } = req.params;

    // Get deployment
    const result = await db.query(
      `SELECT * FROM deployments WHERE id = $1 AND tenant_id = $2`,
      [deployId, tenantId]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Deployment not found' });
      return;
    }

    const deployment = result.rows[0];

    // Find pre-deployment backup
    const backupResult = await db.query(
      `SELECT * FROM backups WHERE deployment_id = $1 AND backup_type = 'pre_deploy' ORDER BY created_at DESC LIMIT 1`,
      [deployId]
    );

    if (backupResult.rows.length === 0) {
      res.status(404).json({ error: 'No backup found for this deployment' });
      return;
    }

    const backup = backupResult.rows[0];

    // Create rollback deployment
    const rollbackResult = await db.query(
      `INSERT INTO deployments (tenant_id, target_org_id, status, created_by)
       VALUES ($1, $2, 'pending', $3)
       RETURNING *`,
      [tenantId, deployment.target_org_id, req.user!.userId]
    );

    const rollbackDeployment = rollbackResult.rows[0];

    // Start rollback workflow
    const client = await getTemporalClient();
    await client.start('rollbackWorkflow', {
      taskQueue: 'deployment-queue',
      workflowId: `rollback-${rollbackDeployment.id}`,
      args: [{
        deploymentId: rollbackDeployment.id,
        tenantId,
        targetOrgId: deployment.target_org_id,
        backupId: backup.id,
        snapshotId: backup.snapshot_id,
      }],
    });

    res.status(202).json(rollbackDeployment);
  } catch (error) {
    logger.error('Failed to start rollback:', error);
    res.status(500).json({ error: 'Failed to start rollback' });
  }
});
