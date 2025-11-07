import { Express } from 'express';
import client from 'prom-client';
import { config } from '../config';

// Create a Registry
const register = new client.Registry();

// Add default metrics
client.collectDefaultMetrics({ register });

// Custom metrics
export const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

export const deploymentDuration = new client.Histogram({
  name: 'deployment_duration_seconds',
  help: 'Duration of deployments in seconds',
  labelNames: ['tenant_id', 'status'],
  registers: [register],
});

export const deploymentCounter = new client.Counter({
  name: 'deployments_total',
  help: 'Total number of deployments',
  labelNames: ['tenant_id', 'status', 'environment'],
  registers: [register],
});

export const snapshotSize = new client.Gauge({
  name: 'snapshot_size_bytes',
  help: 'Size of metadata snapshots in bytes',
  labelNames: ['tenant_id', 'org_id'],
  registers: [register],
});

export const activeConnections = new client.Gauge({
  name: 'active_database_connections',
  help: 'Number of active database connections',
  registers: [register],
});

export const queueDepth = new client.Gauge({
  name: 'deployment_queue_depth',
  help: 'Number of deployments waiting in queue',
  labelNames: ['queue_name'],
  registers: [register],
});

export function setupMetrics(app: Express): void {
  if (!config.enableMetrics) {
    return;
  }

  // Metrics endpoint
  app.get('/metrics', async (req, res) => {
    res.set('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.send(metrics);
  });

  // Request duration middleware
  app.use((req, res, next) => {
    const start = Date.now();

    res.on('finish', () => {
      const duration = (Date.now() - start) / 1000;
      httpRequestDuration.labels(req.method, req.route?.path || req.path, res.statusCode.toString()).observe(duration);
    });

    next();
  });
}
