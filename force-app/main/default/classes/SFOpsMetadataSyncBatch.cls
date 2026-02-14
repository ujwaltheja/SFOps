public class SFOpsMetadataSyncBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Integer totalProcessed = 0;
    private Id environmentId;

    public SFOpsMetadataSyncBatch(Id envId) {
        this.environmentId = envId;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, API_Name__c, Metadata_Type__c, Hash__c, XML_Content__c
            FROM Component__c WHERE Branch__r.Repository__c != null LIMIT 10000
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Component__c> scope) {
        totalProcessed += scope.size();
        EventBus.publish(new Deployment_Progress__e(
            Deployment_Id__c = environmentId,
            Status__c = 'Syncing',
            Progress_Pct__c = 50,
            Message__c = 'Processed ' + totalProcessed + ' components',
            Timestamp__c = Datetime.now()
        ));
    }

    public void finish(Database.BatchableContext bc) {
        SFOpsEnvironmentService.updateMetadataCount(environmentId, totalProcessed);
        SFOpsAuditService.logEvent(SFOpsAuditService.ACTION_CONFIG_CHANGE,
            'Metadata sync completed. Components: ' + totalProcessed,
            SFOpsAuditService.STATUS_SUCCESS, environmentId);
    }
}
