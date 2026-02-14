public class SFOpsScanBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Id scanId;
    private List<Scan_Issue__c> allIssues = new List<Scan_Issue__c>();

    public SFOpsScanBatch(Id scanId) {
        this.scanId = scanId;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Scan__c scan = [SELECT Id, Branch__c, Environment__c FROM Scan__c WHERE Id = :scanId LIMIT 1];
        update new Scan__c(Id = scanId, Status__c = 'Running');
        return Database.getQueryLocator([
            SELECT Id, Name, API_Name__c, Metadata_Type__c, XML_Content__c
            FROM Component__c WHERE Branch__c = :scan.Branch__c AND Is_Deleted__c = false
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Component__c> scope) {
        for (Component__c comp : scope) {
            if (comp.Metadata_Type__c == 'ApexClass' || comp.Metadata_Type__c == 'ApexTrigger') {
                allIssues.addAll(SFOpsApexAnalyzer.analyzeApexClass(comp.API_Name__c, comp.XML_Content__c));
            }
        }
        EventBus.publish(new Scan_Progress__e(
            Scan_Id__c = scanId, Status__c = 'Running',
            Components_Processed__c = scope.size(),
            Issues_Found__c = allIssues.size(),
            Message__c = 'Scanning components'
        ));
    }

    public void finish(Database.BatchableContext bc) {
        SFOpsScanEngine.completeScan(scanId, allIssues);
    }
}
