public with sharing class SFOpsLWCAnalyzer {
    public static List<Scan_Issue__c> analyzeLWC(String componentName, String sourceCode) {
        List<Scan_Issue__c> issues = new List<Scan_Issue__c>();
        if (String.isBlank(sourceCode)) return issues;
        Integer lineNum = 0;
        for (String line : sourceCode.split('\n')) {
            lineNum++;
            String trimmed = line.trim().toLowerCase();
            if (trimmed.contains('console.log')) {
                issues.add(createIssue(componentName, lineNum, 'Low', 'BestPractice',
                    'console.log found. Remove for production.', 'Remove console.log.'));
            }
            if (trimmed.contains('innerhtml')) {
                issues.add(createIssue(componentName, lineNum, 'High', 'Security',
                    'innerHTML usage detected. XSS risk.', 'Use template binding instead.'));
            }
            if (trimmed.contains('eval(')) {
                issues.add(createIssue(componentName, lineNum, 'Critical', 'Security',
                    'eval() usage detected. Critical security risk.', 'Remove eval().'));
            }
        }
        return issues;
    }

    private static Scan_Issue__c createIssue(String comp, Integer line, String sev, String cat, String desc, String fix) {
        return new Scan_Issue__c(
            Component_Name__c = comp, Line_Number__c = line,
            Severity__c = sev, Category__c = cat,
            Description__c = desc, AI_Fix_Suggestion__c = fix, Status__c = 'Open'
        );
    }
}
