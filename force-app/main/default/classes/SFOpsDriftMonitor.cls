public with sharing class SFOpsDriftMonitor {

    public static List<Operational_Alert__c> detectDrift(Id environmentId) {
        SFOpsSecurityUtils.enforceCreateAccess('Operational_Alert__c');
        List<Operational_Alert__c> alerts = new List<Operational_Alert__c>();

        List<Snapshot__c> snapshots = [
            SELECT Id, Component_Count__c, Snapshot_Date__c FROM Snapshot__c
            WHERE Environment__c = :environmentId AND Is_Restorable__c = true
            ORDER BY Snapshot_Date__c DESC LIMIT 2
        ];

        if (snapshots.size() < 2) return alerts;

        if (snapshots[0].Component_Count__c != snapshots[1].Component_Count__c) {
            alerts.add(new Operational_Alert__c(
                Alert_Type__c = 'Drift',
                Severity__c = 'Medium',
                Environment__c = environmentId,
                Description__c = 'Component count changed from ' + snapshots[1].Component_Count__c + ' to ' + snapshots[0].Component_Count__c,
                Detected_At__c = Datetime.now(),
                Status__c = 'New'
            ));
        }

        if (!alerts.isEmpty()) insert alerts;
        return alerts;
    }

    public static List<Operational_Alert__c> getAlerts(Id environmentId, Integer limitCount) {
        SFOpsSecurityUtils.enforceReadAccess('Operational_Alert__c');
        return [
            SELECT Id, Name, Alert_Type__c, Severity__c, Description__c, Detected_At__c, Status__c, Environment__c
            FROM Operational_Alert__c
            WHERE (Environment__c = :environmentId OR :environmentId = null) AND Status__c != 'Dismissed'
            ORDER BY Detected_At__c DESC LIMIT :limitCount
        ];
    }

    public static void acknowledgeAlert(Id alertId) {
        SFOpsSecurityUtils.enforceUpdateAccess('Operational_Alert__c');
        update new Operational_Alert__c(Id = alertId, Status__c = 'Acknowledged');
    }

    public static void resolveAlert(Id alertId, String notes) {
        SFOpsSecurityUtils.enforceUpdateAccess('Operational_Alert__c');
        update new Operational_Alert__c(
            Id = alertId, Status__c = 'Resolved',
            Resolution_Notes__c = notes, Resolved_At__c = Datetime.now(), Resolved_By__c = UserInfo.getName()
        );
    }
}
