import { db } from '../database';

export const resolvers = {
  Query: {
    orgs: async (_: any, { tenantId }: any) => {
      const result = await db.query(
        `SELECT * FROM orgs WHERE tenant_id = $1 AND deleted_at IS NULL`,
        [tenantId]
      );
      return result.rows;
    },

    org: async (_: any, { tenantId, orgId }: any) => {
      const result = await db.query(
        `SELECT * FROM orgs WHERE id = $1 AND tenant_id = $2 AND deleted_at IS NULL`,
        [orgId, tenantId]
      );
      return result.rows[0] || null;
    },

    deployments: async (_: any, { tenantId }: any) => {
      const result = await db.query(
        `SELECT * FROM deployments WHERE tenant_id = $1 ORDER BY created_at DESC LIMIT 50`,
        [tenantId]
      );
      return result.rows;
    },

    deployment: async (_: any, { tenantId, deploymentId }: any) => {
      const result = await db.query(
        `SELECT * FROM deployments WHERE id = $1 AND tenant_id = $2`,
        [deploymentId, tenantId]
      );
      return result.rows[0] || null;
    },
  },

  Deployment: {
    package: async (parent: any) => {
      if (!parent.package_id) return null;
      const result = await db.query(
        `SELECT * FROM packages WHERE id = $1`,
        [parent.package_id]
      );
      return result.rows[0] || null;
    },

    targetOrg: async (parent: any) => {
      const result = await db.query(
        `SELECT * FROM orgs WHERE id = $1`,
        [parent.target_org_id]
      );
      return result.rows[0] || null;
    },
  },
};
