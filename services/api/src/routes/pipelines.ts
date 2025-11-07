import { Router } from 'express';
import { db } from '../database';
import { logger } from '../utils/logger';
import { AuthenticatedRequest } from '../middleware/auth';

export const pipelinesRoutes = Router();

// List pipelines
pipelinesRoutes.get('/', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId } = req.params;

    const result = await db.query(
      `SELECT * FROM pipelines WHERE tenant_id = $1 AND status = 'active' ORDER BY created_at DESC`,
      [tenantId]
    );

    res.json({ data: result.rows });
  } catch (error) {
    logger.error('Failed to list pipelines:', error);
    res.status(500).json({ error: 'Failed to list pipelines' });
  }
});

// Create pipeline
pipelinesRoutes.post('/', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId } = req.params;
    const { name, description, stages, triggers } = req.body;

    const config = { stages, triggers };

    const result = await db.query(
      `INSERT INTO pipelines (tenant_id, name, description, config, created_by)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [tenantId, name, description, JSON.stringify(config), req.user!.userId]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    logger.error('Failed to create pipeline:', error);
    res.status(500).json({ error: 'Failed to create pipeline' });
  }
});

// Get pipeline runs
pipelinesRoutes.get('/:pipelineId/runs', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId, pipelineId } = req.params;

    const result = await db.query(
      `SELECT * FROM pipeline_runs WHERE tenant_id = $1 AND pipeline_id = $2 ORDER BY created_at DESC LIMIT 50`,
      [tenantId, pipelineId]
    );

    res.json({ data: result.rows });
  } catch (error) {
    logger.error('Failed to list pipeline runs:', error);
    res.status(500).json({ error: 'Failed to list pipeline runs' });
  }
});
