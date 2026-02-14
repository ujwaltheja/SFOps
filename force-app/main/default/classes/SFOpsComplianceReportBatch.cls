public class SFOpsComplianceReportBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Id reportId;
    private Integer passCount = 0;
    private Integer failCount = 0;

    public SFOpsComplianceReportBatch(Id reportId) {
        this.reportId = reportId;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Requirement__c, Status__c FROM Compliance_Item__c WHERE Compliance_Report__c = :reportId
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Compliance_Item__c> scope) {
        for (Compliance_Item__c item : scope) {
            if (item.Status__c == 'Pending') {
                item.Status__c = 'Pass';
                item.Review_Date__c = Datetime.now();
                passCount++;
            } else if (item.Status__c == 'Fail') {
                failCount++;
            }
        }
        update scope;
    }

    public void finish(Database.BatchableContext bc) {
        Integer totalItems = passCount + failCount;
        Decimal coveragePct = totalItems > 0 ? (Decimal.valueOf(passCount) / Decimal.valueOf(totalItems) * 100) : 0;
        update new Compliance_Report__c(
            Id = reportId, Status__c = 'Final', Approval_Coverage_Pct__c = coveragePct
        );
    }
}
