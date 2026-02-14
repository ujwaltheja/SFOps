public with sharing class SFOpsEnvironmentController {
    @AuraEnabled(cacheable=true)
    public static List<Environment__c> getEnvironments() {
        return SFOpsEnvironmentService.getAllEnvironments();
    }

    @AuraEnabled
    public static Environment__c createEnvironment(String name, String envType, String orgId, String instanceUrl) {
        try {
            return SFOpsEnvironmentService.createEnvironment(name, envType, orgId, instanceUrl);
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'createEnvironment'));
        }
    }

    @AuraEnabled
    public static Environment__c getEnvironment(Id environmentId) {
        return SFOpsEnvironmentService.getEnvironment(environmentId);
    }

    @AuraEnabled
    public static void deleteEnvironment(Id environmentId) {
        try {
            SFOpsEnvironmentService.deleteEnvironment(environmentId);
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'deleteEnvironment'));
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getEnvironmentStats() {
        return SFOpsEnvironmentService.getEnvironmentStats();
    }
}
