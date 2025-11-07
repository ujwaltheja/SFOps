import { Router } from 'express';
import { db } from '../database';
import { logger } from '../utils/logger';
import { AuthenticatedRequest } from '../middleware/auth';

export const backupsRoutes = Router();

// List backups
backupsRoutes.get('/', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId } = req.params;
    const { orgId } = req.query;

    let query = `SELECT * FROM backups WHERE tenant_id = $1`;
    const params: any[] = [tenantId];

    if (orgId) {
      params.push(orgId);
      query += ` AND org_id = $${params.length}`;
    }

    query += ` ORDER BY created_at DESC LIMIT 100`;

    const result = await db.query(query, params);

    res.json({ data: result.rows });
  } catch (error) {
    logger.error('Failed to list backups:', error);
    res.status(500).json({ error: 'Failed to list backups' });
  }
});
