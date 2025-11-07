import { Request, Response, NextFunction } from 'express';
import { AuthenticatedRequest } from './auth';
import { db } from '../database';
import { logger } from '../utils/logger';

export async function auditMiddleware(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  // Only audit state-changing operations
  if (!['POST', 'PUT', 'PATCH', 'DELETE'].includes(req.method)) {
    return next();
  }

  // Skip audit for non-authenticated requests
  if (!req.user) {
    return next();
  }

  // Capture response
  const originalSend = res.send;
  res.send = function (data: any) {
    res.send = originalSend;

    // Log audit entry asynchronously
    setImmediate(async () => {
      try {
        const action = `${req.method} ${req.path}`;
        const resourceType = extractResourceType(req.path);
        const resourceId = extractResourceId(req.path);

        await db.query(
          `INSERT INTO audit_logs (tenant_id, user_id, action, resource_type, resource_id, details, ip_address, user_agent)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
          [
            req.user!.tenantId,
            req.user!.userId,
            action,
            resourceType,
            resourceId,
            JSON.stringify({ body: req.body, query: req.query }),
            req.ip,
            req.get('user-agent'),
          ]
        );
      } catch (error) {
        logger.error('Failed to create audit log:', error);
      }
    });

    return originalSend.call(this, data);
  };

  next();
}

function extractResourceType(path: string): string {
  const match = path.match(/\/api\/v\d+\/tenants\/[^/]+\/([^/]+)/);
  return match ? match[1] : 'unknown';
}

function extractResourceId(path: string): string | null {
  const match = path.match(/\/([a-f0-9-]{36})/);
  return match ? match[1] : null;
}
