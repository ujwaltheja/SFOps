# Incident Response Runbook

## Severity Levels

### SEV-1 (Critical)
- Service completely down
- Data loss
- Security breach
- Response time: Immediate
- Escalation: Page on-call immediately

### SEV-2 (High)
- Degraded performance
- Partial outage
- Response time: Within 30 minutes
- Escalation: Notify on-call

### SEV-3 (Medium)
- Minor performance issues
- Non-critical bug
- Response time: Within 4 hours
- Escalation: Create ticket

## Incident Response Procedure

### 1. Detection & Assessment (5 minutes)
- [ ] Confirm incident via monitoring dashboards
- [ ] Assess severity level
- [ ] Create incident channel (#incident-YYYY-MM-DD)
- [ ] Assign incident commander

### 2. Initial Response (15 minutes)
- [ ] Update status page (status.sfops.io)
- [ ] Notify affected customers (SEV-1/SEV-2 only)
- [ ] Begin incident log in shared doc
- [ ] Assemble response team

### 3. Diagnosis (30 minutes)
- [ ] Check recent deployments
- [ ] Review error logs and metrics
- [ ] Identify root cause hypothesis
- [ ] Document findings

### 4. Mitigation
- [ ] Execute rollback if needed (see [deployment-failures.md](./deployment-failures.md))
- [ ] Apply hotfix if available
- [ ] Scale resources if capacity issue
- [ ] Implement temporary workaround

### 5. Recovery
- [ ] Verify service restoration
- [ ] Run smoke tests
- [ ] Monitor for recurrence (30 minutes)
- [ ] Update status page: Resolved

### 6. Post-Incident (Within 48 hours)
- [ ] Conduct blameless postmortem
- [ ] Document timeline and root cause
- [ ] Create action items for prevention
- [ ] Update runbooks if needed
- [ ] Share learnings with team

## Common Incidents

### Database Connection Pool Exhausted

**Symptoms**: API returns 500 errors, logs show "cannot acquire connection"

**Diagnosis**:
```bash
kubectl exec -it <api-pod> -- node
> const { Pool } = require('pg')
> const pool = new Pool({ connectionString: process.env.DATABASE_URL })
> pool.totalCount  // Check total connections
```

**Resolution**:
```bash
# Scale down API pods to reduce connections
kubectl scale deployment sfops-api --replicas=2

# Or increase RDS connection limit
aws rds modify-db-instance --db-instance-identifier production-sfops-db \
  --max-connections 200 --apply-immediately
```

### Deployment Workflow Stuck

**Symptoms**: Deployment shows "running" for > 1 hour

**Diagnosis**:
- Check Temporal UI: http://temporal-ui.sfops.io
- Review workflow execution history
- Check worker logs for errors

**Resolution**:
```bash
# Terminate stuck workflow
temporal workflow terminate --workflow-id deployment-<id>

# Restart workers
kubectl rollout restart deployment/sfops-workers
```

### Salesforce API Rate Limit

**Symptoms**: Deployments failing with "API_LIMIT_EXCEEDED"

**Diagnosis**:
- Check Salesforce System Overview
- Review API usage in last 24 hours

**Resolution**:
- Implement exponential backoff (already in code)
- Contact Salesforce to increase limits
- Spread deployments over time

### Vault Sealed

**Symptoms**: API returns "Vault is sealed" errors

**Diagnosis**:
```bash
kubectl exec -it vault-0 -- vault status
```

**Resolution**:
```bash
# Unseal Vault (requires 3 of 5 unseal keys)
kubectl exec -it vault-0 -- vault operator unseal <key1>
kubectl exec -it vault-0 -- vault operator unseal <key2>
kubectl exec -it vault-0 -- vault operator unseal <key3>

# Verify
kubectl exec -it vault-0 -- vault status
```

## Escalation Contacts

- **Primary On-Call**: PagerDuty rotation
- **Engineering Lead**: eng-lead@sfops.io
- **Infrastructure Team**: infra@sfops.io
- **Security Team**: security@sfops.io

## Tools & Dashboards

- **Grafana**: https://grafana.sfops.io
- **Jaeger**: https://jaeger.sfops.io
- **Temporal UI**: https://temporal-ui.sfops.io
- **Kibana**: https://kibana.sfops.io
- **PagerDuty**: https://sfops.pagerduty.com

## Post-Incident Template

```markdown
# Incident Report: [Brief Description]

**Date**: YYYY-MM-DD
**Severity**: SEV-X
**Duration**: X hours Y minutes
**Affected Customers**: X customers, Y deployments

## Timeline (UTC)
- HH:MM - Incident detected
- HH:MM - Team assembled
- HH:MM - Root cause identified
- HH:MM - Mitigation deployed
- HH:MM - Service restored

## Root Cause
[Detailed explanation]

## Impact
- [Customer impact]
- [Business impact]
- [Data integrity]

## Resolution
[What was done to fix]

## Action Items
- [ ] [Prevention measure 1] - Owner: @person
- [ ] [Monitoring improvement] - Owner: @person
- [ ] [Documentation update] - Owner: @person

## Lessons Learned
[Key takeaways]
```
