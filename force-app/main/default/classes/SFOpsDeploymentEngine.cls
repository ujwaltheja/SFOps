public with sharing class SFOpsDeploymentEngine {

    public static Deployment__c getDeployment(Id deploymentId) {
        SFOpsSecurityUtils.enforceReadAccess('Deployment__c');
        return [
            SELECT Id, Name, Pipeline__c, Source_Branch__c, Target_Environment__c,
                   Status__c, Start_Time__c, End_Time__c, Duration__c, Total_Components__c,
                   Success_Count__c, Error_Count__c, Initiated_By__c, Error_Log__c, AI_Risk_Score__c,
                   Target_Environment__r.Name, Target_Environment__r.Instance_URL__c
            FROM Deployment__c WHERE Id = :deploymentId LIMIT 1
        ];
    }

    public static List<Deployment__c> getDeploymentHistory(Id environmentId, Integer limitCount) {
        SFOpsSecurityUtils.enforceReadAccess('Deployment__c');
        String query = 'SELECT Id, Name, Pipeline__c, Source_Branch__c, Target_Environment__c, Status__c, Start_Time__c, End_Time__c, Duration__c, Total_Components__c, Success_Count__c, Error_Count__c, Initiated_By__c, AI_Risk_Score__c FROM Deployment__c';
        if (environmentId != null) query += ' WHERE Target_Environment__c = :environmentId';
        query += ' ORDER BY Start_Time__c DESC LIMIT :limitCount';
        return Database.query(query);
    }

    public static Deployment__c updateDeploymentStatus(Id deploymentId, String status, String errorLog) {
        SFOpsSecurityUtils.enforceUpdateAccess('Deployment__c');
        Deployment__c deployment = new Deployment__c(Id = deploymentId, Status__c = status);
        if (status == 'Success' || status == 'Failed' || status == 'RolledBack' || status == 'Cancelled') {
            deployment.End_Time__c = Datetime.now();
        }
        if (String.isNotBlank(errorLog)) deployment.Error_Log__c = errorLog;
        update deployment;

        EventBus.publish(new Deployment_Progress__e(
            Deployment_Id__c = deploymentId, Status__c = status,
            Message__c = 'Deployment status updated to ' + status,
            Timestamp__c = Datetime.now()
        ));

        return deployment;
    }

    public static Deployment__c completeDeployment(Id deploymentId, Integer successCount, Integer errorCount) {
        Deployment__c deployment = [SELECT Id, Start_Time__c FROM Deployment__c WHERE Id = :deploymentId LIMIT 1];
        deployment.Status__c = errorCount > 0 ? 'Failed' : 'Success';
        deployment.End_Time__c = Datetime.now();
        deployment.Success_Count__c = successCount;
        deployment.Error_Count__c = errorCount;
        if (deployment.Start_Time__c != null) {
            Long durationMs = deployment.End_Time__c.getTime() - deployment.Start_Time__c.getTime();
            deployment.Duration__c = durationMs / 1000;
        }
        update deployment;

        SFOpsAuditService.logDeployment(deploymentId, deployment.Target_Environment__c,
            'Deployment completed: ' + deployment.Status__c, deployment.Status__c == 'Success' ? SFOpsAuditService.STATUS_SUCCESS : SFOpsAuditService.STATUS_FAILURE,
            successCount + errorCount);

        return deployment;
    }

    public static Deployment__c cancelDeployment(Id deploymentId) {
        return updateDeploymentStatus(deploymentId, 'Cancelled', 'Deployment cancelled by user');
    }

    public static Map<String, Object> getDeploymentStats() {
        Map<String, Object> stats = new Map<String, Object>();
        stats.put('total', [SELECT COUNT() FROM Deployment__c]);
        stats.put('successful', [SELECT COUNT() FROM Deployment__c WHERE Status__c = 'Success']);
        stats.put('failed', [SELECT COUNT() FROM Deployment__c WHERE Status__c = 'Failed']);
        stats.put('inProgress', [SELECT COUNT() FROM Deployment__c WHERE Status__c IN ('Pending', 'Queued', 'InProgress', 'Validating', 'Testing')]);
        return stats;
    }
}
