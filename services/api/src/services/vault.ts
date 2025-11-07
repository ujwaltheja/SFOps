import vault from 'node-vault';
import { config } from '../config';
import { logger } from '../utils/logger';

class VaultService {
  private client: any;
  private initialized: boolean = false;

  async initialize(): Promise<void> {
    try {
      this.client = vault({
        endpoint: config.vaultAddr,
        token: config.vaultToken,
      });

      // Test connection
      await this.client.health();
      this.initialized = true;
      logger.info('Vault client initialized');
    } catch (error) {
      logger.error('Failed to initialize Vault client:', error);
      throw error;
    }
  }

  async writeSecret(path: string, data: Record<string, any>): Promise<void> {
    if (!this.initialized) {
      throw new Error('Vault client not initialized');
    }

    try {
      await this.client.write(path, { data });
      logger.debug({ path }, 'Secret written to Vault');
    } catch (error) {
      logger.error({ path, error }, 'Failed to write secret to Vault');
      throw error;
    }
  }

  async readSecret(path: string): Promise<Record<string, any> | null> {
    if (!this.initialized) {
      throw new Error('Vault client not initialized');
    }

    try {
      const result = await this.client.read(path);
      return result.data.data || result.data;
    } catch (error: any) {
      if (error.response?.statusCode === 404) {
        return null;
      }
      logger.error({ path, error }, 'Failed to read secret from Vault');
      throw error;
    }
  }

  async deleteSecret(path: string): Promise<void> {
    if (!this.initialized) {
      throw new Error('Vault client not initialized');
    }

    try {
      await this.client.delete(path);
      logger.debug({ path }, 'Secret deleted from Vault');
    } catch (error) {
      logger.error({ path, error }, 'Failed to delete secret from Vault');
      throw error;
    }
  }

  // Encrypt data using Vault's transit engine
  async encrypt(keyName: string, plaintext: string): Promise<string> {
    if (!this.initialized) {
      throw new Error('Vault client not initialized');
    }

    try {
      const result = await this.client.write(`transit/encrypt/${keyName}`, {
        plaintext: Buffer.from(plaintext).toString('base64'),
      });
      return result.data.ciphertext;
    } catch (error) {
      logger.error({ keyName, error }, 'Failed to encrypt data');
      throw error;
    }
  }

  // Decrypt data using Vault's transit engine
  async decrypt(keyName: string, ciphertext: string): Promise<string> {
    if (!this.initialized) {
      throw new Error('Vault client not initialized');
    }

    try {
      const result = await this.client.write(`transit/decrypt/${keyName}`, {
        ciphertext,
      });
      return Buffer.from(result.data.plaintext, 'base64').toString();
    } catch (error) {
      logger.error({ keyName, error }, 'Failed to decrypt data');
      throw error;
    }
  }

  // Store Salesforce OAuth credentials
  async storeSalesforceCredentials(
    tenantId: string,
    orgId: string,
    credentials: {
      accessToken: string;
      refreshToken: string;
      instanceUrl: string;
    }
  ): Promise<void> {
    const path = `secret/data/tenants/${tenantId}/orgs/${orgId}/salesforce`;
    await this.writeSecret(path, credentials);
  }

  // Retrieve Salesforce OAuth credentials
  async getSalesforceCredentials(
    tenantId: string,
    orgId: string
  ): Promise<{
    accessToken: string;
    refreshToken: string;
    instanceUrl: string;
  } | null> {
    const path = `secret/data/tenants/${tenantId}/orgs/${orgId}/salesforce`;
    return await this.readSecret(path);
  }

  // Revoke Salesforce credentials
  async revokeSalesforceCredentials(tenantId: string, orgId: string): Promise<void> {
    const path = `secret/data/tenants/${tenantId}/orgs/${orgId}/salesforce`;
    await this.deleteSecret(path);
  }
}

export const vaultService = new VaultService();

export async function initializeVault(): Promise<void> {
  logger.info('Initializing Vault client...');
  await vaultService.initialize();
}
