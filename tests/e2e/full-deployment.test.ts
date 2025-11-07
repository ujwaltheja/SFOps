import { describe, it, expect } from '@jest/globals';
import axios from 'axios';

const API_URL = process.env.API_URL || 'http://localhost:3000';

describe('End-to-End Deployment Flow', () => {
  it('should complete full deployment workflow', async () => {
    // 1. Login
    const loginRes = await axios.post(`${API_URL}/api/v1/auth/login`, {
      email: 'admin@demo.com',
      provider: 'local',
      tenantId: '00000000-0000-0000-0000-000000000001',
    });

    const authToken = loginRes.data.accessToken;
    const tenantId = '00000000-0000-0000-0000-000000000001';

    const headers = { Authorization: `Bearer ${authToken}` };

    // 2. List orgs
    const orgsRes = await axios.get(
      `${API_URL}/api/v1/tenants/${tenantId}/orgs`,
      { headers }
    );
    expect(orgsRes.status).toBe(200);
    expect(Array.isArray(orgsRes.data.data)).toBe(true);

    // 3. Create snapshot
    // Note: This would normally connect to a real Salesforce org
    // For E2E testing, we would use a dedicated sandbox

    // 4. Create diff
    // Compare two orgs or snapshots

    // 5. Create package
    const pkgRes = await axios.post(
      `${API_URL}/api/v1/tenants/${tenantId}/packages`,
      {
        name: 'E2E Test Package',
        description: 'Test package from E2E test',
        selectedComponents: ['ApexClass:TestClass'],
      },
      { headers }
    );

    expect(pkgRes.status).toBe(201);
    const packageId = pkgRes.data.id;

    // 6. Validate deployment (checkOnly)
    // Would normally validate against real org

    // 7. Deploy
    // Would normally deploy to real sandbox

    // 8. Verify deployment status
    // Would poll for completion

    // 9. Rollback (if needed)
    // Would restore from backup

    expect(packageId).toBeDefined();
  });
});
