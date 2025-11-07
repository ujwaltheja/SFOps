import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';
import { config } from '../config';
import { db } from '../database';
import { logger } from '../utils/logger';

export interface JWTPayload {
  userId: string;
  tenantId: string;
  email: string;
  roles: string[];
}

export class AuthService {
  async generateToken(payload: JWTPayload): Promise<string> {
    return jwt.sign(payload, config.jwtSecret, {
      expiresIn: config.jwtExpiry,
    });
  }

  async generateRefreshToken(payload: JWTPayload): Promise<string> {
    return jwt.sign(payload, config.jwtSecret, {
      expiresIn: config.jwtRefreshExpiry,
    });
  }

  async verifyToken(token: string): Promise<JWTPayload> {
    try {
      const payload = jwt.verify(token, config.jwtSecret) as JWTPayload;
      return payload;
    } catch (error) {
      logger.error('Token verification failed:', error);
      throw new Error('Invalid token');
    }
  }

  async hashPassword(password: string): Promise<string> {
    return bcrypt.hash(password, 10);
  }

  async comparePassword(password: string, hash: string): Promise<boolean> {
    return bcrypt.compare(password, hash);
  }

  async getUserByEmail(tenantId: string, email: string): Promise<any | null> {
    const result = await db.query(
      `SELECT u.*, array_agg(r.name) as roles
       FROM users u
       LEFT JOIN user_roles ur ON u.id = ur.user_id
       LEFT JOIN roles r ON ur.role_id = r.id
       WHERE u.tenant_id = $1 AND u.email = $2 AND u.deleted_at IS NULL
       GROUP BY u.id`,
      [tenantId, email]
    );

    return result.rows[0] || null;
  }

  async getUserById(userId: string): Promise<any | null> {
    const result = await db.query(
      `SELECT u.*, array_agg(r.name) as roles
       FROM users u
       LEFT JOIN user_roles ur ON u.id = ur.user_id
       LEFT JOIN roles r ON ur.role_id = r.id
       WHERE u.id = $1 AND u.deleted_at IS NULL
       GROUP BY u.id`,
      [userId]
    );

    return result.rows[0] || null;
  }

  async createUser(
    tenantId: string,
    data: {
      email: string;
      name: string;
      externalId?: string;
      provider?: string;
    }
  ): Promise<any> {
    const result = await db.query(
      `INSERT INTO users (tenant_id, email, name, external_id, provider, status)
       VALUES ($1, $2, $3, $4, $5, 'active')
       RETURNING *`,
      [tenantId, data.email, data.name, data.externalId, data.provider]
    );

    return result.rows[0];
  }

  async updateLastLogin(userId: string): Promise<void> {
    await db.query(
      `UPDATE users SET last_login_at = NOW() WHERE id = $1`,
      [userId]
    );
  }

  async getUserPermissions(userId: string): Promise<string[]> {
    const result = await db.query(
      `SELECT DISTINCT jsonb_array_elements_text(r.permissions) as permission
       FROM users u
       JOIN user_roles ur ON u.id = ur.user_id
       JOIN roles r ON ur.role_id = r.id
       WHERE u.id = $1 AND u.deleted_at IS NULL`,
      [userId]
    );

    return result.rows.map(row => row.permission);
  }

  async hasPermission(userId: string, permission: string): Promise<boolean> {
    const permissions = await this.getUserPermissions(userId);
    return permissions.includes('*') || permissions.includes(permission);
  }

  async createApiKey(
    tenantId: string,
    userId: string,
    name: string,
    permissions: string[]
  ): Promise<{ id: string; key: string }> {
    // Generate random API key
    const key = `sfops_${Math.random().toString(36).substring(2, 15)}${Math.random().toString(36).substring(2, 15)}`;
    const keyHash = await this.hashPassword(key);
    const keyPrefix = key.substring(0, 10);

    const result = await db.query(
      `INSERT INTO api_keys (tenant_id, user_id, name, key_hash, key_prefix, permissions)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id`,
      [tenantId, userId, name, keyHash, keyPrefix, JSON.stringify(permissions)]
    );

    return {
      id: result.rows[0].id,
      key, // Return the plaintext key only once
    };
  }

  async validateApiKey(key: string): Promise<any | null> {
    const keyPrefix = key.substring(0, 10);

    const result = await db.query(
      `SELECT * FROM api_keys
       WHERE key_prefix = $1 AND revoked_at IS NULL
       AND (expires_at IS NULL OR expires_at > NOW())`,
      [keyPrefix]
    );

    for (const row of result.rows) {
      const isValid = await this.comparePassword(key, row.key_hash);
      if (isValid) {
        // Update last used
        await db.query(
          `UPDATE api_keys SET last_used_at = NOW() WHERE id = $1`,
          [row.id]
        );
        return row;
      }
    }

    return null;
  }
}

export const authService = new AuthService();
