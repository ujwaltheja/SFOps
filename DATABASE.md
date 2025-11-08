# 🗄️ SFOps Database Schema

## Overview

SFOps uses **PostgreSQL 15+** as the primary relational database for storing metadata, configuration, and operational data. The schema is designed with normalization, referential integrity, and scalability in mind.

## Schema Diagram

```
┌─────────────┐       ┌──────────────┐       ┌─────────────┐
│    users    │──────<│ org_members  │>──────│    orgs     │
└─────────────┘       └──────────────┘       └─────────────┘
       │                                             │
       │                                             │
       ▼                                             ▼
┌─────────────┐                              ┌─────────────┐
│   tokens    │                              │ credentials │
└─────────────┘                              └─────────────┘
                                                    │
                                                    │
       ┌────────────────────────────────────────────┘
       │
       ▼
┌─────────────┐       ┌──────────────┐       ┌─────────────┐
│ deployments │──────<│ deploy_logs  │       │  artifacts  │
└─────────────┘       └──────────────┘       └─────────────┘
       │                     │
       │                     │
       ▼                     ▼
┌─────────────┐       ┌──────────────┐
│  approvals  │       │   commits    │
└─────────────┘       └──────────────┘
       │
       │
       ▼
┌─────────────┐       ┌──────────────┐
│audit_logs   │       │notifications │
└─────────────┘       └──────────────┘
```

## Core Tables

### 1. users

Stores user account information and authentication details.

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  role VARCHAR(50) NOT NULL DEFAULT 'viewer',
  -- Roles: super_admin, org_admin, deployer, approver, viewer
  is_active BOOLEAN NOT NULL DEFAULT true,
  email_verified BOOLEAN NOT NULL DEFAULT false,
  last_login_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE,

  CONSTRAINT users_role_check CHECK (
    role IN ('super_admin', 'org_admin', 'deployer', 'approver', 'viewer')
  )
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_created_at ON users(created_at DESC);
```

**Fields:**
- `id`: Unique user identifier (UUID)
- `email`: User email (unique, used for login)
- `password_hash`: Bcrypt hashed password
- `role`: Global role for system-wide permissions
- `is_active`: Account status
- `email_verified`: Email verification status
- `last_login_at`: Last successful login timestamp
- `deleted_at`: Soft delete timestamp

### 2. orgs

Stores Salesforce organization configurations.

```sql
CREATE TABLE orgs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  alias VARCHAR(100) NOT NULL UNIQUE,
  org_type VARCHAR(50) NOT NULL,
  -- Types: production, sandbox, scratch, developer
  instance_url VARCHAR(500) NOT NULL,
  org_id VARCHAR(18) NOT NULL,
  api_version VARCHAR(10) NOT NULL DEFAULT '59.0',
  is_active BOOLEAN NOT NULL DEFAULT true,
  environment VARCHAR(50) NOT NULL,
  -- Environments: dev, qa, uat, staging, production

  -- Deployment settings
  test_level VARCHAR(50) NOT NULL DEFAULT 'RunLocalTests',
  -- TestLevels: NoTestRun, RunSpecifiedTests, RunLocalTests, RunAllTestsInOrg
  min_coverage_required INTEGER NOT NULL DEFAULT 75,

  -- Metadata
  metadata JSONB DEFAULT '{}',

  -- Timestamps
  last_validated_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE,

  CONSTRAINT orgs_org_type_check CHECK (
    org_type IN ('production', 'sandbox', 'scratch', 'developer')
  ),
  CONSTRAINT orgs_environment_check CHECK (
    environment IN ('dev', 'qa', 'uat', 'staging', 'production')
  ),
  CONSTRAINT orgs_test_level_check CHECK (
    test_level IN ('NoTestRun', 'RunSpecifiedTests', 'RunLocalTests', 'RunAllTestsInOrg')
  ),
  CONSTRAINT orgs_min_coverage_check CHECK (
    min_coverage_required >= 0 AND min_coverage_required <= 100
  )
);

CREATE INDEX idx_orgs_alias ON orgs(alias);
CREATE INDEX idx_orgs_environment ON orgs(environment);
CREATE INDEX idx_orgs_is_active ON orgs(is_active);
```

**Fields:**
- `id`: Unique org identifier
- `alias`: Human-readable alias (e.g., "prod", "qa-sandbox")
- `org_type`: Salesforce org type
- `instance_url`: Salesforce instance URL (e.g., https://na1.salesforce.com)
- `org_id`: 15 or 18 character Salesforce org ID
- `environment`: Deployment environment classification
- `test_level`: Default Apex test level for deployments
- `min_coverage_required`: Minimum code coverage percentage

### 3. credentials

Stores encrypted Salesforce authentication credentials.

```sql
CREATE TABLE credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,

  -- Credential type
  auth_type VARCHAR(50) NOT NULL DEFAULT 'oauth',
  -- Types: oauth, jwt, username_password

  -- Encrypted credentials (stored in Vault, reference only)
  vault_path VARCHAR(500) NOT NULL,

  -- OAuth specific
  access_token_expires_at TIMESTAMP WITH TIME ZONE,
  refresh_token_exists BOOLEAN DEFAULT false,

  -- Metadata
  last_used_at TIMESTAMP WITH TIME ZONE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE,

  CONSTRAINT credentials_auth_type_check CHECK (
    auth_type IN ('oauth', 'jwt', 'username_password')
  )
);

CREATE INDEX idx_credentials_org_id ON credentials(org_id);
CREATE INDEX idx_credentials_vault_path ON credentials(vault_path);
```

**Fields:**
- `vault_path`: Path in HashiCorp Vault where actual credentials are stored
- `auth_type`: Authentication method used
- `access_token_expires_at`: Token expiration for refresh logic
- `last_used_at`: Last time credential was used for deployment

### 4. org_members

Junction table for user-org relationships with org-specific roles.

```sql
CREATE TABLE org_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  role VARCHAR(50) NOT NULL,
  -- Org-specific roles: admin, deployer, approver, viewer

  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  UNIQUE(user_id, org_id),

  CONSTRAINT org_members_role_check CHECK (
    role IN ('admin', 'deployer', 'approver', 'viewer')
  )
);

CREATE INDEX idx_org_members_user_id ON org_members(user_id);
CREATE INDEX idx_org_members_org_id ON org_members(org_id);
CREATE INDEX idx_org_members_role ON org_members(role);
```

### 5. deployments

Core table for tracking all deployment operations.

```sql
CREATE TABLE deployments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relationships
  org_id UUID NOT NULL REFERENCES orgs(id),
  created_by UUID NOT NULL REFERENCES users(id),

  -- Deployment identification
  deployment_number SERIAL NOT NULL,
  name VARCHAR(255),
  description TEXT,

  -- Source control
  repository_url VARCHAR(500),
  branch VARCHAR(255) NOT NULL,
  commit_sha VARCHAR(40) NOT NULL,
  commit_message TEXT,

  -- Deployment type
  deployment_type VARCHAR(50) NOT NULL,
  -- Types: validate, deploy, quick_deploy, rollback
  validate_only BOOLEAN NOT NULL DEFAULT false,

  -- Test configuration
  test_level VARCHAR(50) NOT NULL DEFAULT 'RunLocalTests',
  specified_tests TEXT[], -- Array of test class names
  run_tests BOOLEAN NOT NULL DEFAULT true,

  -- Deployment options
  check_only BOOLEAN NOT NULL DEFAULT false,
  rollback_on_error BOOLEAN NOT NULL DEFAULT true,
  ignore_warnings BOOLEAN NOT NULL DEFAULT false,
  purge_on_delete BOOLEAN NOT NULL DEFAULT false,

  -- Status tracking
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
  -- Statuses: pending, queued, validating, deploying, testing,
  --           success, failed, canceled, rolled_back

  -- Salesforce deployment ID
  sf_deployment_id VARCHAR(18), -- Salesforce async deployment ID

  -- Results
  components_total INTEGER DEFAULT 0,
  components_deployed INTEGER DEFAULT 0,
  components_failed INTEGER DEFAULT 0,
  tests_total INTEGER DEFAULT 0,
  tests_passed INTEGER DEFAULT 0,
  tests_failed INTEGER DEFAULT 0,
  code_coverage_percentage DECIMAL(5,2),

  -- Timing
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  duration_seconds INTEGER,

  -- Error tracking
  error_message TEXT,
  error_stack TEXT,

  -- Approval tracking
  requires_approval BOOLEAN NOT NULL DEFAULT false,
  approval_status VARCHAR(50),
  -- Statuses: pending, approved, rejected, expired
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMP WITH TIME ZONE,

  -- Artifact reference
  artifact_id UUID REFERENCES artifacts(id),

  -- Metadata
  metadata JSONB DEFAULT '{}',

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE,

  CONSTRAINT deployments_status_check CHECK (
    status IN ('pending', 'queued', 'validating', 'deploying', 'testing',
               'success', 'failed', 'canceled', 'rolled_back', 'awaiting_approval')
  ),
  CONSTRAINT deployments_deployment_type_check CHECK (
    deployment_type IN ('validate', 'deploy', 'quick_deploy', 'rollback')
  )
);

CREATE INDEX idx_deployments_org_id ON deployments(org_id);
CREATE INDEX idx_deployments_created_by ON deployments(created_by);
CREATE INDEX idx_deployments_status ON deployments(status);
CREATE INDEX idx_deployments_branch ON deployments(branch);
CREATE INDEX idx_deployments_commit_sha ON deployments(commit_sha);
CREATE INDEX idx_deployments_created_at ON deployments(created_at DESC);
CREATE INDEX idx_deployments_sf_id ON deployments(sf_deployment_id);
```

**Key Fields:**
- `deployment_number`: Sequential number for human reference
- `deployment_type`: Type of deployment operation
- `validate_only`: Check-only deployment flag
- `sf_deployment_id`: Salesforce's async deployment ID for tracking
- `status`: Current deployment status
- Component/test metrics for tracking progress
- `requires_approval`: Production deployments flag

### 6. artifacts

Stores metadata packages and deployment artifacts.

```sql
CREATE TABLE artifacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relationships
  deployment_id UUID REFERENCES deployments(id),
  org_id UUID NOT NULL REFERENCES orgs(id),

  -- Artifact identification
  name VARCHAR(255) NOT NULL,
  version VARCHAR(50),
  artifact_type VARCHAR(50) NOT NULL,
  -- Types: package, snapshot, rollback

  -- Storage
  storage_provider VARCHAR(50) NOT NULL DEFAULT 's3',
  storage_path VARCHAR(1000) NOT NULL,
  storage_bucket VARCHAR(255),
  file_size_bytes BIGINT,
  checksum VARCHAR(64), -- SHA-256 checksum

  -- Metadata
  package_xml TEXT, -- Contents of package.xml
  file_count INTEGER DEFAULT 0,
  metadata_types TEXT[], -- Array of metadata types included

  -- Compression
  is_compressed BOOLEAN DEFAULT true,
  compression_type VARCHAR(20) DEFAULT 'gzip',

  -- Versioning
  parent_artifact_id UUID REFERENCES artifacts(id),
  is_snapshot BOOLEAN DEFAULT false,
  snapshot_timestamp TIMESTAMP WITH TIME ZONE,

  -- Metadata
  metadata JSONB DEFAULT '{}',

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE,
  deleted_at TIMESTAMP WITH TIME ZONE,

  CONSTRAINT artifacts_type_check CHECK (
    artifact_type IN ('package', 'snapshot', 'rollback')
  )
);

CREATE INDEX idx_artifacts_deployment_id ON artifacts(deployment_id);
CREATE INDEX idx_artifacts_org_id ON artifacts(org_id);
CREATE INDEX idx_artifacts_type ON artifacts(artifact_type);
CREATE INDEX idx_artifacts_created_at ON artifacts(created_at DESC);
```

### 7. deploy_logs

Stores detailed logs for each deployment operation.

```sql
CREATE TABLE deploy_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deployment_id UUID NOT NULL REFERENCES deployments(id) ON DELETE CASCADE,

  -- Log entry
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  level VARCHAR(20) NOT NULL,
  -- Levels: debug, info, warn, error
  message TEXT NOT NULL,

  -- Context
  component VARCHAR(255), -- Metadata component name
  log_type VARCHAR(50),
  -- Types: deployment, test, validation, error

  -- Structured data
  metadata JSONB DEFAULT '{}',

  CONSTRAINT deploy_logs_level_check CHECK (
    level IN ('debug', 'info', 'warn', 'error')
  )
);

CREATE INDEX idx_deploy_logs_deployment_id ON deploy_logs(deployment_id);
CREATE INDEX idx_deploy_logs_timestamp ON deploy_logs(timestamp DESC);
CREATE INDEX idx_deploy_logs_level ON deploy_logs(level);
CREATE INDEX idx_deploy_logs_type ON deploy_logs(log_type);
```

### 8. approvals

Tracks approval workflows for deployments.

```sql
CREATE TABLE approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deployment_id UUID NOT NULL REFERENCES deployments(id) ON DELETE CASCADE,

  -- Approval request
  requested_by UUID NOT NULL REFERENCES users(id),
  requested_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  -- Approval status
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
  -- Statuses: pending, approved, rejected, expired, canceled

  -- Approver info
  approver_id UUID REFERENCES users(id),
  approved_at TIMESTAMP WITH TIME ZONE,

  -- Response
  comments TEXT,
  rejection_reason TEXT,

  -- Expiration
  expires_at TIMESTAMP WITH TIME ZONE,

  -- Metadata
  metadata JSONB DEFAULT '{}',

  CONSTRAINT approvals_status_check CHECK (
    status IN ('pending', 'approved', 'rejected', 'expired', 'canceled')
  )
);

CREATE INDEX idx_approvals_deployment_id ON approvals(deployment_id);
CREATE INDEX idx_approvals_status ON approvals(status);
CREATE INDEX idx_approvals_requested_by ON approvals(requested_by);
CREATE INDEX idx_approvals_approver_id ON approvals(approver_id);
```

### 9. audit_logs

Immutable audit trail for compliance.

```sql
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Actor
  user_id UUID REFERENCES users(id),
  user_email VARCHAR(255),
  ip_address INET,
  user_agent TEXT,

  -- Action
  action VARCHAR(100) NOT NULL,
  -- Actions: user.login, deployment.create, deployment.approve,
  --          org.create, credential.update, etc.
  resource_type VARCHAR(50),
  resource_id UUID,

  -- Details
  description TEXT,
  changes JSONB, -- Before/after values

  -- Context
  org_id UUID REFERENCES orgs(id),
  deployment_id UUID REFERENCES deployments(id),

  -- Metadata
  metadata JSONB DEFAULT '{}',

  -- Timestamp (immutable)
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_resource_type ON audit_logs(resource_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_org_id ON audit_logs(org_id);
```

### 10. notifications

Tracks notification delivery.

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Recipients
  user_id UUID REFERENCES users(id),
  email VARCHAR(255),

  -- Notification details
  type VARCHAR(50) NOT NULL,
  -- Types: deployment_success, deployment_failure, approval_request,
  --        approval_approved, approval_rejected
  channel VARCHAR(50) NOT NULL,
  -- Channels: email, slack, teams, webhook

  -- Content
  subject VARCHAR(500),
  message TEXT NOT NULL,

  -- Context
  deployment_id UUID REFERENCES deployments(id),
  org_id UUID REFERENCES orgs(id),

  -- Delivery status
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
  -- Statuses: pending, sent, delivered, failed, bounced
  sent_at TIMESTAMP WITH TIME ZONE,
  delivered_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,

  -- Metadata
  metadata JSONB DEFAULT '{}',

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  CONSTRAINT notifications_status_check CHECK (
    status IN ('pending', 'sent', 'delivered', 'failed', 'bounced')
  )
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
```

### 11. tokens

Stores API tokens and refresh tokens.

```sql
CREATE TABLE tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Token details
  token_type VARCHAR(50) NOT NULL,
  -- Types: access, refresh, api_key
  token_hash VARCHAR(255) NOT NULL UNIQUE,

  -- Token metadata
  name VARCHAR(255), -- For API keys
  scopes TEXT[], -- Permissions array

  -- Expiration
  expires_at TIMESTAMP WITH TIME ZONE,
  last_used_at TIMESTAMP WITH TIME ZONE,

  -- Revocation
  is_revoked BOOLEAN NOT NULL DEFAULT false,
  revoked_at TIMESTAMP WITH TIME ZONE,
  revoked_by UUID REFERENCES users(id),

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

  CONSTRAINT tokens_type_check CHECK (
    token_type IN ('access', 'refresh', 'api_key')
  )
);

CREATE INDEX idx_tokens_user_id ON tokens(user_id);
CREATE INDEX idx_tokens_token_hash ON tokens(token_hash);
CREATE INDEX idx_tokens_type ON tokens(token_type);
CREATE INDEX idx_tokens_expires_at ON tokens(expires_at);
```

## Database Functions & Triggers

### Auto-update timestamp trigger

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orgs_updated_at BEFORE UPDATE ON orgs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_deployments_updated_at BEFORE UPDATE ON deployments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_credentials_updated_at BEFORE UPDATE ON credentials
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_org_members_updated_at BEFORE UPDATE ON org_members
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### Calculate deployment duration

```sql
CREATE OR REPLACE FUNCTION calculate_deployment_duration()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.started_at IS NOT NULL AND NEW.completed_at IS NOT NULL THEN
    NEW.duration_seconds = EXTRACT(EPOCH FROM (NEW.completed_at - NEW.started_at));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_deployments_duration BEFORE UPDATE ON deployments
  FOR EACH ROW EXECUTE FUNCTION calculate_deployment_duration();
```

## Indexes Summary

| Table | Index Purpose |
|-------|---------------|
| users | Email lookup, role filtering, activity tracking |
| orgs | Alias lookup, environment filtering, active status |
| credentials | Org relationship, Vault path lookup |
| deployments | Org filter, creator filter, status/branch lookup, time-based queries |
| artifacts | Deployment relationship, type filtering |
| deploy_logs | Deployment lookup, timestamp ordering, level filtering |
| approvals | Deployment relationship, status tracking |
| audit_logs | User activity, action filtering, time-based compliance queries |
| notifications | User inbox, status tracking, time ordering |

## Data Retention Policy

| Table | Retention Period | Action |
|-------|------------------|--------|
| deployments | 12 months | Archive to cold storage |
| deploy_logs | 6 months | Archive to cold storage |
| audit_logs | 7 years | Never delete (compliance) |
| artifacts | 90 days | Delete from S3 and DB |
| notifications | 30 days | Soft delete |

## Migration Strategy

```bash
# Create database
createdb sfops

# Run migrations
npm run migrate

# Seed initial data (dev only)
npm run seed

# Rollback last migration
npm run migrate:rollback

# Reset database (dev only)
npm run migrate:reset
```

## Connection Pooling

```javascript
// Recommended pool configuration
{
  max: 20,              // Maximum pool size
  min: 5,               // Minimum pool size
  idle: 10000,          // 10 seconds idle timeout
  acquire: 30000,       // 30 seconds acquire timeout
  evict: 1000           // 1 second eviction interval
}
```

## Backup Strategy

1. **Daily automated backups** at 2 AM UTC
2. **Point-in-time recovery** enabled (7-day retention)
3. **Pre-deployment snapshots** for production
4. **Cross-region replication** for disaster recovery

## Performance Considerations

1. **Partitioning**: Consider partitioning `deploy_logs` by month for large installations
2. **Archival**: Move old deployments to archive tables
3. **Vacuum**: Regular VACUUM ANALYZE for statistics
4. **Connection pooling**: Use PgBouncer for connection management
5. **Read replicas**: For reporting and analytics workloads

---

For migration files and seed data, see `/database/migrations/` directory.
