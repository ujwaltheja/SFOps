-- SFOps Initial Schema Migration
-- Version: 1
-- Description: Create all core tables

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Tenants table
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    plan VARCHAR(50) NOT NULL DEFAULT 'free',
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    encryption_key_id VARCHAR(255),
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_tenants_slug ON tenants(slug);
CREATE INDEX idx_tenants_status ON tenants(status) WHERE deleted_at IS NULL;

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    external_id VARCHAR(255),
    provider VARCHAR(50),
    avatar_url TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(tenant_id, email)
);

CREATE INDEX idx_users_tenant ON users(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_external_id ON users(external_id);

-- Roles table
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '[]',
    is_system BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tenant_id, name)
);

CREATE INDEX idx_roles_tenant ON roles(tenant_id);

-- User roles junction table
CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, role_id)
);

CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role_id);

-- Salesforce orgs table
CREATE TABLE orgs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    name VARCHAR(255) NOT NULL,
    environment VARCHAR(50) NOT NULL,
    instance_url VARCHAR(255) NOT NULL,
    salesforce_org_id VARCHAR(18),
    username VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    vault_path VARCHAR(500),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_orgs_tenant ON orgs(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_orgs_status ON orgs(status);
CREATE INDEX idx_orgs_environment ON orgs(environment);

-- Metadata snapshots table
CREATE TABLE snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    org_id UUID NOT NULL REFERENCES orgs(id),
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    component_count INTEGER DEFAULT 0,
    size_bytes BIGINT DEFAULT 0,
    storage_path VARCHAR(500),
    checksum VARCHAR(64),
    metadata_types TEXT[],
    error_message TEXT,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_snapshots_tenant ON snapshots(tenant_id);
CREATE INDEX idx_snapshots_org ON snapshots(org_id);
CREATE INDEX idx_snapshots_status ON snapshots(status);
CREATE INDEX idx_snapshots_created ON snapshots(created_at DESC);

-- Snapshot components table
CREATE TABLE snapshot_components (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    snapshot_id UUID NOT NULL REFERENCES snapshots(id) ON DELETE CASCADE,
    component_type VARCHAR(100) NOT NULL,
    component_name VARCHAR(500) NOT NULL,
    file_path TEXT,
    content_hash VARCHAR(64),
    size_bytes INTEGER,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_snapshot_components_snapshot ON snapshot_components(snapshot_id);
CREATE INDEX idx_snapshot_components_type ON snapshot_components(component_type);
CREATE INDEX idx_snapshot_components_hash ON snapshot_components(content_hash);
CREATE INDEX idx_snapshot_components_composite ON snapshot_components(snapshot_id, component_type, component_name);

-- Diffs table
CREATE TABLE diffs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    source_org_id UUID NOT NULL REFERENCES orgs(id),
    target_org_id UUID NOT NULL REFERENCES orgs(id),
    source_snapshot_id UUID REFERENCES snapshots(id),
    target_snapshot_id UUID REFERENCES snapshots(id),
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    change_count INTEGER DEFAULT 0,
    storage_path VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_diffs_tenant ON diffs(tenant_id);
CREATE INDEX idx_diffs_orgs ON diffs(source_org_id, target_org_id);
CREATE INDEX idx_diffs_created ON diffs(created_at DESC);

-- Diff changes table
CREATE TABLE diff_changes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    diff_id UUID NOT NULL REFERENCES diffs(id) ON DELETE CASCADE,
    component_type VARCHAR(100) NOT NULL,
    component_name VARCHAR(500) NOT NULL,
    change_type VARCHAR(50) NOT NULL,
    source_hash VARCHAR(64),
    target_hash VARCHAR(64),
    dependencies TEXT[],
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_diff_changes_diff ON diff_changes(diff_id);
CREATE INDEX idx_diff_changes_type ON diff_changes(change_type);
CREATE INDEX idx_diff_changes_component ON diff_changes(component_type, component_name);

-- Deployment packages table
CREATE TABLE packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    diff_id UUID REFERENCES diffs(id),
    component_count INTEGER DEFAULT 0,
    manifest JSONB NOT NULL DEFAULT '{}',
    storage_path VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_packages_tenant ON packages(tenant_id);
CREATE INDEX idx_packages_diff ON packages(diff_id);
CREATE INDEX idx_packages_created ON packages(created_at DESC);

-- Deployments table
CREATE TABLE deployments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    package_id UUID REFERENCES packages(id),
    target_org_id UUID NOT NULL REFERENCES orgs(id),
    pipeline_run_id UUID,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    check_only BOOLEAN DEFAULT FALSE,
    run_tests BOOLEAN DEFAULT FALSE,
    test_level VARCHAR(50),
    salesforce_deploy_id VARCHAR(18),
    progress JSONB DEFAULT '{"total": 0, "completed": 0, "failed": 0}',
    error_message TEXT,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_deployments_tenant ON deployments(tenant_id);
CREATE INDEX idx_deployments_package ON deployments(package_id);
CREATE INDEX idx_deployments_org ON deployments(target_org_id);
CREATE INDEX idx_deployments_status ON deployments(status);
CREATE INDEX idx_deployments_created ON deployments(created_at DESC);

-- Deployment results table
CREATE TABLE deployment_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deployment_id UUID NOT NULL REFERENCES deployments(id) ON DELETE CASCADE,
    component_type VARCHAR(100) NOT NULL,
    component_name VARCHAR(500) NOT NULL,
    status VARCHAR(50) NOT NULL,
    message TEXT,
    line_number INTEGER,
    column_number INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_deployment_results_deployment ON deployment_results(deployment_id);
CREATE INDEX idx_deployment_results_status ON deployment_results(status);

-- Backups table
CREATE TABLE backups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    org_id UUID NOT NULL REFERENCES orgs(id),
    deployment_id UUID REFERENCES deployments(id),
    snapshot_id UUID REFERENCES snapshots(id),
    backup_type VARCHAR(50) NOT NULL,
    storage_path VARCHAR(500),
    size_bytes BIGINT DEFAULT 0,
    retention_days INTEGER DEFAULT 90,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_backups_tenant ON backups(tenant_id);
CREATE INDEX idx_backups_org ON backups(org_id);
CREATE INDEX idx_backups_deployment ON backups(deployment_id);
CREATE INDEX idx_backups_expires ON backups(expires_at);

-- Pipelines table
CREATE TABLE pipelines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    config JSONB NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_pipelines_tenant ON pipelines(tenant_id);
CREATE INDEX idx_pipelines_status ON pipelines(status);

-- Pipeline triggers table
CREATE TABLE pipeline_triggers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pipeline_id UUID NOT NULL REFERENCES pipelines(id) ON DELETE CASCADE,
    trigger_type VARCHAR(50) NOT NULL,
    config JSONB NOT NULL DEFAULT '{}',
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_pipeline_triggers_pipeline ON pipeline_triggers(pipeline_id);
CREATE INDEX idx_pipeline_triggers_type ON pipeline_triggers(trigger_type);

-- Pipeline runs table
CREATE TABLE pipeline_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    pipeline_id UUID NOT NULL REFERENCES pipelines(id),
    trigger_type VARCHAR(50) NOT NULL,
    trigger_metadata JSONB DEFAULT '{}',
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    current_stage INTEGER DEFAULT 0,
    error_message TEXT,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_pipeline_runs_tenant ON pipeline_runs(tenant_id);
CREATE INDEX idx_pipeline_runs_pipeline ON pipeline_runs(pipeline_id);
CREATE INDEX idx_pipeline_runs_status ON pipeline_runs(status);
CREATE INDEX idx_pipeline_runs_created ON pipeline_runs(created_at DESC);

-- Pipeline approvals table
CREATE TABLE pipeline_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pipeline_run_id UUID NOT NULL REFERENCES pipeline_runs(id) ON DELETE CASCADE,
    stage_index INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    comment TEXT
);

CREATE INDEX idx_pipeline_approvals_run ON pipeline_approvals(pipeline_run_id);
CREATE INDEX idx_pipeline_approvals_status ON pipeline_approvals(status);

-- Git repositories table
CREATE TABLE git_repositories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    provider VARCHAR(50) NOT NULL,
    repository_url VARCHAR(500) NOT NULL,
    default_branch VARCHAR(100) DEFAULT 'main',
    vault_path VARCHAR(500),
    webhook_secret VARCHAR(255),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE INDEX idx_git_repos_tenant ON git_repositories(tenant_id);

-- Git branch mappings table
CREATE TABLE git_branch_mappings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    repository_id UUID NOT NULL REFERENCES git_repositories(id) ON DELETE CASCADE,
    branch_pattern VARCHAR(255) NOT NULL,
    target_org_id UUID NOT NULL REFERENCES orgs(id),
    pipeline_id UUID REFERENCES pipelines(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_git_mappings_repo ON git_branch_mappings(repository_id);
CREATE INDEX idx_git_mappings_org ON git_branch_mappings(target_org_id);

-- Audit logs table
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id UUID,
    details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_tenant ON audit_logs(tenant_id, created_at DESC);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);

-- API keys table
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    user_id UUID REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(64) NOT NULL,
    key_prefix VARCHAR(10) NOT NULL,
    permissions JSONB DEFAULT '[]',
    last_used_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    revoked_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_api_keys_tenant ON api_keys(tenant_id);
CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_user ON api_keys(user_id);

-- Usage metrics table
CREATE TABLE usage_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    metric_type VARCHAR(100) NOT NULL,
    metric_value INTEGER NOT NULL DEFAULT 1,
    metadata JSONB DEFAULT '{}',
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_usage_metrics_tenant ON usage_metrics(tenant_id, recorded_at DESC);
CREATE INDEX idx_usage_metrics_type ON usage_metrics(metric_type, recorded_at DESC);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_orgs_updated_at BEFORE UPDATE ON orgs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_packages_updated_at BEFORE UPDATE ON packages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pipelines_updated_at BEFORE UPDATE ON pipelines FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
