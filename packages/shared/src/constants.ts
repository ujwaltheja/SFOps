// Common constants

export const PLAN_TIERS = {
  FREE: 'free',
  PROFESSIONAL: 'professional',
  ENTERPRISE: 'enterprise',
} as const;

export const USER_ROLES = {
  ADMIN: 'admin',
  DEVELOPER: 'developer',
  VIEWER: 'viewer',
} as const;

export const ORG_TYPES = {
  PRODUCTION: 'production',
  SANDBOX: 'sandbox',
  SCRATCH: 'scratch',
} as const;

export const DEPLOYMENT_STATUS = {
  PENDING: 'pending',
  RUNNING: 'running',
  SUCCESS: 'success',
  FAILED: 'failed',
  CANCELLED: 'cancelled',
} as const;

export const ORG_STATUS = {
  CONNECTED: 'connected',
  DISCONNECTED: 'disconnected',
  ERROR: 'error',
} as const;

// Rate limits per plan tier
export const RATE_LIMITS = {
  [PLAN_TIERS.FREE]: {
    deploymentsPerMonth: 10,
    orgsPerTenant: 2,
    usersPerTenant: 3,
  },
  [PLAN_TIERS.PROFESSIONAL]: {
    deploymentsPerMonth: 100,
    orgsPerTenant: 10,
    usersPerTenant: 25,
  },
  [PLAN_TIERS.ENTERPRISE]: {
    deploymentsPerMonth: -1, // unlimited
    orgsPerTenant: -1,
    usersPerTenant: -1,
  },
} as const;

// API response codes
export const API_ERROR_CODES = {
  UNAUTHORIZED: 'UNAUTHORIZED',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  RATE_LIMIT_EXCEEDED: 'RATE_LIMIT_EXCEEDED',
  SALESFORCE_API_ERROR: 'SALESFORCE_API_ERROR',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
} as const;
