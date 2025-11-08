import vault, { client as VaultClient } from 'node-vault';

export interface VaultConfig {
  endpoint: string;
  token?: string;
  roleId?: string;
  secretId?: string;
  namespace?: string;
}

export interface SecretData {
  [key: string]: any;
}

export class VaultClientWrapper {
  private client: VaultClient;
  private readonly basePath: string;

  constructor(config: VaultConfig) {
    this.client = vault({
      endpoint: config.endpoint,
      token: config.token,
      namespace: config.namespace,
    });
    
    this.basePath = 'secret/data/sfops';
  }

  /**
   * Authenticate using AppRole
   */
  async authenticateAppRole(roleId: string, secretId: string): Promise<void> {
    const result = await this.client.approleLogin({
      role_id: roleId,
      secret_id: secretId,
    });
    
    this.client.token = result.auth.client_token;
  }

  /**
   * Store a secret
   */
  async setSecret(path: string, data: SecretData): Promise<void> {
    const fullPath = `${this.basePath}/${path}`;
    await this.client.write(fullPath, { data });
  }

  /**
   * Retrieve a secret
   */
  async getSecret(path: string): Promise<SecretData | null> {
    try {
      const fullPath = `${this.basePath}/${path}`;
      const result = await this.client.read(fullPath);
      return result.data.data;
    } catch (error: any) {
      if (error.response?.statusCode === 404) {
        return null;
      }
      throw error;
    }
  }

  /**
   * Delete a secret
   */
  async deleteSecret(path: string): Promise<void> {
    const fullPath = `${this.basePath}/${path}`;
    await this.client.delete(fullPath);
  }

  /**
   * List secrets at a path
   */
  async listSecrets(path: string = ''): Promise<string[]> {
    try {
      const fullPath = `secret/metadata/sfops/${path}`;
      const result = await this.client.list(fullPath);
      return result.data.keys || [];
    } catch (error: any) {
      if (error.response?.statusCode === 404) {
        return [];
      }
      throw error;
    }
  }

  /**
   * Store Salesforce credentials for a tenant
   */
  async setSalesforceCredentials(
    tenantId: string,
    orgId: string,
    credentials: {
      accessToken: string;
      refreshToken?: string;
      instanceUrl: string;
    }
  ): Promise<void> {
    await this.setSecret(`tenants/${tenantId}/orgs/${orgId}`, credentials);
  }

  /**
   * Retrieve Salesforce credentials for a tenant
   */
  async getSalesforceCredentials(
    tenantId: string,
    orgId: string
  ): Promise<{
    accessToken: string;
    refreshToken?: string;
    instanceUrl: string;
  } | null> {
    return await this.getSecret(`tenants/${tenantId}/orgs/${orgId}`);
  }

  /**
   * Delete Salesforce credentials for a tenant
   */
  async deleteSalesforceCredentials(
    tenantId: string,
    orgId: string
  ): Promise<void> {
    await this.deleteSecret(`tenants/${tenantId}/orgs/${orgId}`);
  }

  /**
   * Store encryption key for tenant
   */
  async setEncryptionKey(tenantId: string, key: string): Promise<void> {
    await this.setSecret(`tenants/${tenantId}/encryption-key`, { key });
  }

  /**
   * Retrieve encryption key for tenant
   */
  async getEncryptionKey(tenantId: string): Promise<string | null> {
    const data = await this.getSecret(`tenants/${tenantId}/encryption-key`);
    return data?.key || null;
  }

  /**
   * Health check
   */
  async healthCheck(): Promise<boolean> {
    try {
      await this.client.health();
      return true;
    } catch {
      return false;
    }
  }
}

export default VaultClientWrapper;
