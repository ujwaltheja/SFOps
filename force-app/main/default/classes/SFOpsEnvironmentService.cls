public with sharing class SFOpsEnvironmentService {

    public static Environment__c createEnvironment(String name, String envType, String orgId, String instanceUrl) {
        SFOpsSecurityUtils.enforceCreateAccess('Environment__c');
        SFOpsLicenseService.enforceEnvironmentLimit();

        Environment__c env = new Environment__c(
            Name = name,
            Type__c = envType,
            Org_Id__c = orgId,
            Instance_URL__c = instanceUrl,
            Auth_Status__c = 'Disconnected',
            API_Version__c = '62.0',
            Is_Production__c = (envType == 'Production'),
            Metadata_Count__c = 0
        );
        insert env;

        SFOpsAuditService.logEvent(SFOpsAuditService.ACTION_CONFIG_CHANGE,
            'Environment created: ' + name + ' (' + envType + ')', SFOpsAuditService.STATUS_SUCCESS, env.Id);

        return env;
    }

    public static Environment__c getEnvironment(Id environmentId) {
        SFOpsSecurityUtils.enforceReadAccess('Environment__c');
        List<Environment__c> envs = [
            SELECT Id, Name, Type__c, Auth_Status__c, Org_Id__c, Instance_URL__c,
                   Last_Sync_Date__c, Metadata_Count__c, API_Version__c, Is_Production__c
            FROM Environment__c WHERE Id = :environmentId LIMIT 1
        ];
        return envs.isEmpty() ? null : envs[0];
    }

    public static List<Environment__c> getAllEnvironments() {
        SFOpsSecurityUtils.enforceReadAccess('Environment__c');
        return [
            SELECT Id, Name, Type__c, Auth_Status__c, Org_Id__c, Instance_URL__c,
                   Last_Sync_Date__c, Metadata_Count__c, API_Version__c, Is_Production__c
            FROM Environment__c ORDER BY Name ASC
        ];
    }

    public static Environment__c updateAuthStatus(Id environmentId, String status) {
        SFOpsSecurityUtils.enforceUpdateAccess('Environment__c');
        Environment__c env = new Environment__c(Id = environmentId, Auth_Status__c = status);
        update env;

        EventBus.publish(new Environment_Status_Changed__e(
            Environment_Id__c = environmentId,
            New_Status__c = status,
            Message__c = 'Auth status changed to ' + status
        ));

        return env;
    }

    public static void storeOAuthTokens(Id environmentId, String accessToken, String refreshToken) {
        SFOpsSecurityUtils.enforceUpdateAccess('Environment__c');
        Environment__c env = new Environment__c(
            Id = environmentId,
            Access_Token__c = accessToken,
            Refresh_Token__c = refreshToken,
            Auth_Status__c = 'Connected'
        );
        update env;
    }

    public static Environment__c updateMetadataCount(Id environmentId, Integer count) {
        SFOpsSecurityUtils.enforceUpdateAccess('Environment__c');
        Environment__c env = new Environment__c(
            Id = environmentId,
            Metadata_Count__c = count,
            Last_Sync_Date__c = Datetime.now()
        );
        update env;
        return env;
    }

    public static void deleteEnvironment(Id environmentId) {
        SFOpsSecurityUtils.enforceDeleteAccess('Environment__c');
        Environment__c env = [SELECT Id, Name FROM Environment__c WHERE Id = :environmentId LIMIT 1];
        SFOpsAuditService.logEvent(SFOpsAuditService.ACTION_DELETE,
            'Environment deleted: ' + env.Name, SFOpsAuditService.STATUS_SUCCESS);
        delete env;
    }

    public static Map<String, Integer> getEnvironmentStats() {
        Map<String, Integer> stats = new Map<String, Integer>();
        for (AggregateResult ar : [
            SELECT Type__c, COUNT(Id) cnt FROM Environment__c GROUP BY Type__c
        ]) {
            stats.put((String)ar.get('Type__c'), (Integer)ar.get('cnt'));
        }
        return stats;
    }
}
