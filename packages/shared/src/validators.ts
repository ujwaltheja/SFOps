import { z } from 'zod';

// User validation schemas
export const userCreateSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['admin', 'developer', 'viewer']),
});

export const userUpdateSchema = userCreateSchema.partial();

// Tenant validation schemas
export const tenantCreateSchema = z.object({
  name: z.string().min(1).max(100),
  domain: z.string().min(1).max(100),
  planTier: z.enum(['free', 'professional', 'enterprise']),
});

export const tenantUpdateSchema = tenantCreateSchema.partial();

// Org validation schemas
export const orgCreateSchema = z.object({
  name: z.string().min(1).max(100),
  instanceUrl: z.string().url(),
  orgType: z.enum(['production', 'sandbox', 'scratch']),
  accessToken: z.string().optional(),
  refreshToken: z.string().optional(),
});

export const orgUpdateSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  status: z.enum(['connected', 'disconnected', 'error']).optional(),
});

// Deployment validation schemas
export const deploymentCreateSchema = z.object({
  name: z.string().min(1).max(100),
  sourceOrgId: z.string().uuid(),
  targetOrgId: z.string().uuid(),
  packageId: z.string().uuid().optional(),
  testLevel: z.enum(['NoTestRun', 'RunSpecifiedTests', 'RunLocalTests', 'RunAllTestsInOrg']).optional(),
  runTests: z.array(z.string()).optional(),
  checkOnly: z.boolean().optional(),
});

// Package validation schemas
export const packageCreateSchema = z.object({
  name: z.string().min(1).max(100),
  version: z.string().optional(),
  metadata: z.record(z.any()),
});

// Pipeline validation schemas
export const pipelineCreateSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().max(500).optional(),
  sourceOrgId: z.string().uuid(),
  targetOrgId: z.string().uuid(),
  schedule: z.string().optional(), // cron expression
  enabled: z.boolean().default(true),
});

export const pipelineUpdateSchema = pipelineCreateSchema.partial();

// Snapshot validation schemas
export const snapshotCreateSchema = z.object({
  orgId: z.string().uuid(),
  name: z.string().min(1).max(100),
  description: z.string().max(500).optional(),
  includeData: z.boolean().optional(),
  metadataTypes: z.array(z.string()).optional(),
});
