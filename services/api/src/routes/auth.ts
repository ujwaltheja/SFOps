import { Router } from 'express';
import { authService } from '../services/auth';
import { SalesforceClient } from '@sfops/salesforce-client';
import { config } from '../config';
import { logger } from '../utils/logger';

export const authRoutes = Router();

// OAuth state storage (use Redis in production)
const oauthStates = new Map<string, { tenantId: string; redirectUri: string }>();

// Initiate Salesforce OAuth
authRoutes.post('/salesforce/authorize', async (req, res) => {
  try {
    const { tenantId, redirectUri } = req.body;
    const state = Math.random().toString(36).substring(7);

    oauthStates.set(state, { tenantId, redirectUri });

    const authUrl = SalesforceClient.getAuthorizationUrl(
      config.salesforceClientId!,
      config.salesforceCallbackUrl,
      state
    );

    res.json({ authUrl, state });
  } catch (error) {
    logger.error('Failed to initiate Salesforce OAuth:', error);
    res.status(500).json({ error: 'Failed to initiate authorization' });
  }
});

// Salesforce OAuth callback
authRoutes.post('/salesforce/callback', async (req, res) => {
  try {
    const { code, state } = req.body;

    const stateData = oauthStates.get(state);
    if (!stateData) {
      res.status(400).json({ error: 'Invalid state' });
      return;
    }

    oauthStates.delete(state);

    const credentials = await SalesforceClient.authorizeFromCode(
      config.salesforceClientId!,
      config.salesforceClientSecret!,
      config.salesforceCallbackUrl,
      code
    );

    res.json({
      success: true,
      credentials,
    });
  } catch (error) {
    logger.error('Failed to complete Salesforce OAuth:', error);
    res.status(500).json({ error: 'Failed to complete authorization' });
  }
});

// SSO login (Google, SAML, etc.)
authRoutes.post('/login', async (req, res) => {
  try {
    const { provider, email, tenantId } = req.body;

    // For demo purposes - implement actual SSO flow
    let user = await authService.getUserByEmail(tenantId, email);

    if (!user) {
      user = await authService.createUser(tenantId, {
        email,
        name: email.split('@')[0],
        provider,
      });
    }

    await authService.updateLastLogin(user.id);

    const payload = {
      userId: user.id,
      tenantId: user.tenant_id,
      email: user.email,
      roles: user.roles || [],
    };

    const accessToken = await authService.generateToken(payload);
    const refreshToken = await authService.generateRefreshToken(payload);

    res.json({
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        roles: user.roles,
      },
    });
  } catch (error) {
    logger.error('Login failed:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// Refresh token
authRoutes.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    const payload = await authService.verifyToken(refreshToken);
    const newAccessToken = await authService.generateToken(payload);

    res.json({ accessToken: newAccessToken });
  } catch (error) {
    logger.error('Token refresh failed:', error);
    res.status(401).json({ error: 'Invalid refresh token' });
  }
});

// Create API key
authRoutes.post('/api-keys', async (req, res) => {
  try {
    const { name, permissions } = req.body;
    // Get from authenticated user
    const userId = 'user-id'; // From req.user
    const tenantId = 'tenant-id'; // From req.user

    const apiKey = await authService.createApiKey(tenantId, userId, name, permissions);

    res.json(apiKey);
  } catch (error) {
    logger.error('Failed to create API key:', error);
    res.status(500).json({ error: 'Failed to create API key' });
  }
});
