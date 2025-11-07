import { Express, Router } from 'express';
import { authRoutes } from './auth';
import { orgsRoutes } from './orgs';
import { snapshotsRoutes } from './snapshots';
import { diffsRoutes } from './diffs';
import { packagesRoutes } from './packages';
import { deploymentsRoutes } from './deployments';
import { pipelinesRoutes } from './pipelines';
import { backupsRoutes } from './backups';
import { auditRoutes } from './audit';

export function setupRoutes(app: Express): void {
  const apiRouter = Router();

  // Mount route modules
  apiRouter.use('/auth', authRoutes);
  apiRouter.use('/tenants/:tenantId/orgs', orgsRoutes);
  apiRouter.use('/tenants/:tenantId/snapshots', snapshotsRoutes);
  apiRouter.use('/tenants/:tenantId/diffs', diffsRoutes);
  apiRouter.use('/tenants/:tenantId/packages', packagesRoutes);
  apiRouter.use('/tenants/:tenantId/deploys', deploymentsRoutes);
  apiRouter.use('/tenants/:tenantId/pipelines', pipelinesRoutes);
  apiRouter.use('/tenants/:tenantId/backups', backupsRoutes);
  apiRouter.use('/tenants/:tenantId/audit-logs', auditRoutes);

  // Mount API router
  app.use('/api/v1', apiRouter);
}
