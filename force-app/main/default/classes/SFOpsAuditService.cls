public with sharing class SFOpsAuditService {
    public static final String ACTION_DEPLOY = 'Deploy';
    public static final String ACTION_ROLLBACK = 'Rollback';
    public static final String ACTION_SCAN = 'Scan';
    public static final String ACTION_CONFIG_CHANGE = 'ConfigChange';
    public static final String ACTION_ACCESS = 'Access';
    public static final String ACTION_OVERRIDE = 'Override';
    public static final String ACTION_DELETE = 'Delete';

    public static final String STATUS_SUCCESS = 'Success';
    public static final String STATUS_FAILURE = 'Failure';
    public static final String STATUS_ERROR = 'Error';
    public static final String STATUS_WARNING = 'Warning';

    public static Audit_Log__c logEvent(String actionType, String details, String status) {
        return logEvent(actionType, details, status, null, null, null);
    }

    public static Audit_Log__c logEvent(String actionType, String details, String status, Id environmentId) {
        return logEvent(actionType, details, status, environmentId, null, null);
    }

    public static Audit_Log__c logEvent(String actionType, String details, String status, Id environmentId, Id deploymentId, Integer componentCount) {
        Audit_Log__c log = new Audit_Log__c(
            Action_Type__c = actionType,
            Actor__c = UserInfo.getName() + ' (' + UserInfo.getUserId() + ')',
            Timestamp__c = Datetime.now(),
            Details__c = details != null && details.length() > 131072 ? details.substring(0, 131072) : details,
            Status__c = status,
            Environment__c = environmentId,
            Deployment__c = deploymentId,
            Component_Count__c = componentCount
        );
        try {
            insert log;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to create audit log: ' + e.getMessage());
        }
        return log;
    }

    public static Audit_Log__c logDeployment(Id deploymentId, Id environmentId, String details, String status, Integer componentCount) {
        return logEvent(ACTION_DEPLOY, details, status, environmentId, deploymentId, componentCount);
    }

    public static Audit_Log__c logRollback(Id deploymentId, Id environmentId, String details, String status) {
        return logEvent(ACTION_ROLLBACK, details, status, environmentId, deploymentId, null);
    }

    public static Audit_Log__c logScan(String details, String status, Id environmentId) {
        return logEvent(ACTION_SCAN, details, status, environmentId, null, null);
    }

    public static Audit_Log__c logConfigChange(String details) {
        return logEvent(ACTION_CONFIG_CHANGE, details, STATUS_SUCCESS, null, null, null);
    }

    public static List<Audit_Log__c> getAuditLogs(String actionType, Id environmentId, Datetime startDate, Datetime endDate, Integer limitCount) {
        SFOpsSecurityUtils.enforceReadAccess('Audit_Log__c');
        String query = 'SELECT Id, Name, Action_Type__c, Actor__c, Timestamp__c, Details__c, Status__c, Environment__c, Deployment__c, Component_Count__c, Duration_Ms__c FROM Audit_Log__c WHERE Timestamp__c != null';
        if (String.isNotBlank(actionType)) query += ' AND Action_Type__c = :actionType';
        if (environmentId != null) query += ' AND Environment__c = :environmentId';
        if (startDate != null) query += ' AND Timestamp__c >= :startDate';
        if (endDate != null) query += ' AND Timestamp__c <= :endDate';
        query += ' ORDER BY Timestamp__c DESC';
        if (limitCount != null && limitCount > 0) query += ' LIMIT :limitCount';
        return Database.query(query);
    }
}
