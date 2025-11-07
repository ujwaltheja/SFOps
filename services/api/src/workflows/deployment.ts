import { proxyActivities } from '@temporalio/workflow';
import type * as activities from './activities';

const {
  createBackup,
  buildDeploymentPackage,
  validateDeployment,
  executeDeployment,
  monitorDeployment,
  updateDeploymentStatus,
  recordDeploymentResults,
  sendNotification,
} = proxyActivities<typeof activities>({
  startToCloseTimeout: '10 minutes',
  retry: {
    initialInterval: '1s',
    backoffCoefficient: 2,
    maximumAttempts: 3,
  },
});

export interface DeploymentWorkflowInput {
  deploymentId: string;
  tenantId: string;
  packageId: string;
  targetOrgId: string;
  checkOnly: boolean;
  runTests: boolean;
  testLevel: string;
}

export async function deploymentWorkflow(input: DeploymentWorkflowInput): Promise<void> {
  const { deploymentId, tenantId, packageId, targetOrgId, checkOnly, runTests, testLevel } = input;

  try {
    // Update status to validating
    await updateDeploymentStatus(deploymentId, 'validating');

    // Step 1: Create pre-deployment backup (if not checkOnly)
    let backupId: string | null = null;
    if (!checkOnly) {
      backupId = await createBackup({
        deploymentId,
        tenantId,
        orgId: targetOrgId,
        backupType: 'pre_deploy',
      });
    }

    // Step 2: Build deployment package
    const packageData = await buildDeploymentPackage(packageId);

    // Step 3: Validate deployment
    const validationResult = await validateDeployment({
      deploymentId,
      tenantId,
      targetOrgId,
      packageData,
      checkOnly: true,
    });

    if (!validationResult.success) {
      await updateDeploymentStatus(deploymentId, 'failed');
      await recordDeploymentResults(deploymentId, validationResult.results);
      await sendNotification({
        tenantId,
        type: 'deployment_failed',
        data: { deploymentId, reason: 'Validation failed' },
      });
      return;
    }

    // If checkOnly, stop here
    if (checkOnly) {
      await updateDeploymentStatus(deploymentId, 'succeeded');
      await recordDeploymentResults(deploymentId, validationResult.results);
      await sendNotification({
        tenantId,
        type: 'validation_succeeded',
        data: { deploymentId },
      });
      return;
    }

    // Step 4: Execute deployment
    await updateDeploymentStatus(deploymentId, 'running');

    const salesforceDeployId = await executeDeployment({
      deploymentId,
      tenantId,
      targetOrgId,
      packageData,
      runTests,
      testLevel,
    });

    // Step 5: Monitor deployment progress
    const deployResult = await monitorDeployment({
      deploymentId,
      tenantId,
      targetOrgId,
      salesforceDeployId,
    });

    // Step 6: Record results
    await recordDeploymentResults(deploymentId, deployResult.results);

    // Step 7: Update final status
    if (deployResult.success) {
      await updateDeploymentStatus(deploymentId, 'succeeded');
      await sendNotification({
        tenantId,
        type: 'deployment_succeeded',
        data: { deploymentId },
      });
    } else {
      await updateDeploymentStatus(deploymentId, 'failed');
      await sendNotification({
        tenantId,
        type: 'deployment_failed',
        data: { deploymentId, reason: deployResult.error },
      });
    }

  } catch (error) {
    await updateDeploymentStatus(deploymentId, 'failed');
    await sendNotification({
      tenantId,
      type: 'deployment_failed',
      data: {
        deploymentId,
        reason: error instanceof Error ? error.message : 'Unknown error'
      },
    });
    throw error;
  }
}
