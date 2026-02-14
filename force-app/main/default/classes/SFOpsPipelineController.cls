public with sharing class SFOpsPipelineController {
    @AuraEnabled(cacheable=true)
    public static List<Pipeline__c> getPipelines() {
        return SFOpsPipelineOrchestrator.getAllPipelines();
    }

    @AuraEnabled
    public static Pipeline__c createPipeline(String name, String description, String pipelineType) {
        try {
            return SFOpsPipelineOrchestrator.createPipeline(name, description, pipelineType);
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'createPipeline'));
        }
    }

    @AuraEnabled
    public static Pipeline__c getPipelineWithStages(Id pipelineId) {
        try {
            return SFOpsPipelineOrchestrator.getPipeline(pipelineId);
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'getPipelineWithStages'));
        }
    }

    @AuraEnabled
    public static Deployment__c executePipeline(Id pipelineId, Id sourceBranchId, Id targetEnvironmentId) {
        try {
            return SFOpsPipelineOrchestrator.executePipeline(pipelineId, sourceBranchId, targetEnvironmentId);
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'executePipeline'));
        }
    }

    @AuraEnabled(cacheable=true)
    public static Deployment__c getDeployment(Id deploymentId) {
        return SFOpsDeploymentEngine.getDeployment(deploymentId);
    }

    @AuraEnabled(cacheable=true)
    public static List<Deployment__c> getDeploymentHistory(Id environmentId, Integer limitCount) {
        return SFOpsDeploymentEngine.getDeploymentHistory(environmentId, limitCount != null ? limitCount : 50);
    }

    @AuraEnabled
    public static Deployment__c cancelDeployment(Id deploymentId) {
        try {
            return SFOpsDeploymentEngine.cancelDeployment(deploymentId);
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'cancelDeployment'));
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDeploymentStats() {
        return SFOpsDeploymentEngine.getDeploymentStats();
    }
}
