public with sharing class SFOpsDebtCalculator {

    private static final Map<String, Decimal> SEVERITY_WEIGHTS = new Map<String, Decimal>{
        'Critical' => 4.0, 'High' => 2.0, 'Medium' => 1.0, 'Low' => 0.5
    };

    public static void createDebtFromScanIssues(Id scanId) {
        SFOpsSecurityUtils.enforceCreateAccess('Tech_Debt__c');
        List<Scan_Issue__c> issues = [
            SELECT Id, Severity__c, Category__c, Component_Name__c, Fix_Effort_Hours__c
            FROM Scan_Issue__c WHERE Scan__c = :scanId AND Status__c = 'Open'
        ];

        List<Tech_Debt__c> debtItems = new List<Tech_Debt__c>();
        for (Scan_Issue__c issue : issues) {
            debtItems.add(new Tech_Debt__c(
                Scan_Issue__c = issue.Id,
                Component_Name__c = issue.Component_Name__c,
                Debt_Type__c = mapCategoryToDebtType(issue.Category__c),
                Estimated_Hours__c = issue.Fix_Effort_Hours__c != null ? issue.Fix_Effort_Hours__c : estimateEffort(issue.Severity__c),
                Priority__c = mapSeverityToPriority(issue.Severity__c),
                Status__c = 'Active',
                First_Detected_Date__c = Date.today(),
                Scan_Count__c = 1
            ));
        }
        if (!debtItems.isEmpty()) insert debtItems;
    }

    public static Decimal calculateDebtScore(Id environmentId) {
        List<Tech_Debt__c> activeDebts = [
            SELECT Estimated_Hours__c, Priority__c FROM Tech_Debt__c
            WHERE Status__c = 'Active' AND Component__r.Branch__r.Repository__c != null
        ];
        if (activeDebts.isEmpty()) return 100;

        Decimal totalWeightedDebt = 0;
        for (Tech_Debt__c debt : activeDebts) {
            Decimal weight = SEVERITY_WEIGHTS.containsKey(debt.Priority__c) ? SEVERITY_WEIGHTS.get(debt.Priority__c) : 1.0;
            totalWeightedDebt += (debt.Estimated_Hours__c != null ? debt.Estimated_Hours__c : 1) * weight;
        }

        Decimal score = Math.max(0, 100 - totalWeightedDebt);
        return score.setScale(2, RoundingMode.HALF_UP);
    }

    public static Map<String, Object> getDebtSummary() {
        Map<String, Object> summary = new Map<String, Object>();
        summary.put('totalActive', [SELECT COUNT() FROM Tech_Debt__c WHERE Status__c = 'Active']);
        summary.put('totalHours', 0);

        AggregateResult[] results = [
            SELECT SUM(Estimated_Hours__c) totalHours FROM Tech_Debt__c WHERE Status__c = 'Active'
        ];
        if (!results.isEmpty() && results[0].get('totalHours') != null) {
            summary.put('totalHours', results[0].get('totalHours'));
        }

        Map<String, Integer> byPriority = new Map<String, Integer>();
        for (AggregateResult ar : [
            SELECT Priority__c, COUNT(Id) cnt FROM Tech_Debt__c WHERE Status__c = 'Active' GROUP BY Priority__c
        ]) {
            byPriority.put((String)ar.get('Priority__c'), (Integer)ar.get('cnt'));
        }
        summary.put('byPriority', byPriority);

        return summary;
    }

    public static void remediateDebt(Id debtId) {
        SFOpsSecurityUtils.enforceUpdateAccess('Tech_Debt__c');
        update new Tech_Debt__c(Id = debtId, Status__c = 'Remediated');
    }

    public static void writeOffDebt(Id debtId, String justification, Id approverId) {
        SFOpsSecurityUtils.enforceUpdateAccess('Tech_Debt__c');
        update new Tech_Debt__c(
            Id = debtId, Status__c = 'WrittenOff',
            Business_Justification__c = justification, Write_Off_Approver__c = approverId
        );
    }

    private static String mapCategoryToDebtType(String category) {
        Map<String, String> mapping = new Map<String, String>{
            'Security' => 'Security', 'Performance' => 'Performance',
            'BestPractice' => 'Code', 'Maintainability' => 'Code',
            'Compliance' => 'Architecture', 'Accessibility' => 'Config'
        };
        return mapping.containsKey(category) ? mapping.get(category) : 'Code';
    }

    private static String mapSeverityToPriority(String severity) {
        Map<String, String> mapping = new Map<String, String>{
            'Critical' => 'P0', 'High' => 'P1', 'Medium' => 'P2', 'Low' => 'P3'
        };
        return mapping.containsKey(severity) ? mapping.get(severity) : 'P3';
    }

    private static Decimal estimateEffort(String severity) {
        Map<String, Decimal> estimates = new Map<String, Decimal>{
            'Critical' => 8.0, 'High' => 4.0, 'Medium' => 2.0, 'Low' => 1.0
        };
        return estimates.containsKey(severity) ? estimates.get(severity) : 1.0;
    }
}
