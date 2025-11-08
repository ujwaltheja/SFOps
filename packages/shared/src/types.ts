// Common types shared across the platform

export interface Tenant {
  id: string;
  name: string;
  domain: string;
  planTier: 'free' | 'professional' | 'enterprise';
  createdAt: Date;
  updatedAt: Date;
}

export interface User {
  id: string;
  email: string;
  name: string;
  tenantId: string;
  role: 'admin' | 'developer' | 'viewer';
  createdAt: Date;
  updatedAt: Date;
}

export interface SalesforceOrg {
  id: string;
  tenantId: string;
  name: string;
  instanceUrl: string;
  orgType: 'production' | 'sandbox' | 'scratch';
  status: 'connected' | 'disconnected' | 'error';
  createdAt: Date;
  updatedAt: Date;
}

export interface Deployment {
  id: string;
  tenantId: string;
  name: string;
  sourceOrgId: string;
  targetOrgId: string;
  status: 'pending' | 'running' | 'success' | 'failed' | 'cancelled';
  startedAt?: Date;
  completedAt?: Date;
  createdBy: string;
  createdAt: Date;
}

export interface Package {
  id: string;
  tenantId: string;
  name: string;
  version: string;
  metadata: Record<string, any>;
  createdAt: Date;
}

export interface AuditLog {
  id: string;
  tenantId: string;
  userId: string;
  action: string;
  resourceType: string;
  resourceId: string;
  metadata: Record<string, any>;
  ipAddress?: string;
  userAgent?: string;
  createdAt: Date;
}

export interface DeploymentStep {
  id: string;
  deploymentId: string;
  stepNumber: number;
  name: string;
  status: 'pending' | 'running' | 'success' | 'failed' | 'skipped';
  logs?: string;
  startedAt?: Date;
  completedAt?: Date;
}

export interface Snapshot {
  id: string;
  tenantId: string;
  orgId: string;
  name: string;
  description?: string;
  metadata: Record<string, any>;
  createdBy: string;
  createdAt: Date;
}

export interface Pipeline {
  id: string;
  tenantId: string;
  name: string;
  description?: string;
  sourceOrgId: string;
  targetOrgId: string;
  schedule?: string; // cron expression
  enabled: boolean;
  createdAt: Date;
  updatedAt: Date;
}
