public with sharing class SFOpsOrgHealthCalculator {

    public static Org_Health_Score__c calculateHealthScore(Id environmentId) {
        SFOpsSecurityUtils.enforceCreateAccess('Org_Health_Score__c');

        Decimal codeQualityScore = getLatestScanScore(environmentId);
        Decimal securityScore = getSecurityScore(environmentId);
        Decimal debtScore = SFOpsDebtCalculator.calculateDebtScore(environmentId);
        Decimal configScore = 80;
        Decimal overallScore = ((codeQualityScore + securityScore + debtScore + configScore) / 4).setScale(2, RoundingMode.HALF_UP);

        String trend = determineTrend(environmentId, overallScore);

        Org_Health_Score__c healthScore = new Org_Health_Score__c(
            Environment__c = environmentId,
            Scan_Date__c = Datetime.now(),
            Overall_Score__c = overallScore,
            Code_Quality_Score__c = codeQualityScore,
            Security_Score__c = securityScore,
            Debt_Score__c = debtScore,
            Config_Score__c = configScore,
            Total_Components__c = getComponentCount(environmentId),
            Total_Issues__c = getOpenIssueCount(environmentId),
            Debt_Hours__c = getTotalDebtHours(),
            Trend__c = trend
        );
        insert healthScore;
        return healthScore;
    }

    private static Decimal getLatestScanScore(Id environmentId) {
        List<Scan__c> scans = [
            SELECT Quality_Score__c FROM Scan__c WHERE Environment__c = :environmentId AND Status__c = 'Complete'
            ORDER BY End_Time__c DESC LIMIT 1
        ];
        return scans.isEmpty() ? 100 : (scans[0].Quality_Score__c != null ? scans[0].Quality_Score__c : 100);
    }

    private static Decimal getSecurityScore(Id environmentId) {
        List<Scan__c> scans = [
            SELECT Critical_Count__c, High_Count__c FROM Scan__c
            WHERE Environment__c = :environmentId AND Type__c = 'Security' AND Status__c = 'Complete'
            ORDER BY End_Time__c DESC LIMIT 1
        ];
        if (scans.isEmpty()) return 100;
        Decimal score = 100 - ((scans[0].Critical_Count__c != null ? scans[0].Critical_Count__c : 0) * 10)
                            - ((scans[0].High_Count__c != null ? scans[0].High_Count__c : 0) * 5);
        return Math.max(0, score);
    }

    private static String determineTrend(Id environmentId, Decimal currentScore) {
        List<Org_Health_Score__c> previous = [
            SELECT Overall_Score__c FROM Org_Health_Score__c WHERE Environment__c = :environmentId
            ORDER BY Scan_Date__c DESC LIMIT 1
        ];
        if (previous.isEmpty()) return 'Stable';
        Decimal prevScore = previous[0].Overall_Score__c;
        if (currentScore > prevScore + 2) return 'Improving';
        if (currentScore < prevScore - 2) return 'Declining';
        return 'Stable';
    }

    private static Integer getComponentCount(Id environmentId) {
        Environment__c env = [SELECT Metadata_Count__c FROM Environment__c WHERE Id = :environmentId LIMIT 1];
        return env.Metadata_Count__c != null ? (Integer)env.Metadata_Count__c : 0;
    }

    private static Integer getOpenIssueCount(Id environmentId) {
        return [SELECT COUNT() FROM Scan_Issue__c WHERE Scan__r.Environment__c = :environmentId AND Status__c = 'Open'];
    }

    private static Decimal getTotalDebtHours() {
        AggregateResult[] results = [SELECT SUM(Estimated_Hours__c) total FROM Tech_Debt__c WHERE Status__c = 'Active'];
        return results[0].get('total') != null ? (Decimal)results[0].get('total') : 0;
    }

    public static List<Org_Health_Score__c> getHealthHistory(Id environmentId, Integer limitCount) {
        return [
            SELECT Id, Scan_Date__c, Overall_Score__c, Code_Quality_Score__c, Security_Score__c,
                   Debt_Score__c, Config_Score__c, Total_Components__c, Total_Issues__c, Trend__c
            FROM Org_Health_Score__c WHERE Environment__c = :environmentId
            ORDER BY Scan_Date__c DESC LIMIT :limitCount
        ];
    }
}
