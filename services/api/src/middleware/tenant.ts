import { Request, Response, NextFunction } from 'express';
import { AuthenticatedRequest } from './auth';

export async function tenantMiddleware(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  // Extract tenant ID from path params or user context
  const tenantIdFromPath = req.params.tenantId;

  if (req.user && tenantIdFromPath) {
    // Verify tenant access
    if (req.user.tenantId !== tenantIdFromPath) {
      res.status(403).json({ error: 'Access denied to this tenant' });
      return;
    }
  }

  next();
}
