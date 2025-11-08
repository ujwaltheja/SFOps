# 🚀 SFOps - Salesforce Deployment Automation Platform

**Production-grade CI/CD tool for Salesforce metadata and Apex code deployments**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen)](https://nodejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0-blue)](https://www.typescriptlang.org/)
[![Docker](https://img.shields.io/badge/Docker-ready-blue)](https://www.docker.com/)

## 📋 Overview

SFOps is a comprehensive Salesforce deployment automation platform that streamlines the CI/CD process for Salesforce metadata and Apex code. It provides a secure, scalable, and user-friendly solution for managing deployments across multiple Salesforce environments (DEV → QA → UAT → PROD).

### Key Features

✅ **Automated Git Integration** - Detect changes from GitHub/GitLab/Bitbucket
✅ **Multi-Environment Deployments** - Sequential promotion pipelines
✅ **Validation-First Approach** - Check-only deployments before production
✅ **Apex Test Execution** - Automated test runs with coverage reporting
✅ **Intelligent Rollbacks** - Version-controlled metadata snapshots
✅ **Approval Workflows** - Multi-stage approvals for production
✅ **RBAC & Security** - Role-based access control with OAuth2
✅ **Real-Time Monitoring** - Live deployment logs and status
✅ **Audit Trail** - Comprehensive compliance logging
✅ **Multi-Interface** - Web UI, REST API, and CLI access

## 🏗️ Architecture

SFOps follows a **modular monolith architecture** designed for cloud-native deployment:

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   Web UI    │  │   CLI Tool  │  │  REST API   │
│   (React)   │  │  (Node.js)  │  │  Clients    │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                 │
       └────────────────┴─────────────────┘
                        │
                ┌───────▼────────┐
                │   API Gateway  │
                │  (Auth/Router) │
                └───────┬────────┘
                        │
       ┌────────────────┼────────────────┐
       │                │                │
┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐
│ Deployment  │  │ Validation  │  │  Approval   │
│ Orchestrator│  │   Engine    │  │  Workflow   │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                │
       └────────────────┼────────────────┘
                        │
                ┌───────▼────────┐
                │  Worker Queue  │
                │    (BullMQ)    │
                └───────┬────────┘
                        │
       ┌────────────────┼────────────────┐
       │                │                │
┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐
│ PostgreSQL  │  │    Redis    │  │  S3/MinIO   │
│  (Metadata) │  │   (Cache)   │  │ (Artifacts) │
└─────────────┘  └─────────────┘  └─────────────┘
```

For detailed architecture, see [ARCHITECTURE.md](./ARCHITECTURE.md)

## 🛠️ Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| **Backend** | Node.js + TypeScript | 18+ |
| **API Framework** | Express.js | 4.x |
| **Database** | PostgreSQL | 15+ |
| **Cache/Queue** | Redis + BullMQ | 7+ |
| **Frontend** | React + TypeScript | 18+ |
| **Styling** | TailwindCSS | 3.x |
| **Containerization** | Docker | Latest |
| **Orchestration** | Kubernetes | 1.27+ |
| **Secrets** | HashiCorp Vault | 1.15+ |
| **Storage** | MinIO (S3 API) | Latest |
| **SF Integration** | Salesforce CLI (sf) | Latest |
| **Monitoring** | Prometheus + Grafana | Latest |

## 📦 Project Structure

```
SFOps/
├── backend/                    # Backend API service
│   ├── src/
│   │   ├── api/               # REST API routes
│   │   ├── services/          # Business logic services
│   │   ├── workers/           # Background job workers
│   │   ├── middleware/        # Express middleware
│   │   ├── models/            # Database models
│   │   └── utils/             # Utility functions
│   ├── tests/                 # Backend tests
│   └── Dockerfile
├── frontend/                  # React UI application
│   ├── src/
│   │   ├── components/        # React components
│   │   ├── pages/             # Page components
│   │   ├── hooks/             # Custom hooks
│   │   ├── services/          # API client services
│   │   └── stores/            # State management
│   ├── public/
│   └── Dockerfile
├── cli/                       # CLI client tool
│   ├── src/
│   │   ├── commands/          # CLI commands
│   │   └── utils/             # CLI utilities
│   └── package.json
├── packages/                  # Shared packages
│   ├── shared/                # Shared types and utilities
│   ├── salesforce-client/     # Salesforce API wrapper
│   └── vault-client/          # Vault integration
├── database/                  # Database scripts
│   ├── migrations/            # SQL migrations
│   └── seeds/                 # Seed data
├── infrastructure/            # Infrastructure as Code
│   ├── docker/                # Docker configs
│   ├── kubernetes/            # K8s manifests
│   └── terraform/             # Terraform configs
├── scripts/                   # Utility scripts
├── docs/                      # Documentation
├── .github/                   # GitHub Actions workflows
├── docker-compose.yml         # Local development
├── DATABASE.md               # Database schema docs
├── API-SPEC.yaml             # OpenAPI specification
└── ARCHITECTURE.md           # Architecture details
```

## 🚀 Quick Start

### Prerequisites

- **Node.js** 18+ and npm
- **Docker** and Docker Compose
- **PostgreSQL** 15+
- **Redis** 7+
- **Salesforce CLI** (`sf` or `sfdx`)
- **Salesforce Org** (Dev, Sandbox, or Production)

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

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Start infrastructure services**
   ```bash
   docker-compose up -d postgres redis minio vault
   ```

5. **Run database migrations**
   ```bash
   npm run migrate
   ```

6. **Start the application**
   ```bash
   # Terminal 1: Start backend API
   npm run dev:backend

   # Terminal 2: Start worker processes
   npm run dev:workers

   # Terminal 3: Start frontend UI
   npm run dev:frontend
   ```

7. **Access the application**
   - **Web UI**: http://localhost:3000
   - **API**: http://localhost:4000
   - **API Docs**: http://localhost:4000/api/docs

### Docker Deployment

```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

### Kubernetes Deployment

```bash
# Apply Kubernetes manifests
kubectl apply -f infrastructure/kubernetes/

# Check deployment status
kubectl get pods -n sfops

# Access via ingress
kubectl get ingress -n sfops
```

## 📖 Usage

### Web UI

1. Navigate to http://localhost:3000
2. Login with your credentials
3. Connect your Salesforce org
4. Configure Git repository
5. Create and manage deployments

### CLI Tool

```bash
# Install CLI globally
npm install -g @sfops/cli

# Login
sfops login

# Connect Salesforce org
sfops org:connect --alias myorg --type sandbox

# Create deployment
sfops deploy:create --org myorg --branch main --validate-only

# View deployment status
sfops deploy:status <deployment-id>

# Approve deployment
sfops deploy:approve <deployment-id>

# Rollback deployment
sfops deploy:rollback <deployment-id>
```

### REST API

```bash
# Authenticate
curl -X POST http://localhost:4000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}'

# Create deployment
curl -X POST http://localhost:4000/api/v1/deployments \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "orgId": "org-123",
    "branch": "main",
    "validateOnly": true
  }'

# Get deployment status
curl -X GET http://localhost:4000/api/v1/deployments/{id} \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🔐 Security

### Authentication
- JWT-based authentication with refresh tokens
- OAuth2 integration with Salesforce
- API key support for programmatic access

### Authorization
- Role-based access control (RBAC)
- Organization-level permissions
- Environment-specific access controls

### Secrets Management
- HashiCorp Vault for credential storage
- Encrypted secrets at rest
- Automatic secret rotation

### Audit Logging
- Comprehensive audit trail
- Immutable log storage
- Compliance reporting

## 📊 Monitoring & Observability

### Metrics
- Prometheus metrics endpoint: `/metrics`
- Grafana dashboards included
- Custom SLIs/SLOs for deployments

### Logging
- Structured JSON logging
- Log aggregation with Loki/ELK
- Per-deployment log isolation

### Tracing
- OpenTelemetry instrumentation
- Distributed tracing support
- Performance profiling

## 🧪 Testing

```bash
# Run all tests
npm test

# Unit tests
npm run test:unit

# Integration tests
npm run test:integration

# E2E tests
npm run test:e2e

# Coverage report
npm run test:coverage
```

## 📚 Documentation

- **Architecture**: [ARCHITECTURE.md](./ARCHITECTURE.md)
- **Database Schema**: [DATABASE.md](./DATABASE.md)
- **API Reference**: [API-SPEC.yaml](./API-SPEC.yaml)
- **User Guide**: [docs/user-guide.md](./docs/user-guide.md)
- **Developer Guide**: [docs/developer-guide.md](./docs/developer-guide.md)
- **Deployment Guide**: [docs/deployment-guide.md](./docs/deployment-guide.md)

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](./CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## 🆘 Support

- **Documentation**: [docs/](./docs/)
- **Issues**: [GitHub Issues](https://github.com/yourusername/sfops/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/sfops/discussions)

## 🗺️ Roadmap

### MVP (Phase 1) ✅
- [x] Git integration
- [x] Basic deployment orchestration
- [x] Validation engine
- [x] Web UI dashboard
- [x] CLI tool
- [x] RBAC

### Phase 2 🚧
- [ ] Advanced approval workflows
- [ ] Multi-org parallel deployments
- [ ] Enhanced rollback strategies
- [ ] Static code analysis integration
- [ ] Slack/Teams integration

### Phase 3 📋
- [ ] AI-powered deployment recommendations
- [ ] Cost optimization insights
- [ ] Advanced analytics dashboard
- [ ] Self-service org provisioning
- [ ] Marketplace for deployment templates

## 👥 Authors

- **Your Name** - *Initial work* - [@yourusername](https://github.com/yourusername)

## 🙏 Acknowledgments

- Salesforce CLI team for excellent tooling
- Open source community
- Contributors and testers

---

**Built with ❤️ for the Salesforce DevOps community**
