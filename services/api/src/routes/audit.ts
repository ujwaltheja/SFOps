import { Router } from 'express';
import { db } from '../database';
import { logger } from '../utils/logger';
import { AuthenticatedRequest } from '../middleware/auth';

export const auditRoutes = Router();

// Get audit logs
auditRoutes.get('/', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId } = req.params;
    const { startDate, endDate, userId, action } = req.query;

    let query = `SELECT * FROM audit_logs WHERE tenant_id = $1`;
    const params: any[] = [tenantId];

    if (startDate) {
      params.push(startDate);
      query += ` AND created_at >= $${params.length}`;
    }

    if (endDate) {
      params.push(endDate);
      query += ` AND created_at <= $${params.length}`;
    }

    if (userId) {
      params.push(userId);
      query += ` AND user_id = $${params.length}`;
    }

    if (action) {
      params.push(action);
      query += ` AND action = $${params.length}`;
    }

    query += ` ORDER BY created_at DESC LIMIT 1000`;

    const result = await db.query(query, params);

    res.json({ data: result.rows });
  } catch (error) {
    logger.error('Failed to get audit logs:', error);
    res.status(500).json({ error: 'Failed to get audit logs' });
  }
});
