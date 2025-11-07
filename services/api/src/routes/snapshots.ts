import { Router } from 'express';
import { db } from '../database';
import { logger } from '../utils/logger';
import { AuthenticatedRequest } from '../middleware/auth';
import { Connection, WorkflowClient } from '@temporalio/client';
import { config } from '../config';

export const snapshotsRoutes = Router();

// List snapshots
snapshotsRoutes.get('/', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId } = req.params;
    const { orgId } = req.query;

    let query = `
      SELECT s.*, o.name as org_name
      FROM snapshots s
      LEFT JOIN orgs o ON s.org_id = o.id
      WHERE s.tenant_id = $1
    `;

    const params: any[] = [tenantId];

    if (orgId) {
      params.push(orgId);
      query += ` AND s.org_id = $${params.length}`;
    }

    query += ` ORDER BY s.created_at DESC LIMIT 100`;

    const result = await db.query(query, params);

    res.json({ data: result.rows });
  } catch (error) {
    logger.error('Failed to list snapshots:', error);
    res.status(500).json({ error: 'Failed to list snapshots' });
  }
});

// Create snapshot
snapshotsRoutes.post('/', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId } = req.params;
    const { orgId, description, metadataTypes } = req.body;

    // Create snapshot record
    const result = await db.query(
      `INSERT INTO snapshots (tenant_id, org_id, description, metadata_types, status, created_by)
       VALUES ($1, $2, $3, $4, 'pending', $5)
       RETURNING *`,
      [tenantId, orgId, description, metadataTypes || null, req.user!.userId]
    );

    const snapshot = result.rows[0];

    // Start snapshot workflow
    const connection = await Connection.connect({ address: config.temporalAddress });
    const client = new WorkflowClient({ connection, namespace: config.temporalNamespace });

    await client.start('snapshotWorkflow', {
      taskQueue: 'snapshot-queue',
      workflowId: `snapshot-${snapshot.id}`,
      args: [{
        snapshotId: snapshot.id,
        tenantId,
        orgId,
        metadataTypes,
      }],
    });

    res.status(202).json(snapshot);
  } catch (error) {
    logger.error('Failed to create snapshot:', error);
    res.status(500).json({ error: 'Failed to create snapshot' });
  }
});

// Get snapshot
snapshotsRoutes.get('/:snapshotId', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId, snapshotId } = req.params;

    const result = await db.query(
      `SELECT * FROM snapshots WHERE id = $1 AND tenant_id = $2`,
      [snapshotId, tenantId]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Snapshot not found' });
      return;
    }

    res.json(result.rows[0]);
  } catch (error) {
    logger.error('Failed to get snapshot:', error);
    res.status(500).json({ error: 'Failed to get snapshot' });
  }
});
