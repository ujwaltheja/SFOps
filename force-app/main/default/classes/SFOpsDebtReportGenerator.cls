public with sharing class SFOpsDebtReportGenerator {
    public static String generateDebtReport() {
        Map<String, Object> summary = SFOpsDebtCalculator.getDebtSummary();
        List<Tech_Debt__c> items = SFOpsDebtTracker.getActiveDebtItems(100);
        String report = 'SFOps Enterprise - Technical Debt Report\n';
        report += 'Generated: ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss') + '\n---\n';
        report += 'Total Active Items: ' + summary.get('totalActive') + '\n';
        report += 'Total Estimated Hours: ' + summary.get('totalHours') + '\n\n';
        for (Tech_Debt__c item : items) {
            report += item.Priority__c + ' | ' + item.Component_Name__c + ' | ' +
                      item.Debt_Type__c + ' | ' + item.Estimated_Hours__c + 'h\n';
        }
        return report;
    }
}
