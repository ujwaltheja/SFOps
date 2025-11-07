import { describe, it, expect, beforeAll, afterAll } from '@jest/globals';
import axios from 'axios';
import { Pool } from 'pg';

const API_URL = process.env.API_URL || 'http://localhost:3000';
const db = new Pool({ connectionString: process.env.DATABASE_URL });

describe('Deployment Integration Tests', () => {
  let authToken: string;
  let tenantId: string;
  let orgId: string;
  let packageId: string;

  beforeAll(async () => {
    // Authenticate
    const loginRes = await axios.post(`${API_URL}/api/v1/auth/login`, {
      email: 'admin@demo.com',
      provider: 'local',
      tenantId: '00000000-0000-0000-0000-000000000001',
    });

    authToken = loginRes.data.accessToken;
    tenantId = '00000000-0000-0000-0000-000000000001';

    // Create test org
    const orgRes = await db.query(
      `INSERT INTO orgs (tenant_id, name, environment, instance_url, status)
       VALUES ($1, 'Test Org', 'sandbox', 'https://test.salesforce.com', 'connected')
       RETURNING id`,
      [tenantId]
    );
    orgId = orgRes.rows[0].id;

    // Create test package
    const pkgRes = await db.query(
      `INSERT INTO packages (tenant_id, name, manifest)
       VALUES ($1, 'Test Package', '{"components": []}')
       RETURNING id`,
      [tenantId]
    );
    packageId = pkgRes.rows[0].id;
  });

  afterAll(async () => {
    // Cleanup
    await db.query(`DELETE FROM orgs WHERE id = $1`, [orgId]);
    await db.query(`DELETE FROM packages WHERE id = $1`, [packageId]);
    await db.end();
  });

  it('should create a deployment', async () => {
    const res = await axios.post(
      `${API_URL}/api/v1/tenants/${tenantId}/deploys`,
      {
        packageId,
        targetOrgId: orgId,
        checkOnly: true,
      },
      {
        headers: { Authorization: `Bearer ${authToken}` },
      }
    );

    expect(res.status).toBe(202);
    expect(res.data).toHaveProperty('id');
    expect(res.data.status).toBe('pending');
  });

  it('should get deployment status', async () => {
    // Create deployment first
    const createRes = await axios.post(
      `${API_URL}/api/v1/tenants/${tenantId}/deploys`,
      {
        packageId,
        targetOrgId: orgId,
        checkOnly: true,
      },
      {
        headers: { Authorization: `Bearer ${authToken}` },
      }
    );

    const deploymentId = createRes.data.id;

    // Get status
    const statusRes = await axios.get(
      `${API_URL}/api/v1/tenants/${tenantId}/deploys/${deploymentId}`,
      {
        headers: { Authorization: `Bearer ${authToken}` },
      }
    );

    expect(statusRes.status).toBe(200);
    expect(statusRes.data.id).toBe(deploymentId);
  });

  it('should reject deployment without authentication', async () => {
    await expect(
      axios.post(`${API_URL}/api/v1/tenants/${tenantId}/deploys`, {
        packageId,
        targetOrgId: orgId,
      })
    ).rejects.toThrow();
  });
});
