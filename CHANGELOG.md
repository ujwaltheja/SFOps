# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Complete Salesforce deployment SaaS platform
- Multi-tenant architecture with tenant isolation
- OAuth2 Salesforce org connections
- Metadata snapshot and comparison engine
- Granular deployment with component selection
- Validation (dry-run) before deployment
- Automated backup and one-click rollback
- CI/CD pipelines with Git integration
- RBAC with SSO support (Google, SAML, OIDC)
- Audit logging for compliance
- Temporal-based workflow orchestration
- HashiCorp Vault for secret management
- React frontend with Material-UI
- Comprehensive observability (Prometheus, Grafana, Jaeger)
- Kubernetes deployment manifests
- Terraform infrastructure as code
- End-to-end testing suite
- GitHub Actions CI/CD pipeline
- Comprehensive documentation and runbooks

## [1.0.0] - 2024-01-15

### Added
- Initial release of SFOps platform
- Core deployment functionality
- Basic UI for org management and deployment monitoring
- RESTful API and GraphQL endpoints
- Database schema and migrations
- Docker Compose for local development
- Infrastructure provisioning with Terraform

### Security
- Encryption at rest and in transit
- Per-tenant encryption keys
- Secure credential storage in Vault
- JWT-based authentication
- Rate limiting and DDoS protection

[Unreleased]: https://github.com/sfops/sfops/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/sfops/sfops/releases/tag/v1.0.0
