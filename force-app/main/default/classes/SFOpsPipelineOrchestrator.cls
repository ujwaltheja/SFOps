public with sharing class SFOpsPipelineOrchestrator {

    public static Pipeline__c createPipeline(String name, String description, String pipelineType) {
        SFOpsSecurityUtils.enforceCreateAccess('Pipeline__c');
        SFOpsLicenseService.enforcePipelineLimit();

        Pipeline__c pipeline = new Pipeline__c(
            Name = name,
            Description__c = description,
            Type__c = pipelineType,
            Status__c = 'Draft',
            Total_Stages__c = 0,
            Success_Rate__c = 0,
            Avg_Duration__c = 0,
            Is_Default__c = false
        );
        insert pipeline;
        return pipeline;
    }

    public static Pipeline_Stage__c addStage(Id pipelineId, String name, String stageType, Integer stageOrder, Id targetEnvironmentId) {
        SFOpsSecurityUtils.enforceCreateAccess('Pipeline_Stage__c');
        Pipeline_Stage__c stage = new Pipeline_Stage__c(
            Name = name,
            Pipeline__c = pipelineId,
            Order__c = stageOrder,
            Type__c = stageType,
            Target_Environment__c = targetEnvironmentId,
            Auto_Trigger__c = true,
            On_Failure_Action__c = 'Block',
            Timeout_Minutes__c = 60
        );
        insert stage;

        Pipeline__c pipeline = new Pipeline__c(Id = pipelineId);
        pipeline.Total_Stages__c = [SELECT COUNT() FROM Pipeline_Stage__c WHERE Pipeline__c = :pipelineId];
        update pipeline;
        return stage;
    }

    public static Pipeline__c getPipeline(Id pipelineId) {
        SFOpsSecurityUtils.enforceReadAccess('Pipeline__c');
        return [
            SELECT Id, Name, Description__c, Type__c, Status__c, Total_Stages__c,
                   Success_Rate__c, Avg_Duration__c, Last_Run_Date__c, Is_Default__c,
                   (SELECT Id, Name, Order__c, Type__c, Target_Environment__c,
                           Auto_Trigger__c, On_Failure_Action__c, Quality_Gate__c, Timeout_Minutes__c
                    FROM Pipeline_Stages__r ORDER BY Order__c ASC)
            FROM Pipeline__c WHERE Id = :pipelineId LIMIT 1
        ];
    }

    public static List<Pipeline__c> getAllPipelines() {
        SFOpsSecurityUtils.enforceReadAccess('Pipeline__c');
        return [
            SELECT Id, Name, Type__c, Status__c, Total_Stages__c, Success_Rate__c, Last_Run_Date__c
            FROM Pipeline__c WHERE Status__c != 'Archived' ORDER BY Name ASC
        ];
    }

    public static Deployment__c executePipeline(Id pipelineId, Id sourceBranchId, Id targetEnvironmentId) {
        SFOpsSecurityUtils.enforceCreateAccess('Deployment__c');
        Pipeline__c pipeline = getPipeline(pipelineId);
        if (pipeline == null || pipeline.Status__c != 'Active') {
            throw new SFOpsErrorHandler.ValidationException('Pipeline is not active');
        }

        Deployment__c deployment = new Deployment__c(
            Pipeline__c = pipelineId,
            Source_Branch__c = sourceBranchId,
            Target_Environment__c = targetEnvironmentId,
            Status__c = 'Pending',
            Start_Time__c = Datetime.now(),
            Total_Components__c = 0,
            Success_Count__c = 0,
            Error_Count__c = 0,
            Initiated_By__c = UserInfo.getName()
        );
        insert deployment;

        pipeline.Last_Run_Date__c = Datetime.now();
        update pipeline;

        SFOpsAuditService.logDeployment(deployment.Id, targetEnvironmentId,
            'Pipeline execution started: ' + pipeline.Name, SFOpsAuditService.STATUS_SUCCESS, 0);

        return deployment;
    }

    public static void activatePipeline(Id pipelineId) {
        SFOpsSecurityUtils.enforceUpdateAccess('Pipeline__c');
        update new Pipeline__c(Id = pipelineId, Status__c = 'Active');
    }

    public static void archivePipeline(Id pipelineId) {
        SFOpsSecurityUtils.enforceUpdateAccess('Pipeline__c');
        update new Pipeline__c(Id = pipelineId, Status__c = 'Archived');
    }

    public static void updatePipelineStats(Id pipelineId) {
        List<Deployment__c> deployments = [
            SELECT Status__c, Duration__c FROM Deployment__c WHERE Pipeline__c = :pipelineId
        ];
        if (deployments.isEmpty()) return;

        Integer total = deployments.size();
        Integer successes = 0;
        Decimal totalDuration = 0;
        for (Deployment__c d : deployments) {
            if (d.Status__c == 'Success') successes++;
            if (d.Duration__c != null) totalDuration += d.Duration__c;
        }

        Pipeline__c pipeline = new Pipeline__c(Id = pipelineId);
        pipeline.Success_Rate__c = (Decimal.valueOf(successes) / Decimal.valueOf(total)) * 100;
        pipeline.Avg_Duration__c = totalDuration / total;
        update pipeline;
    }
}
