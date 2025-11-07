export const typeDefs = `#graphql
  type Org {
    id: ID!
    name: String!
    environment: String!
    status: String!
    instanceUrl: String!
    lastSyncedAt: String
  }

  type Deployment {
    id: ID!
    status: String!
    checkOnly: Boolean!
    progress: Progress!
    startedAt: String
    completedAt: String
    package: Package
    targetOrg: Org
  }

  type Progress {
    total: Int!
    completed: Int!
    failed: Int!
  }

  type Package {
    id: ID!
    name: String!
    description: String
    componentCount: Int!
  }

  type Query {
    orgs(tenantId: ID!): [Org!]!
    org(tenantId: ID!, orgId: ID!): Org
    deployments(tenantId: ID!): [Deployment!]!
    deployment(tenantId: ID!, deploymentId: ID!): Deployment
  }

  type Subscription {
    deploymentStatus(deploymentId: ID!): Deployment!
  }
`;
