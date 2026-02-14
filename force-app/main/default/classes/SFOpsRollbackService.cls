public with sharing class SFOpsRollbackService {

    public static Snapshot__c createSnapshot(Id environmentId, String snapshotType, Id deploymentId) {
        SFOpsSecurityUtils.enforceCreateAccess('Snapshot__c');
        Setting__c settings = Setting__c.getInstance();
        Integer retentionDays = settings != null && settings.Retention_Days__c != null ? (Integer)settings.Retention_Days__c : 30;

        Snapshot__c snapshot = new Snapshot__c(
            Name = snapshotType + ' - ' + Datetime.now().format('yyyy-MM-dd HH:mm'),
            Environment__c = environmentId,
            Deployment__c = deploymentId,
            Snapshot_Date__c = Datetime.now(),
            Component_Count__c = 0,
            Size_MB__c = 0,
            Type__c = snapshotType,
            Retention_Days__c = retentionDays,
            Is_Restorable__c = true,
            Created_By_User__c = UserInfo.getName()
        );
        insert snapshot;
        return snapshot;
    }

    public static Deployment__c initiateRollback(Id deploymentId, Id snapshotId) {
        SFOpsSecurityUtils.enforceCreateAccess('Deployment__c');
        Deployment__c originalDeployment = [
            SELECT Id, Pipeline__c, Target_Environment__c FROM Deployment__c WHERE Id = :deploymentId LIMIT 1
        ];

        Deployment__c rollbackDeployment = new Deployment__c(
            Pipeline__c = originalDeployment.Pipeline__c,
            Target_Environment__c = originalDeployment.Target_Environment__c,
            Status__c = 'Pending',
            Start_Time__c = Datetime.now(),
            Initiated_By__c = UserInfo.getName(),
            Rollback_Deployment__c = deploymentId
        );
        insert rollbackDeployment;

        SFOpsDeploymentEngine.updateDeploymentStatus(deploymentId, 'RolledBack', 'Rolled back by ' + UserInfo.getName());
        SFOpsAuditService.logRollback(rollbackDeployment.Id, originalDeployment.Target_Environment__c,
            'Rollback initiated for deployment ' + deploymentId, SFOpsAuditService.STATUS_SUCCESS);

        return rollbackDeployment;
    }

    public static List<Snapshot__c> getSnapshots(Id environmentId) {
        SFOpsSecurityUtils.enforceReadAccess('Snapshot__c');
        return [
            SELECT Id, Name, Environment__c, Snapshot_Date__c, Component_Count__c, Size_MB__c,
                   Type__c, Is_Restorable__c, Created_By_User__c
            FROM Snapshot__c WHERE Environment__c = :environmentId AND Is_Restorable__c = true
            ORDER BY Snapshot_Date__c DESC
        ];
    }

    public static void cleanupExpiredSnapshots() {
        List<Snapshot__c> expired = [
            SELECT Id FROM Snapshot__c
            WHERE Is_Restorable__c = true AND Retention_Days__c != null
            AND Snapshot_Date__c < :Datetime.now().addDays(-30)
            LIMIT 5000
        ];
        if (!expired.isEmpty()) {
            for (Snapshot__c s : expired) s.Is_Restorable__c = false;
            update expired;
        }
    }
}
