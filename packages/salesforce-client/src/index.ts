import jsforce from 'jsforce';
import JSZip from 'jszip';
import axios from 'axios';
import { parseStringPromise } from 'xml2js';

export interface SalesforceCredentials {
  accessToken: string;
  refreshToken: string;
  instanceUrl: string;
}

export interface MetadataComponent {
  type: string;
  name: string;
  content?: string;
  metadata?: any;
}

export interface DeployResult {
  id: string;
  status: string;
  success: boolean;
  details: any;
}

export class SalesforceClient {
  private conn: jsforce.Connection;

  constructor(credentials: SalesforceCredentials) {
    this.conn = new jsforce.Connection({
      instanceUrl: credentials.instanceUrl,
      accessToken: credentials.accessToken,
      refreshToken: credentials.refreshToken,
      version: '59.0',
    });
  }

  // OAuth flow helpers
  static getAuthorizationUrl(clientId: string, redirectUri: string, state: string): string {
    const oauth2 = new jsforce.OAuth2({
      clientId,
      redirectUri,
    });
    return oauth2.getAuthorizationUrl({ state, scope: 'api refresh_token' });
  }

  static async authorizeFromCode(
    clientId: string,
    clientSecret: string,
    redirectUri: string,
    code: string
  ): Promise<SalesforceCredentials> {
    const oauth2 = new jsforce.OAuth2({
      clientId,
      clientSecret,
      redirectUri,
    });

    const conn = new jsforce.Connection({ oauth2, version: '59.0' });
    const userInfo = await conn.authorize(code);

    return {
      accessToken: conn.accessToken!,
      refreshToken: conn.refreshToken!,
      instanceUrl: conn.instanceUrl!,
    };
  }

  // Refresh access token
  async refreshAccessToken(clientId: string, clientSecret: string): Promise<string> {
    const oauth2 = new jsforce.OAuth2({
      clientId,
      clientSecret,
    });

    this.conn.oauth2 = oauth2;
    await this.conn.refresh(this.conn.refreshToken!);
    return this.conn.accessToken!;
  }

  // Fetch org info
  async getOrgInfo(): Promise<any> {
    const identity = await this.conn.identity();
    const org = await this.conn.query('SELECT Id, Name, InstanceName, OrganizationType FROM Organization LIMIT 1');
    return {
      identity,
      org: org.records[0],
    };
  }

  // List metadata types
  async listMetadataTypes(): Promise<any[]> {
    const describe = await this.conn.metadata.describe();
    return describe.metadataObjects;
  }

  // List metadata components
  async listMetadata(type: string): Promise<any[]> {
    try {
      const result = await this.conn.metadata.list([{ type }]);
      return Array.isArray(result) ? result : [result];
    } catch (error) {
      console.error(`Error listing metadata type ${type}:`, error);
      return [];
    }
  }

  // Read metadata components
  async readMetadata(type: string, fullNames: string[]): Promise<any[]> {
    if (fullNames.length === 0) return [];

    try {
      const result = await this.conn.metadata.read(type, fullNames);
      return Array.isArray(result) ? result : [result];
    } catch (error) {
      console.error(`Error reading metadata ${type}:`, error);
      return [];
    }
  }

  // Retrieve metadata package
  async retrieveMetadata(types: { name: string; members: string[] }[]): Promise<Buffer> {
    const packageXml = this.buildPackageXml(types);

    return new Promise((resolve, reject) => {
      this.conn.metadata.retrieve({
        apiVersion: '59.0',
        unpackaged: packageXml,
      }).stream().pipe(this.collectBuffer((buffer) => {
        resolve(buffer);
      }, reject));
    });
  }

  // Create snapshot of all metadata
  async createSnapshot(): Promise<{
    components: MetadataComponent[];
    types: any[];
  }> {
    const metadataTypes = await this.listMetadataTypes();
    const components: MetadataComponent[] = [];

    // Focus on commonly deployed types
    const typesToRetrieve = [
      'ApexClass', 'ApexTrigger', 'ApexPage', 'ApexComponent',
      'CustomObject', 'CustomField', 'ValidationRule',
      'WorkflowRule', 'Flow', 'Layout', 'CustomTab',
      'Profile', 'PermissionSet', 'CustomApplication',
    ];

    for (const metadataType of metadataTypes) {
      if (!typesToRetrieve.includes(metadataType.xmlName)) continue;

      const items = await this.listMetadata(metadataType.xmlName);

      for (const item of items) {
        components.push({
          type: metadataType.xmlName,
          name: item.fullName,
        });
      }
    }

    return { components, types: metadataTypes };
  }

  // Deploy metadata
  async deploy(
    zipBuffer: Buffer,
    options: {
      checkOnly?: boolean;
      runTests?: boolean;
      testLevel?: 'NoTestRun' | 'RunSpecifiedTests' | 'RunLocalTests' | 'RunAllTestsInOrg';
      runTests?: string[];
    } = {}
  ): Promise<string> {
    const deployOptions: any = {
      checkOnly: options.checkOnly || false,
      testLevel: options.testLevel || 'NoTestRun',
      rollbackOnError: true,
      singlePackage: true,
    };

    if (options.testLevel === 'RunSpecifiedTests' && options.runTests) {
      deployOptions.runTests = options.runTests;
    }

    const deploy = this.conn.metadata.deploy(zipBuffer, deployOptions);
    return deploy.id;
  }

  // Check deployment status
  async checkDeployStatus(deployId: string): Promise<DeployResult> {
    const result = await this.conn.metadata.checkDeployStatus(deployId, true);

    return {
      id: deployId,
      status: result.status,
      success: result.success,
      details: result,
    };
  }

  // Cancel deployment
  async cancelDeploy(deployId: string): Promise<void> {
    await this.conn.metadata.cancelDeploy(deployId);
  }

  // Build package.xml
  private buildPackageXml(types: { name: string; members: string[] }[]): any {
    return {
      types: types.map(t => ({
        name: t.name,
        members: t.members,
      })),
      version: '59.0',
    };
  }

  // Helper to collect stream buffer
  private collectBuffer(onComplete: (buffer: Buffer) => void, onError: (error: Error) => void) {
    const chunks: Buffer[] = [];
    return {
      write(chunk: Buffer) {
        chunks.push(chunk);
      },
      end() {
        onComplete(Buffer.concat(chunks));
      },
      on(event: string, handler: Function) {
        if (event === 'error') {
          // Error handling
        }
      },
    };
  }

  // Query records
  async query<T = any>(soql: string): Promise<T[]> {
    const result = await this.conn.query(soql);
    return result.records as T[];
  }

  // Execute anonymous Apex
  async executeAnonymous(apexCode: string): Promise<any> {
    return this.conn.tooling.executeAnonymous(apexCode);
  }
}
