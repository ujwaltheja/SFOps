import { Router } from 'express';
import { db } from '../database';
import { logger } from '../utils/logger';
import { AuthenticatedRequest } from '../middleware/auth';

export const packagesRoutes = Router();

// List packages
packagesRoutes.get('/', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId } = req.params;

    const result = await db.query(
      `SELECT * FROM packages WHERE tenant_id = $1 ORDER BY created_at DESC LIMIT 100`,
      [tenantId]
    );

    res.json({ data: result.rows });
  } catch (error) {
    logger.error('Failed to list packages:', error);
    res.status(500).json({ error: 'Failed to list packages' });
  }
});

// Create package
packagesRoutes.post('/', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId } = req.params;
    const { name, description, diffId, selectedComponents } = req.body;

    const manifest = {
      components: selectedComponents,
      version: '1.0',
    };

    const result = await db.query(
      `INSERT INTO packages (tenant_id, name, description, diff_id, component_count, manifest, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [tenantId, name, description, diffId, selectedComponents.length, JSON.stringify(manifest), req.user!.userId]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    logger.error('Failed to create package:', error);
    res.status(500).json({ error: 'Failed to create package' });
  }
});

// Get package
packagesRoutes.get('/:packageId', async (req: AuthenticatedRequest, res) => {
  try {
    const { tenantId, packageId } = req.params;

    const result = await db.query(
      `SELECT * FROM packages WHERE id = $1 AND tenant_id = $2`,
      [packageId, tenantId]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Package not found' });
      return;
    }

    res.json(result.rows[0]);
  } catch (error) {
    logger.error('Failed to get package:', error);
    res.status(500).json({ error: 'Failed to get package' });
  }
});
