public with sharing class SFOpsScanEngine {

    public static Scan__c initiateScan(String scanType, String target, Id environmentId, Id branchId) {
        SFOpsSecurityUtils.enforceCreateAccess('Scan__c');
        Scan__c scan = new Scan__c(
            Type__c = scanType,
            Target__c = target,
            Environment__c = environmentId,
            Branch__c = branchId,
            Status__c = 'Queued',
            Start_Time__c = Datetime.now(),
            Total_Issues__c = 0,
            Critical_Count__c = 0,
            High_Count__c = 0,
            Medium_Count__c = 0,
            Low_Count__c = 0,
            Quality_Score__c = 100,
            Scanned_Components__c = 0
        );
        insert scan;

        SFOpsAuditService.logScan('Scan initiated: ' + scanType + ' on ' + target,
            SFOpsAuditService.STATUS_SUCCESS, environmentId);
        return scan;
    }

    public static Scan__c completeScan(Id scanId, List<Scan_Issue__c> issues) {
        SFOpsSecurityUtils.enforceUpdateAccess('Scan__c');
        if (issues != null && !issues.isEmpty()) {
            for (Scan_Issue__c issue : issues) issue.Scan__c = scanId;
            insert issues;
        }

        Integer criticalCount = 0, highCount = 0, mediumCount = 0, lowCount = 0;
        if (issues != null) {
            for (Scan_Issue__c issue : issues) {
                if (issue.Severity__c == 'Critical') criticalCount++;
                else if (issue.Severity__c == 'High') highCount++;
                else if (issue.Severity__c == 'Medium') mediumCount++;
                else if (issue.Severity__c == 'Low') lowCount++;
            }
        }

        Integer totalIssues = issues != null ? issues.size() : 0;
        Decimal qualityScore = calculateQualityScore(criticalCount, highCount, mediumCount, lowCount);

        Scan__c scan = new Scan__c(
            Id = scanId, Status__c = 'Complete', End_Time__c = Datetime.now(),
            Total_Issues__c = totalIssues, Critical_Count__c = criticalCount,
            High_Count__c = highCount, Medium_Count__c = mediumCount,
            Low_Count__c = lowCount, Quality_Score__c = qualityScore
        );
        update scan;
        return scan;
    }

    public static Decimal calculateQualityScore(Integer critical, Integer high, Integer medium, Integer low) {
        Decimal score = 100;
        score -= (critical != null ? critical : 0) * 10;
        score -= (high != null ? high : 0) * 5;
        score -= (medium != null ? medium : 0) * 2;
        score -= (low != null ? low : 0) * 0.5;
        return Math.max(0, score);
    }

    public static Scan__c getScan(Id scanId) {
        SFOpsSecurityUtils.enforceReadAccess('Scan__c');
        return [
            SELECT Id, Name, Type__c, Target__c, Status__c, Start_Time__c, End_Time__c,
                   Total_Issues__c, Critical_Count__c, High_Count__c, Medium_Count__c, Low_Count__c,
                   Quality_Score__c, Debt_Hours_Added__c, Scanned_Components__c,
                   Environment__c, Branch__c, Deployment__c
            FROM Scan__c WHERE Id = :scanId LIMIT 1
        ];
    }

    public static List<Scan__c> getRecentScans(Integer limitCount) {
        SFOpsSecurityUtils.enforceReadAccess('Scan__c');
        return [
            SELECT Id, Name, Type__c, Target__c, Status__c, Start_Time__c, End_Time__c,
                   Total_Issues__c, Critical_Count__c, Quality_Score__c
            FROM Scan__c ORDER BY Start_Time__c DESC LIMIT :limitCount
        ];
    }

    public static List<Scan_Issue__c> getScanIssues(Id scanId) {
        SFOpsSecurityUtils.enforceReadAccess('Scan_Issue__c');
        return [
            SELECT Id, Name, Severity__c, Category__c, Component_Name__c, Line_Number__c,
                   Description__c, AI_Fix_Suggestion__c, Status__c, Fix_Effort_Hours__c, Assigned_To__c
            FROM Scan_Issue__c WHERE Scan__c = :scanId ORDER BY Severity__c ASC, Component_Name__c ASC
        ];
    }
}
