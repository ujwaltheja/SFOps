import express from 'express';
import helmet from 'helmet';
import { createServer } from 'http';
import { logger } from './utils/logger';
import { config } from './config';
import { initializeDatabase } from './database';
import { initializeRedis } from './database/redis';
import { initializeVault } from './services/vault';
import { setupMetrics } from './observability/metrics';
import { setupTracing } from './observability/tracing';
import { setupRoutes } from './routes';
import { setupGraphQL } from './graphql';
import { errorHandler } from './middleware/errorHandler';
import { authMiddleware } from './middleware/auth';
import { tenantMiddleware } from './middleware/tenant';
import { auditMiddleware } from './middleware/audit';

async function bootstrap() {
  try {
    // Initialize tracing first
    setupTracing();

    logger.info('Starting SFOps API Server...');

    // Initialize infrastructure
    await initializeDatabase();
    await initializeRedis();
    await initializeVault();

    // Create Express app
    const app = express();
    const httpServer = createServer(app);

    // Security middleware
    app.use(helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          styleSrc: ["'self'", "'unsafe-inline'"],
          scriptSrc: ["'self'"],
          imgSrc: ["'self'", 'data:', 'https:'],
        },
      },
      crossOriginEmbedderPolicy: false,
    }));

    // Body parsing
    app.use(express.json({ limit: '10mb' }));
    app.use(express.urlencoded({ extended: true, limit: '10mb' }));

    // Setup metrics endpoint
    setupMetrics(app);

    // Health check
    app.get('/health', (req, res) => {
      res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: config.version,
      });
    });

    app.get('/ready', async (req, res) => {
      // Check database, redis, vault connections
      try {
        // Add actual readiness checks
        res.json({
          status: 'ready',
          timestamp: new Date().toISOString(),
        });
      } catch (error) {
        res.status(503).json({
          status: 'not ready',
          error: error instanceof Error ? error.message : 'Unknown error',
        });
      }
    });

    // Apply middleware
    app.use(authMiddleware);
    app.use(tenantMiddleware);
    app.use(auditMiddleware);

    // Setup routes
    setupRoutes(app);

    // Setup GraphQL
    await setupGraphQL(app, httpServer);

    // Error handling
    app.use(errorHandler);

    // Start server
    const port = config.port;
    httpServer.listen(port, () => {
      logger.info(`🚀 Server ready at http://localhost:${port}`);
      logger.info(`📊 Metrics at http://localhost:${port}/metrics`);
      logger.info(`🔍 Health check at http://localhost:${port}/health`);
    });

    // Graceful shutdown
    const shutdown = async (signal: string) => {
      logger.info(`${signal} received, shutting down gracefully...`);

      httpServer.close(() => {
        logger.info('HTTP server closed');
        process.exit(0);
      });

      // Force shutdown after 30 seconds
      setTimeout(() => {
        logger.error('Could not close connections in time, forcefully shutting down');
        process.exit(1);
      }, 30000);
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));

  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

bootstrap();
