public with sharing class SFOpsComplianceEngine {

    public static Compliance_Report__c generateReport(String reportType, Date periodStart, Date periodEnd) {
        SFOpsSecurityUtils.enforceCreateAccess('Compliance_Report__c');

        Compliance_Report__c report = new Compliance_Report__c(
            Type__c = reportType,
            Period_Start__c = periodStart,
            Period_End__c = periodEnd,
            Status__c = 'Draft',
            Generated_By__c = UserInfo.getName()
        );

        Datetime startDt = Datetime.newInstance(periodStart, Time.newInstance(0,0,0,0));
        Datetime endDt = Datetime.newInstance(periodEnd, Time.newInstance(23,59,59,0));
        report.Total_Deployments__c = [SELECT COUNT() FROM Deployment__c WHERE Start_Time__c >= :startDt AND Start_Time__c <= :endDt];
        report.Total_Changes__c = [SELECT COUNT() FROM Commit__c WHERE Commit_Timestamp__c >= :startDt AND Commit_Timestamp__c <= :endDt];

        insert report;
        generateComplianceItems(report.Id, reportType);
        return report;
    }

    private static void generateComplianceItems(Id reportId, String reportType) {
        List<Compliance_Template__mdt> templates = [
            SELECT Framework__c, Requirement_Id__c, Description__c, Check_Type__c, Auto_Evaluatable__c
            FROM Compliance_Template__mdt WHERE Framework__c = :reportType AND Auto_Evaluatable__c = true
        ];

        List<Compliance_Item__c> items = new List<Compliance_Item__c>();
        for (Compliance_Template__mdt template : templates) {
            items.add(new Compliance_Item__c(
                Compliance_Report__c = reportId,
                Requirement__c = template.Requirement_Id__c + ': ' + template.Description__c,
                Status__c = 'Pending'
            ));
        }
        if (!items.isEmpty()) insert items;
    }

    public static Compliance_Report__c getReport(Id reportId) {
        SFOpsSecurityUtils.enforceReadAccess('Compliance_Report__c');
        return [
            SELECT Id, Name, Type__c, Period_Start__c, Period_End__c, Status__c,
                   Total_Deployments__c, Total_Changes__c, Approval_Coverage_Pct__c,
                   Test_Coverage_Pct__c, Security_Score__c, Generated_By__c,
                   (SELECT Id, Requirement__c, Status__c, Evidence__c, Reviewer__c, Review_Date__c FROM Compliance_Items__r)
            FROM Compliance_Report__c WHERE Id = :reportId LIMIT 1
        ];
    }

    public static List<Compliance_Report__c> getReports(Integer limitCount) {
        SFOpsSecurityUtils.enforceReadAccess('Compliance_Report__c');
        return [
            SELECT Id, Name, Type__c, Period_Start__c, Period_End__c, Status__c, Total_Deployments__c
            FROM Compliance_Report__c ORDER BY CreatedDate DESC LIMIT :limitCount
        ];
    }

    public static void finalizeReport(Id reportId) {
        SFOpsSecurityUtils.enforceUpdateAccess('Compliance_Report__c');
        update new Compliance_Report__c(Id = reportId, Status__c = 'Final');
        SFOpsAuditService.logEvent(SFOpsAuditService.ACTION_CONFIG_CHANGE,
            'Compliance report finalized: ' + reportId, SFOpsAuditService.STATUS_SUCCESS);
    }
}
