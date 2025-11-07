import { Request, Response, NextFunction } from 'express';
import { authService } from '../services/auth';
import { logger } from '../utils/logger';

export interface AuthenticatedRequest extends Request {
  user?: {
    userId: string;
    tenantId: string;
    email: string;
    roles: string[];
  };
}

export async function authMiddleware(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  // Skip auth for public endpoints
  const publicPaths = ['/health', '/ready', '/metrics', '/auth/login', '/auth/callback'];
  if (publicPaths.some(path => req.path.startsWith(path))) {
    return next();
  }

  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      res.status(401).json({ error: 'No authorization header' });
      return;
    }

    // Bearer token
    if (authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);

      try {
        const payload = await authService.verifyToken(token);
        req.user = payload;
        return next();
      } catch (error) {
        res.status(401).json({ error: 'Invalid token' });
        return;
      }
    }

    // API Key
    if (authHeader.startsWith('ApiKey ')) {
      const apiKey = authHeader.substring(7);

      const keyData = await authService.validateApiKey(apiKey);
      if (!keyData) {
        res.status(401).json({ error: 'Invalid API key' });
        return;
      }

      // Load user data
      const user = await authService.getUserById(keyData.user_id);
      if (!user) {
        res.status(401).json({ error: 'User not found' });
        return;
      }

      req.user = {
        userId: user.id,
        tenantId: user.tenant_id,
        email: user.email,
        roles: user.roles || [],
      };

      return next();
    }

    res.status(401).json({ error: 'Invalid authorization header format' });
  } catch (error) {
    logger.error('Authentication error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export function requirePermission(permission: string) {
  return async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const hasPermission = await authService.hasPermission(req.user.userId, permission);
    if (!hasPermission) {
      res.status(403).json({ error: 'Insufficient permissions' });
      return;
    }

    next();
  };
}
