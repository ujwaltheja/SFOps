# SFOps - Salesforce Deployment SaaS Platform

A comprehensive, production-ready SaaS platform for Salesforce metadata deployment, comparison, CI/CD automation, backups, and rollback capabilities.

## Features

### Core Capabilities
- **Org Management**: OAuth2-based Salesforce org connections with secure credential storage
- **Metadata Snapshots**: Fast, incremental snapshots of Salesforce metadata
- **Smart Comparison**: Semantic diff engine with dependency detection
- **Granular Deployments**: Component-level selection with validation (dry-run)
- **Automated Testing**: Run Apex tests during deployment
- **Backup & Restore**: Pre-deployment snapshots with one-click rollback
- **CI/CD Pipelines**: Git-triggered workflows with approval gates
- **Multi-tenant**: Secure tenant isolation with per-tenant encryption
- **RBAC**: Role-based access control with SSO support (Google, SAML, OIDC)
- **Audit Logging**: Immutable audit trail for compliance
- **Observability**: Metrics, tracing, and centralized logging

### Architecture Highlights
- **Scalable**: Kubernetes-based, horizontal auto-scaling
- **Reliable**: Multi-AZ deployment, 99.9% uptime SLA
- **Secure**: Vault-based secret management, TLS everywhere
- **Observable**: Prometheus metrics, Jaeger tracing, ELK logging

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 20+
- kubectl (for Kubernetes deployment)
- Terraform 1.6+ (for infrastructure provisioning)

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/sfops.git
   cd sfops
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Start infrastructure services**
   ```bash
   docker-compose up -d
   ```

   This starts:
   - PostgreSQL (port 5432)
   - Redis (port 6379)
   - HashiCorp Vault (port 8200)
   - Temporal (port 7233)
   - Temporal UI (port 8088)
   - MinIO (S3-compatible storage, ports 9000/9001)
   - Prometheus (port 9090)
   - Grafana (port 3001)
   - Jaeger (port 16686)

4. **Run database migrations**
   ```bash
   npm run db:migrate
   ```

5. **Seed the database** (optional, for demo data)
   ```bash
   npm run db:seed
   ```

6. **Start the development servers**
   ```bash
   # Start all services in parallel
   npm run dev
   ```

   Services will be available at:
   - API: http://localhost:3000
   - Frontend: http://localhost:5173
   - GraphQL: http://localhost:3000/graphql
   - Temporal UI: http://localhost:8088
   - Grafana: http://localhost:3001 (admin/admin)

### Environment Variables

Create a `.env` file in the root directory:

```env
# Server
NODE_ENV=development
PORT=3000

# Database
DATABASE_URL=postgresql://sfops:sfops_dev_password@localhost:5432/sfops

# Redis
REDIS_URL=redis://localhost:6379

# Vault
VAULT_ADDR=http://localhost:8200
VAULT_TOKEN=root-token-dev

# Temporal
TEMPORAL_ADDRESS=localhost:7233
TEMPORAL_NAMESPACE=default

# S3/MinIO
S3_ENDPOINT=http://localhost:9000
S3_ACCESS_KEY=minio
S3_SECRET_KEY=minio123
S3_BUCKET=sfops-snapshots

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-in-production

# Salesforce OAuth
SALESFORCE_CLIENT_ID=your-salesforce-client-id
SALESFORCE_CLIENT_SECRET=your-salesforce-client-secret
SALESFORCE_CALLBACK_URL=http://localhost:3000/api/v1/auth/salesforce/callback

# Observability
JAEGER_ENDPOINT=http://localhost:14268/api/traces
LOG_LEVEL=info
```

## Project Structure

```
sfops/
├── services/
│   ├── api/                 # Main API service (Express + GraphQL)
│   └── workers/             # Temporal workflow workers
├── packages/
│   ├── shared/              # Shared types and utilities
│   ├── salesforce-client/   # Salesforce API client
│   └── vault-client/        # HashiCorp Vault client
├── frontend/                # React SPA (TypeScript + Material-UI)
├── infrastructure/
│   ├── terraform/           # Infrastructure as Code (AWS/GCP/Azure)
│   └── k8s/                 # Kubernetes manifests
├── database/
│   └── migrations/          # SQL migrations
├── tests/
│   ├── unit/                # Unit tests
│   ├── integration/         # Integration tests
│   └── e2e/                 # End-to-end tests
├── config/                  # Configuration files
│   ├── prometheus/
│   ├── grafana/
│   └── temporal/
├── scripts/                 # Utility scripts
└── docs/                    # Additional documentation
```

## Development Workflow

### Running Tests

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage

# Run integration tests
npm run test:integration

# Run E2E tests
npm run test:e2e
```

### Linting and Formatting

```bash
# Run linter
npm run lint

# Fix linting issues
npm run lint:fix

# Format code
npm run format
```

### Database Management

```bash
# Run migrations
npm run db:migrate

# Rollback last migration
npm run db:rollback

# Create new migration
npm run db:create-migration <name>

# Seed database
npm run db:seed
```

## API Documentation

### REST API

Full OpenAPI specification: [API-SPEC.yaml](./API-SPEC.yaml)

Key endpoints:

```
POST   /api/v1/auth/login                    # SSO login
POST   /api/v1/tenants/{id}/orgs             # Create org connection
GET    /api/v1/tenants/{id}/orgs/{orgId}     # Get org details
POST   /api/v1/tenants/{id}/snapshots        # Create snapshot
POST   /api/v1/tenants/{id}/diffs            # Compare orgs
POST   /api/v1/tenants/{id}/deploys          # Start deployment
GET    /api/v1/tenants/{id}/deploys/{id}     # Get deployment status
POST   /api/v1/tenants/{id}/deploys/{id}/rollback  # Rollback
```

### GraphQL API

Endpoint: `http://localhost:3000/graphql`

Example query:
```graphql
query GetDeployments($tenantId: ID!) {
  deployments(tenantId: $tenantId) {
    id
    status
    checkOnly
    progress {
      total
      completed
      failed
    }
    package {
      name
      componentCount
    }
    targetOrg {
      name
      environment
    }
  }
}
```

## Deployment

### Production Deployment (Kubernetes)

1. **Provision infrastructure**
   ```bash
   cd infrastructure/terraform
   terraform init
   terraform plan -var-file=production.tfvars
   terraform apply -var-file=production.tfvars
   ```

2. **Configure kubectl**
   ```bash
   aws eks update-kubeconfig --name production-sfops-cluster --region us-east-1
   ```

3. **Create secrets**
   ```bash
   kubectl create namespace sfops
   kubectl create secret generic sfops-secrets \
     --from-literal=database-url=$DATABASE_URL \
     --from-literal=redis-url=$REDIS_URL \
     --from-literal=vault-addr=$VAULT_ADDR \
     --from-literal=vault-token=$VAULT_TOKEN \
     --from-literal=jwt-secret=$JWT_SECRET \
     -n sfops
   ```

4. **Deploy applications**
   ```bash
   kubectl apply -f infrastructure/k8s/
   ```

5. **Verify deployment**
   ```bash
   kubectl get pods -n sfops
   kubectl get svc -n sfops
   ```

### GitOps Deployment

The project includes GitHub Actions workflows for automated CI/CD:

- **CI Pipeline**: Runs on every push, executes tests and linting
- **Security Scanning**: Trivy vulnerability scanning
- **Staging Deployment**: Auto-deploy to staging on `develop` branch
- **Production Deployment**: Auto-deploy to production on `main` branch (with approval)

## Monitoring & Observability

### Metrics (Prometheus + Grafana)

Access Grafana: http://localhost:3001

Key metrics:
- `http_request_duration_seconds` - API request latency
- `deployment_duration_seconds` - Deployment execution time
- `deployments_total` - Total deployments by status
- `snapshot_size_bytes` - Snapshot sizes
- `deployment_queue_depth` - Queue depth

### Distributed Tracing (Jaeger)

Access Jaeger UI: http://localhost:16686

Traces include:
- Full deployment workflow spans
- Database queries
- External API calls (Salesforce)
- Vault operations

### Centralized Logging

Logs are structured JSON with correlation IDs for tracing requests across services.

## Security

### Credential Management
- All Salesforce OAuth tokens stored encrypted in HashiCorp Vault
- Per-tenant encryption keys using Vault transit engine
- Automatic token refresh before expiry
- Token rotation every 7 days

### Network Security
- TLS 1.3 for all connections
- API Gateway with rate limiting and WAF
- Private subnets for databases and workers
- VPC peering for multi-region setup

### Compliance
- Immutable audit logs (7-year retention)
- Exportable audit trail for compliance reports
- GDPR and SOC 2 compliant architecture

## Backup & Disaster Recovery

### Automated Backups
- Pre-deployment snapshots (automatic)
- Scheduled nightly snapshots (configurable per tenant)
- Incremental snapshots with deduplication
- Cross-region replication

### Recovery
- **RTO**: 15 minutes
- **RPO**: 5 minutes
- One-click rollback from UI
- Automated DR drills weekly

## Performance & Scalability

### Performance Targets
- API response time: p95 < 200ms
- Snapshot fetch: < 30s for typical org (10k components)
- Diff computation: < 5s for 1k changed components
- Concurrent deployments: 500+ per cluster

### Scaling
- Horizontal pod autoscaling (HPA) based on CPU/memory
- Temporal worker auto-scaling based on queue depth
- Database read replicas for reporting queries
- Redis cluster for high availability

## Troubleshooting

### Common Issues

**Issue**: Database connection fails
```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Check connection
psql postgresql://sfops:sfops_dev_password@localhost:5432/sfops
```

**Issue**: Temporal workflows not executing
```bash
# Check Temporal server
docker-compose ps temporal

# Check worker logs
npm run workers:dev
```

**Issue**: Salesforce OAuth fails
```bash
# Verify callback URL matches Salesforce Connected App
# Check client ID and secret in .env
```

### Logs

```bash
# API logs
docker-compose logs -f api

# Worker logs
docker-compose logs -f workers

# Database logs
docker-compose logs -f postgres
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Coding Standards
- TypeScript strict mode enabled
- ESLint + Prettier for code formatting
- 80%+ test coverage required
- All PRs require review

## Testing Strategy

### Unit Tests
- All services and utilities
- Jest + ts-jest

### Integration Tests
- Database operations
- Salesforce API mocks
- Vault operations

### End-to-End Tests
- Full deployment workflow
- Git-triggered pipelines
- Rollback scenarios

### Load Tests
- Simulate 1000+ concurrent users
- 500+ parallel deployments
- k6 load testing framework

## Runbooks

See [docs/runbooks](./docs/runbooks/) for operational procedures:

- [Incident Response](./docs/runbooks/incident-response.md)
- [Deployment Failures](./docs/runbooks/deployment-failures.md)
- [Secret Rotation](./docs/runbooks/secret-rotation.md)
- [Backup Verification](./docs/runbooks/backup-verification.md)
- [Scaling Procedures](./docs/runbooks/scaling.md)

## Roadmap

### Q1 2024
- [ ] Visual diff viewer with syntax highlighting
- [ ] Smart dependency resolution (auto-select required components)
- [ ] Slack integration for notifications
- [ ] Multi-region deployment support

### Q2 2024
- [ ] Incremental deploys with binary diffs
- [ ] Visual rollback timeline (time travel)
- [ ] Marketplace for plugins and custom transforms
- [ ] Mobile app (iOS/Android)

### Q3 2024
- [ ] AI-powered deployment recommendations
- [ ] Cost optimization insights
- [ ] Advanced security scanning
- [ ] Compliance automation (HIPAA, PCI-DSS)

## License

Copyright © 2024 SFOps. All rights reserved.

## Support

- Documentation: https://docs.sfops.io
- Email: support@sfops.io
- Slack Community: https://sfops-community.slack.com
- GitHub Issues: https://github.com/sfops/sfops/issues

## Acknowledgments

Built with:
- [Temporal](https://temporal.io) - Workflow orchestration
- [jsforce](https://jsforce.github.io) - Salesforce API client
- [HashiCorp Vault](https://www.vaultproject.io) - Secret management
- [React](https://react.dev) - UI framework
- [Material-UI](https://mui.com) - Component library
- [PostgreSQL](https://www.postgresql.org) - Database
- [Redis](https://redis.io) - Caching & queues
- [Terraform](https://www.terraform.io) - Infrastructure as Code
- [Kubernetes](https://kubernetes.io) - Container orchestration
