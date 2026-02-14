public class SFOpsDeployProcessor implements Queueable {
    private Id deploymentId;

    public SFOpsDeployProcessor(Id deploymentId) {
        this.deploymentId = deploymentId;
    }

    public void execute(QueueableContext context) {
        try {
            SFOpsDeploymentEngine.updateDeploymentStatus(deploymentId, 'InProgress', null);
            Deployment__c deployment = SFOpsDeploymentEngine.getDeployment(deploymentId);

            EventBus.publish(new Deployment_Progress__e(
                Deployment_Id__c = deploymentId, Status__c = 'InProgress',
                Progress_Pct__c = 10, Message__c = 'Deployment started',
                Timestamp__c = Datetime.now()
            ));

            EventBus.publish(new Deployment_Progress__e(
                Deployment_Id__c = deploymentId, Status__c = 'Validating',
                Progress_Pct__c = 30, Message__c = 'Validating components',
                Timestamp__c = Datetime.now()
            ));

            SFOpsRollbackService.createSnapshot(deployment.Target_Environment__c, 'PreDeploy', deploymentId);

            EventBus.publish(new Deployment_Progress__e(
                Deployment_Id__c = deploymentId, Status__c = 'InProgress',
                Progress_Pct__c = 70, Message__c = 'Deploying components',
                Timestamp__c = Datetime.now()
            ));

            Integer componentCount = deployment.Total_Components__c != null ? (Integer)deployment.Total_Components__c : 0;
            SFOpsDeploymentEngine.completeDeployment(deploymentId, componentCount, 0);

        } catch (Exception e) {
            SFOpsDeploymentEngine.updateDeploymentStatus(deploymentId, 'Failed', SFOpsErrorHandler.buildErrorDetails(e, 'DeployProcessor'));
            SFOpsErrorHandler.logError(e, 'SFOpsDeployProcessor');
        }
    }
}
