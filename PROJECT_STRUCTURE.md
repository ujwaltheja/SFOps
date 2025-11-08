# 📁 SFOps Project Structure

Complete directory layout and file organization for the SFOps platform.

## 🗂️ Root Directory

```
SFOps/
├── .github/                    # GitHub configurations
│   └── workflows/              # CI/CD workflows
│       ├── ci.yml             # Main CI/CD pipeline
│       ├── deploy.yml         # Deployment workflow
│       └── release.yml        # Release automation
│
├── backend/                    # Backend Node.js/TypeScript API
│   ├── src/
│   │   ├── api/               # REST API routes and controllers
│   │   │   ├── routes/        # Express route definitions
│   │   │   │   ├── auth.routes.ts
│   │   │   │   ├── deployments.routes.ts
│   │   │   │   ├── orgs.routes.ts
│   │   │   │   ├── users.routes.ts
│   │   │   │   └── index.ts
│   │   │   ├── controllers/   # Request handlers
│   │   │   │   ├── auth.controller.ts
│   │   │   │   ├── deployment.controller.ts
│   │   │   │   ├── org.controller.ts
│   │   │   │   └── user.controller.ts
│   │   │   └── validators/    # Request validation schemas
│   │   │       ├── deployment.validator.ts
│   │   │       └── org.validator.ts
│   │   │
│   │   ├── services/          # Business logic services
│   │   │   ├── auth.service.ts
│   │   │   ├── deployment.service.ts
│   │   │   ├── git.service.ts
│   │   │   ├── org.service.ts
│   │   │   ├── salesforce.service.ts
│   │   │   ├── validation.service.ts
│   │   │   ├── rollback.service.ts
│   │   │   ├── approval.service.ts
│   │   │   ├── notification.service.ts
│   │   │   └── artifact.service.ts
│   │   │
│   │   ├── workers/           # Background job workers
│   │   │   ├── deployment.worker.ts
│   │   │   ├── validation.worker.ts
│   │   │   ├── notification.worker.ts
│   │   │   └── index.ts
│   │   │
│   │   ├── middleware/        # Express middleware
│   │   │   ├── auth.middleware.ts
│   │   │   ├── error.middleware.ts
│   │   │   ├── logging.middleware.ts
│   │   │   ├── rate-limit.middleware.ts
│   │   │   ├── validation.middleware.ts
│   │   │   └── rbac.middleware.ts
│   │   │
│   │   ├── models/            # Database models (ORM)
│   │   │   ├── user.model.ts
│   │   │   ├── org.model.ts
│   │   │   ├── deployment.model.ts
│   │   │   ├── approval.model.ts
│   │   │   ├── artifact.model.ts
│   │   │   ├── audit-log.model.ts
│   │   │   └── index.ts
│   │   │
│   │   ├── utils/             # Utility functions
│   │   │   ├── logger.ts
│   │   │   ├── crypto.ts
│   │   │   ├── jwt.ts
│   │   │   ├── helpers.ts
│   │   │   └── constants.ts
│   │   │
│   │   ├── config/            # Configuration management
│   │   │   ├── database.config.ts
│   │   │   ├── redis.config.ts
│   │   │   ├── vault.config.ts
│   │   │   ├── s3.config.ts
│   │   │   └── index.ts
│   │   │
│   │   ├── types/             # TypeScript type definitions
│   │   │   ├── express.d.ts
│   │   │   ├── deployment.types.ts
│   │   │   ├── org.types.ts
│   │   │   └── index.ts
│   │   │
│   │   ├── app.ts             # Express app setup
│   │   └── server.ts          # Server entry point
│   │
│   ├── tests/                 # Backend tests
│   │   ├── unit/              # Unit tests
│   │   │   ├── services/
│   │   │   ├── utils/
│   │   │   └── models/
│   │   ├── integration/       # Integration tests
│   │   │   ├── api/
│   │   │   ├── database/
│   │   │   └── workers/
│   │   ├── fixtures/          # Test data
│   │   │   ├── users.json
│   │   │   └── deployments.json
│   │   └── setup.ts           # Test setup
│   │
│   ├── Dockerfile             # Docker image definition
│   ├── .dockerignore          # Docker ignore file
│   ├── package.json           # Node.js dependencies
│   ├── tsconfig.json          # TypeScript configuration
│   ├── jest.config.js         # Jest test configuration
│   └── .eslintrc.js           # ESLint configuration
│
├── frontend/                  # React frontend application
│   ├── src/
│   │   ├── components/        # Reusable React components
│   │   │   ├── common/        # Common UI components
│   │   │   │   ├── Button.tsx
│   │   │   │   ├── Input.tsx
│   │   │   │   ├── Modal.tsx
│   │   │   │   ├── Card.tsx
│   │   │   │   └── Spinner.tsx
│   │   │   ├── layout/        # Layout components
│   │   │   │   ├── Header.tsx
│   │   │   │   ├── Sidebar.tsx
│   │   │   │   ├── Footer.tsx
│   │   │   │   └── Layout.tsx
│   │   │   ├── deployment/    # Deployment-specific
│   │   │   │   ├── DeploymentCard.tsx
│   │   │   │   ├── DeploymentList.tsx
│   │   │   │   ├── DeploymentForm.tsx
│   │   │   │   ├── DeploymentLogs.tsx
│   │   │   │   └── DeploymentStatus.tsx
│   │   │   ├── org/           # Organization components
│   │   │   │   ├── OrgCard.tsx
│   │   │   │   ├── OrgForm.tsx
│   │   │   │   └── OrgSelector.tsx
│   │   │   └── approval/      # Approval workflow
│   │   │       ├── ApprovalCard.tsx
│   │   │       └── ApprovalForm.tsx
│   │   │
│   │   ├── pages/             # Page components
│   │   │   ├── Dashboard.tsx
│   │   │   ├── Login.tsx
│   │   │   ├── Register.tsx
│   │   │   ├── Deployments.tsx
│   │   │   ├── DeploymentDetail.tsx
│   │   │   ├── Organizations.tsx
│   │   │   ├── OrgDetail.tsx
│   │   │   ├── Approvals.tsx
│   │   │   ├── Users.tsx
│   │   │   ├── Settings.tsx
│   │   │   └── NotFound.tsx
│   │   │
│   │   ├── hooks/             # Custom React hooks
│   │   │   ├── useAuth.ts
│   │   │   ├── useDeployments.ts
│   │   │   ├── useOrgs.ts
│   │   │   ├── useWebSocket.ts
│   │   │   └── useNotifications.ts
│   │   │
│   │   ├── services/          # API client services
│   │   │   ├── api.service.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── deployment.service.ts
│   │   │   ├── org.service.ts
│   │   │   └── user.service.ts
│   │   │
│   │   ├── stores/            # State management (Zustand)
│   │   │   ├── authStore.ts
│   │   │   ├── deploymentStore.ts
│   │   │   ├── orgStore.ts
│   │   │   └── uiStore.ts
│   │   │
│   │   ├── types/             # TypeScript types
│   │   │   ├── api.types.ts
│   │   │   ├── deployment.types.ts
│   │   │   └── org.types.ts
│   │   │
│   │   ├── utils/             # Utility functions
│   │   │   ├── formatters.ts
│   │   │   ├── validators.ts
│   │   │   └── constants.ts
│   │   │
│   │   ├── styles/            # Global styles
│   │   │   ├── globals.css
│   │   │   └── tailwind.css
│   │   │
│   │   ├── App.tsx            # Main App component
│   │   ├── main.tsx           # Entry point
│   │   └── vite-env.d.ts      # Vite types
│   │
│   ├── public/                # Static assets
│   │   ├── index.html
│   │   ├── favicon.ico
│   │   └── assets/
│   │
│   ├── Dockerfile             # Docker image
│   ├── package.json           # Dependencies
│   ├── tsconfig.json          # TypeScript config
│   ├── vite.config.ts         # Vite configuration
│   ├── tailwind.config.js     # Tailwind CSS config
│   └── postcss.config.js      # PostCSS config
│
├── cli/                       # Command-line interface
│   ├── src/
│   │   ├── commands/          # CLI commands
│   │   │   ├── login.ts
│   │   │   ├── deploy.ts
│   │   │   ├── validate.ts
│   │   │   ├── rollback.ts
│   │   │   ├── org.ts
│   │   │   └── config.ts
│   │   ├── utils/             # CLI utilities
│   │   │   ├── api-client.ts
│   │   │   ├── config.ts
│   │   │   └── logger.ts
│   │   ├── types/             # Type definitions
│   │   └── index.ts           # CLI entry point
│   │
│   ├── package.json
│   ├── tsconfig.json
│   └── README.md
│
├── packages/                  # Shared packages (monorepo)
│   ├── shared/                # Shared utilities and types
│   │   ├── src/
│   │   │   ├── types/
│   │   │   ├── utils/
│   │   │   ├── constants/
│   │   │   └── index.ts
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   ├── salesforce-client/     # Salesforce API wrapper
│   │   ├── src/
│   │   │   ├── auth/
│   │   │   ├── metadata/
│   │   │   ├── deployment/
│   │   │   ├── tooling/
│   │   │   └── index.ts
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   └── vault-client/          # Vault integration
│       ├── src/
│       │   ├── client.ts
│       │   ├── kv.ts
│       │   └── index.ts
│       ├── package.json
│       └── tsconfig.json
│
├── database/                  # Database management
│   ├── migrations/            # SQL migration files
│   │   ├── 001_create_users_table.sql
│   │   ├── 002_create_orgs_table.sql
│   │   ├── 003_create_deployments_table.sql
│   │   └── ...
│   ├── seeds/                 # Seed data
│   │   ├── 001_seed_users.sql
│   │   └── 002_seed_orgs.sql
│   ├── init.sql               # Initial DB setup
│   └── README.md
│
├── infrastructure/            # Infrastructure as Code
│   ├── docker/                # Docker configs
│   │   ├── Dockerfile.backend
│   │   ├── Dockerfile.frontend
│   │   ├── prometheus.yml
│   │   └── grafana-datasources.yml
│   │
│   ├── kubernetes/            # Kubernetes manifests
│   │   ├── base/              # Base configs
│   │   │   ├── namespace.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── secrets.yaml
│   │   │   └── pvc.yaml
│   │   ├── backend/
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   └── hpa.yaml
│   │   ├── frontend/
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   └── ingress.yaml
│   │   ├── database/
│   │   │   ├── statefulset.yaml
│   │   │   └── service.yaml
│   │   └── monitoring/
│   │       ├── prometheus.yaml
│   │       └── grafana.yaml
│   │
│   └── terraform/             # Terraform IaC
│       ├── modules/
│       │   ├── vpc/
│       │   ├── eks/
│       │   ├── rds/
│       │   └── s3/
│       ├── environments/
│       │   ├── dev/
│       │   ├── staging/
│       │   └── production/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── scripts/                   # Utility scripts
│   ├── setup-dev.sh          # Development setup
│   ├── backup-db.sh          # Database backup
│   ├── restore-db.sh         # Database restore
│   ├── deploy.sh             # Deployment script
│   └── seed-data.sh          # Seed test data
│
├── docs/                      # Documentation
│   ├── guides/                # User guides
│   │   ├── getting-started.md
│   │   ├── deployment-guide.md
│   │   ├── approval-workflow.md
│   │   └── troubleshooting.md
│   ├── api/                   # API documentation
│   │   ├── authentication.md
│   │   ├── deployments.md
│   │   └── organizations.md
│   ├── runbooks/              # Operational runbooks
│   │   ├── incident-response.md
│   │   ├── backup-restore.md
│   │   └── scaling.md
│   └── architecture/          # Architecture docs
│       ├── system-design.md
│       ├── data-flow.md
│       └── security.md
│
├── .github/                   # GitHub configuration
├── .gitignore                 # Git ignore file
├── .env.example               # Environment template
├── docker-compose.yml         # Docker Compose config
├── package.json               # Root package.json
├── tsconfig.json              # Root TypeScript config
├── .eslintrc.js               # ESLint config
├── .prettierrc                # Prettier config
├── README.md                  # Project README
├── ARCHITECTURE.md            # Architecture documentation
├── DATABASE.md                # Database schema
├── API-SPEC.yaml              # OpenAPI specification
├── CONTRIBUTING.md            # Contribution guidelines
├── LICENSE                    # MIT License
└── CHANGELOG.md               # Version changelog
```

## 📝 File Naming Conventions

### TypeScript Files
- **Components**: PascalCase (e.g., `DeploymentCard.tsx`)
- **Services**: kebab-case + suffix (e.g., `deployment.service.ts`)
- **Utilities**: kebab-case (e.g., `date-formatter.ts`)
- **Types**: kebab-case + `.types.ts` (e.g., `deployment.types.ts`)
- **Tests**: same as source + `.test.ts` (e.g., `deployment.service.test.ts`)

### Configuration Files
- Use lowercase with hyphens (e.g., `docker-compose.yml`)
- Config files should use appropriate extensions (`.json`, `.yaml`, `.yml`)

### Documentation
- Use lowercase with hyphens (e.g., `getting-started.md`)
- Keep documentation close to relevant code when possible

## 🎯 Key Directories Explained

### `/backend/src/api`
REST API routes, controllers, and validators. This is the HTTP layer.

### `/backend/src/services`
Business logic layer. All core functionality lives here.

### `/backend/src/workers`
Background job processors for async operations like deployments.

### `/backend/src/models`
Database ORM models using Sequelize or TypeORM.

### `/frontend/src/components`
Reusable React components organized by feature.

### `/frontend/src/pages`
Top-level page components for routing.

### `/packages`
Shared code used across multiple parts of the application.

### `/infrastructure`
All deployment and infrastructure configuration.

### `/database/migrations`
Version-controlled database schema changes.

## 🔄 Development Workflow

1. **Feature Development**: Create feature branch from `develop`
2. **Code Changes**: Make changes in appropriate directories
3. **Testing**: Add tests alongside source code
4. **Documentation**: Update docs as needed
5. **Pull Request**: Submit PR to `develop` branch
6. **Review & Merge**: After approval, merge to `develop`
7. **Release**: Periodic merges from `develop` to `main`

## 📦 Build Artifacts

Build outputs are generated in:
- `backend/dist` - Compiled backend code
- `frontend/dist` - Production frontend bundle
- `cli/dist` - CLI executable

## 🚀 Deployment

Production builds are containerized and deployed to Kubernetes clusters defined in `/infrastructure/kubernetes`.

---

For more details, see individual README files in each directory.
