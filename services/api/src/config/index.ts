import { z } from 'zod';

const configSchema = z.object({
  // Server
  nodeEnv: z.enum(['development', 'staging', 'production']).default('development'),
  port: z.number().default(3000),
  version: z.string().default('1.0.0'),

  // Database
  databaseUrl: z.string(),
  databasePoolMin: z.number().default(2),
  databasePoolMax: z.number().default(10),

  // Redis
  redisUrl: z.string(),

  // Vault
  vaultAddr: z.string(),
  vaultToken: z.string().optional(),
  vaultRoleId: z.string().optional(),
  vaultSecretId: z.string().optional(),

  // Temporal
  temporalAddress: z.string().default('localhost:7233'),
  temporalNamespace: z.string().default('default'),

  // S3/Object Storage
  s3Endpoint: z.string().optional(),
  s3AccessKey: z.string(),
  s3SecretKey: z.string(),
  s3Bucket: z.string().default('sfops-snapshots'),
  s3Region: z.string().default('us-east-1'),

  // Auth
  jwtSecret: z.string(),
  jwtExpiry: z.string().default('7d'),
  jwtRefreshExpiry: z.string().default('30d'),

  // OAuth
  googleClientId: z.string().optional(),
  googleClientSecret: z.string().optional(),
  googleCallbackUrl: z.string().optional(),

  // SAML
  samlEntryPoint: z.string().optional(),
  samlIssuer: z.string().optional(),
  samlCert: z.string().optional(),

  // Salesforce
  salesforceClientId: z.string().optional(),
  salesforceClientSecret: z.string().optional(),
  salesforceCallbackUrl: z.string().default('http://localhost:3000/api/v1/auth/salesforce/callback'),

  // Observability
  jaegerEndpoint: z.string().optional(),
  logLevel: z.enum(['trace', 'debug', 'info', 'warn', 'error']).default('info'),

  // Features
  enableMetrics: z.boolean().default(true),
  enableTracing: z.boolean().default(true),
  enableAuditLog: z.boolean().default(true),
});

export type Config = z.infer<typeof configSchema>;

function loadConfig(): Config {
  const rawConfig = {
    nodeEnv: process.env.NODE_ENV,
    port: parseInt(process.env.PORT || '3000', 10),
    version: process.env.VERSION || '1.0.0',

    databaseUrl: process.env.DATABASE_URL || 'postgresql://sfops:sfops_dev_password@localhost:5432/sfops',
    databasePoolMin: parseInt(process.env.DATABASE_POOL_MIN || '2', 10),
    databasePoolMax: parseInt(process.env.DATABASE_POOL_MAX || '10', 10),

    redisUrl: process.env.REDIS_URL || 'redis://localhost:6379',

    vaultAddr: process.env.VAULT_ADDR || 'http://localhost:8200',
    vaultToken: process.env.VAULT_TOKEN || 'root-token-dev',
    vaultRoleId: process.env.VAULT_ROLE_ID,
    vaultSecretId: process.env.VAULT_SECRET_ID,

    temporalAddress: process.env.TEMPORAL_ADDRESS || 'localhost:7233',
    temporalNamespace: process.env.TEMPORAL_NAMESPACE || 'default',

    s3Endpoint: process.env.S3_ENDPOINT || 'http://localhost:9000',
    s3AccessKey: process.env.S3_ACCESS_KEY || 'minio',
    s3SecretKey: process.env.S3_SECRET_KEY || 'minio123',
    s3Bucket: process.env.S3_BUCKET || 'sfops-snapshots',
    s3Region: process.env.S3_REGION || 'us-east-1',

    jwtSecret: process.env.JWT_SECRET || 'dev-secret-change-in-production',
    jwtExpiry: process.env.JWT_EXPIRY || '7d',
    jwtRefreshExpiry: process.env.JWT_REFRESH_EXPIRY || '30d',

    googleClientId: process.env.GOOGLE_CLIENT_ID,
    googleClientSecret: process.env.GOOGLE_CLIENT_SECRET,
    googleCallbackUrl: process.env.GOOGLE_CALLBACK_URL,

    samlEntryPoint: process.env.SAML_ENTRY_POINT,
    samlIssuer: process.env.SAML_ISSUER,
    samlCert: process.env.SAML_CERT,

    salesforceClientId: process.env.SALESFORCE_CLIENT_ID,
    salesforceClientSecret: process.env.SALESFORCE_CLIENT_SECRET,
    salesforceCallbackUrl: process.env.SALESFORCE_CALLBACK_URL,

    jaegerEndpoint: process.env.JAEGER_ENDPOINT,
    logLevel: process.env.LOG_LEVEL || 'info',

    enableMetrics: process.env.ENABLE_METRICS !== 'false',
    enableTracing: process.env.ENABLE_TRACING !== 'false',
    enableAuditLog: process.env.ENABLE_AUDIT_LOG !== 'false',
  };

  return configSchema.parse(rawConfig);
}

export const config = loadConfig();
