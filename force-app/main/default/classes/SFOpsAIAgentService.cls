public with sharing class SFOpsAIAgentService {
    public static Agent_Execution__c executeAgent(String agentType, String inputData, Id deploymentId, Id scanId) {
        SFOpsLicenseService.enforceFeature(SFOpsLicenseService.FEATURE_AI_AGENTS);
        SFOpsSecurityUtils.enforceCreateAccess('Agent_Execution__c');
        Agent_Execution__c execution = new Agent_Execution__c(
            Agent_Type__c = agentType, Input_Data__c = inputData,
            Deployment__c = deploymentId, Scan__c = scanId, Status__c = 'Pending'
        );
        insert execution;
        return execution;
    }

    public static Agent_Execution__c completeExecution(Id executionId, String outputData, Integer tokensUsed, Decimal confidence) {
        Agent_Execution__c execution = new Agent_Execution__c(
            Id = executionId, Output_Data__c = outputData,
            Tokens_Used__c = tokensUsed, Status__c = 'Complete', Confidence_Score__c = confidence
        );
        update execution;
        return execution;
    }

    public static Agent_Execution__c failExecution(Id executionId, String errorMessage) {
        Agent_Execution__c execution = new Agent_Execution__c(
            Id = executionId, Error_Message__c = errorMessage, Status__c = 'Failed'
        );
        update execution;
        return execution;
    }

    public static String getPromptTemplate(String agentType) {
        List<AI_Prompt_Template__mdt> templates = [
            SELECT System_Prompt__c, User_Prompt_Template__c, Max_Tokens__c, Temperature__c
            FROM AI_Prompt_Template__mdt WHERE Agent_Type__c = :agentType LIMIT 1
        ];
        return templates.isEmpty() ? null : templates[0].System_Prompt__c;
    }

    public static List<Agent_Execution__c> getRecentExecutions(Integer limitCount) {
        return [SELECT Id, Name, Agent_Type__c, Status__c, Duration_Ms__c, Tokens_Used__c,
                       Confidence_Score__c, CreatedDate
                FROM Agent_Execution__c ORDER BY CreatedDate DESC LIMIT :limitCount];
    }
}
