# Deployment Failures Runbook

## Common Deployment Failures

### 1. Validation Errors

**Symptoms**: Deployment fails in validation phase with component errors

**Diagnosis**:
```bash
# Get deployment details
curl -H "Authorization: Bearer $TOKEN" \
  https://api.sfops.io/api/v1/tenants/$TENANT_ID/deploys/$DEPLOY_ID

# Review validation errors
kubectl logs -l app=sfops-workers --tail=100 | grep -A 10 "validation failed"
```

**Common Causes**:
- Missing dependencies
- Invalid field references
- Profile/Permission Set issues
- API version incompatibility

**Resolution**:
1. Review error messages in deployment results
2. Fix component issues
3. Re-validate deployment (checkOnly: true)
4. Deploy after validation passes

### 2. Test Failures

**Symptoms**: Deployment fails due to Apex test failures

**Diagnosis**:
```bash
# Get test results from deployment
curl -H "Authorization: Bearer $TOKEN" \
  https://api.sfops.io/api/v1/tenants/$TENANT_ID/deploys/$DEPLOY_ID \
  | jq '.details.runTestResult'
```

**Resolution**:
1. Identify failing test methods
2. Check test coverage (minimum 75% required)
3. Fix failing tests locally
4. Run tests in sandbox first
5. Redeploy

### 3. Timeout

**Symptoms**: Deployment times out after 1 hour

**Diagnosis**:
- Check Salesforce System Status
- Review deployment package size
- Check API usage

**Resolution**:
```bash
# Cancel stuck deployment
curl -X POST -H "Authorization: Bearer $TOKEN" \
  https://api.sfops.io/api/v1/tenants/$TENANT_ID/deploys/$DEPLOY_ID/cancel

# Split package into smaller batches
# Deploy non-dependent components first
# Deploy dependent components after
```

### 4. Partial Success

**Symptoms**: Some components deployed, others failed

**Diagnosis**:
```sql
-- Check deployment results
SELECT component_type, component_name, status, message
FROM deployment_results
WHERE deployment_id = '<deploy-id>'
  AND status = 'failed';
```

**Resolution**:
1. Review failed components
2. Fix dependency issues
3. Create new package with only failed components
4. Redeploy

### 5. Rollback Needed

**Symptoms**: Deployment succeeded but introduced bugs

**Procedure**:
```bash
# 1. Initiate rollback
curl -X POST -H "Authorization: Bearer $TOKEN" \
  https://api.sfops.io/api/v1/tenants/$TENANT_ID/deploys/$DEPLOY_ID/rollback

# 2. Monitor rollback progress
watch -n 5 "curl -s -H 'Authorization: Bearer $TOKEN' \
  https://api.sfops.io/api/v1/tenants/$TENANT_ID/deploys/$ROLLBACK_ID \
  | jq '.status'"

# 3. Verify restoration
# - Check org functionality
# - Run smoke tests
# - Verify data integrity

# 4. Investigate root cause
# - Review deployment logs
# - Check what changed
# - Update tests to catch this scenario
```

## Automatic Rollback Triggers

The system automatically rolls back if:
- Test coverage < 75%
- Critical test failures
- Deployment takes > 60 minutes
- Error rate > 50% of components

## Manual Rollback Procedure

### Pre-Deployment Snapshot Exists

```bash
# Find backup for deployment
curl -H "Authorization: Bearer $TOKEN" \
  "https://api.sfops.io/api/v1/tenants/$TENANT_ID/backups?deploymentId=$DEPLOY_ID"

# Restore from backup
curl -X POST -H "Authorization: Bearer $TOKEN" \
  https://api.sfops.io/api/v1/tenants/$TENANT_ID/backups/$BACKUP_ID/restore \
  -d '{"targetOrgId": "<org-id>"}'
```

### No Snapshot Available

```bash
# 1. Create reverse package
# - Retrieve current state
# - Compare with pre-deployment state
# - Generate reverse changeset

# 2. Manual steps in Salesforce
# - Delete newly created components
# - Restore modified components
# - Revert configuration changes

# 3. Verify restoration
# - Run validation
# - Test critical functionality
# - Check audit logs
```

## Prevention Best Practices

### Before Deployment

- [ ] Run validation (checkOnly: true)
- [ ] Verify all tests pass in source org
- [ ] Check dependencies are included
- [ ] Review deployment package size
- [ ] Ensure backup is created
- [ ] Schedule deployment during low-usage window

### During Deployment

- [ ] Monitor progress in real-time
- [ ] Watch for warnings
- [ ] Check Salesforce System Status
- [ ] Be ready to cancel if issues arise

### After Deployment

- [ ] Run smoke tests
- [ ] Verify critical functionality
- [ ] Monitor error rates
- [ ] Check user feedback
- [ ] Document any issues

## Emergency Contacts

- **Deployment Issues**: deployments@sfops.io
- **Salesforce Support**: Premier Support hotline
- **On-Call Engineer**: PagerDuty rotation

## Escalation Path

1. **L1** (0-15 min): Check runbook, attempt automated rollback
2. **L2** (15-30 min): Escalate to deployment team
3. **L3** (30-60 min): Escalate to engineering lead
4. **L4** (60+ min): Contact Salesforce support, involve senior leadership

## Post-Deployment Failure Checklist

- [ ] Document failure in incident log
- [ ] Update deployment with failure details
- [ ] Notify affected users
- [ ] Schedule postmortem
- [ ] Create action items for prevention
- [ ] Update tests to catch this scenario
- [ ] Update runbook if new failure mode discovered
