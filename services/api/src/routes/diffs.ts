import { Router } from 'express';
import { db } from '../database';
import { logger } from '../utils/logger';
import { AuthenticatedRequest } from '../middleware/auth';

export const diffsRoutes = Router();

// Create diff
diffsRoutes.post('/', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId } = req.params;
    const { sourceOrgId, targetOrgId, sourceSnapshotId, targetSnapshotId } = req.body;

    // Create diff record
    const result = await db.query(
      `INSERT INTO diffs (tenant_id, source_org_id, target_org_id, source_snapshot_id, target_snapshot_id, status, created_by)
       VALUES ($1, $2, $3, $4, $5, 'pending', $6)
       RETURNING *`,
      [tenantId, sourceOrgId, targetOrgId, sourceSnapshotId, targetSnapshotId, req.user!.userId]
    );

    const diff = result.rows[0];

    // TODO: Start diff computation workflow

    res.status(202).json(diff);
  } catch (error) {
    logger.error('Failed to create diff:', error);
    res.status(500).json({ error: 'Failed to create diff' });
  }
});

// Get diff
diffsRoutes.get('/:diffId', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId, diffId } = req.params;

    const result = await db.query(
      `SELECT * FROM diffs WHERE id = $1 AND tenant_id = $2`,
      [diffId, tenantId]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Diff not found' });
      return;
    }

    // Get diff changes
    const changesResult = await db.query(
      `SELECT * FROM diff_changes WHERE diff_id = $1 ORDER BY component_type, component_name`,
      [diffId]
    );

    const diffData = {
      ...result.rows[0],
      changes: changesResult.rows,
    };

    res.json(diffData);
  } catch (error) {
    logger.error('Failed to get diff:', error);
    res.status(500).json({ error: 'Failed to get diff' });
  }
});
