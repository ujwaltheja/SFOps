import { Router } from 'express';
import { db } from '../database';
import { vaultService } from '../services/vault';
import { SalesforceClient } from '@sfops/salesforce-client';
import { logger } from '../utils/logger';
import { AuthenticatedRequest } from '../middleware/auth';

export const orgsRoutes = Router();

// List orgs
orgsRoutes.get('/', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId } = req.params;

    const result = await db.query(
      `SELECT id, name, environment, instance_url, salesforce_org_id, username, status, last_synced_at, created_at
       FROM orgs
       WHERE tenant_id = $1 AND deleted_at IS NULL
       ORDER BY created_at DESC`,
      [tenantId]
    );

    res.json({ data: result.rows });
  } catch (error) {
    logger.error('Failed to list orgs:', error);
    res.status(500).json({ error: 'Failed to list orgs' });
  }
});

// Get org by ID
orgsRoutes.get('/:orgId', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId, orgId } = req.params;

    const result = await db.query(
      `SELECT id, name, environment, instance_url, salesforce_org_id, username, status, last_synced_at, metadata, created_at
       FROM orgs
       WHERE id = $1 AND tenant_id = $2 AND deleted_at IS NULL`,
      [orgId, tenantId]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Org not found' });
      return;
    }

    res.json(result.rows[0]);
  } catch (error) {
    logger.error('Failed to get org:', error);
    res.status(500).json({ error: 'Failed to get org' });
  }
});

// Create org connection (initiate OAuth)
orgsRoutes.post('/', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId } = req.params;
    const { name, environment, instanceUrl } = req.body;

    // Create pending org record
    const result = await db.query(
      `INSERT INTO orgs (tenant_id, name, environment, instance_url, status, created_by)
       VALUES ($1, $2, $3, $4, 'pending', $5)
       RETURNING id`,
      [tenantId, name, environment, instanceUrl || 'https://login.salesforce.com', req.user!.userId]
    );

    const orgId = result.rows[0].id;

    // Generate OAuth URL
    const state = `${tenantId}:${orgId}`;
    const oauthUrl = SalesforceClient.getAuthorizationUrl(
      process.env.SALESFORCE_CLIENT_ID!,
      process.env.SALESFORCE_CALLBACK_URL!,
      state
    );

    res.status(201).json({
      orgId,
      oauthUrl,
      state,
    });
  } catch (error) {
    logger.error('Failed to create org:', error);
    res.status(500).json({ error: 'Failed to create org' });
  }
});

// OAuth callback handler
orgsRoutes.post('/:orgId/oauth/callback', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId, orgId } = req.params;
    const { code, state } = req.body;

    // Complete OAuth flow
    const credentials = await SalesforceClient.authorizeFromCode(
      process.env.SALESFORCE_CLIENT_ID!,
      process.env.SALESFORCE_CLIENT_SECRET!,
      process.env.SALESFORCE_CALLBACK_URL!,
      code
    );

    // Store credentials in Vault
    await vaultService.storeSalesforceCredentials(tenantId, orgId, credentials);

    // Get org info
    const client = new SalesforceClient(credentials);
    const orgInfo = await client.getOrgInfo();

    // Update org record
    await db.query(
      `UPDATE orgs
       SET salesforce_org_id = $1,
           username = $2,
           instance_url = $3,
           status = 'connected',
           vault_path = $4,
           metadata = $5,
           last_synced_at = NOW()
       WHERE id = $6 AND tenant_id = $7`,
      [
        orgInfo.org.Id,
        orgInfo.identity.username,
        credentials.instanceUrl,
        `secret/data/tenants/${tenantId}/orgs/${orgId}/salesforce`,
        JSON.stringify(orgInfo),
        orgId,
        tenantId,
      ]
    );

    res.json({ success: true, org: { id: orgId, status: 'connected' } });
  } catch (error) {
    logger.error('Failed to complete OAuth:', error);
    res.status(500).json({ error: 'Failed to complete OAuth' });
  }
});

// Delete org
orgsRoutes.delete('/:orgId', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId, orgId } = req.params;

    // Soft delete
    await db.query(
      `UPDATE orgs SET deleted_at = NOW() WHERE id = $1 AND tenant_id = $2`,
      [orgId, tenantId]
    );

    // Revoke credentials from Vault
    await vaultService.revokeSalesforceCredentials(tenantId, orgId);

    res.status(204).send();
  } catch (error) {
    logger.error('Failed to delete org:', error);
    res.status(500).json({ error: 'Failed to delete org' });
  }
});
