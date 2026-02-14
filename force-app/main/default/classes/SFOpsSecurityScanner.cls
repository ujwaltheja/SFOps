public with sharing class SFOpsSecurityScanner {
    public static List<Scan_Issue__c> performSecurityScan(String componentName, String sourceCode, String metadataType) {
        List<Scan_Issue__c> issues = new List<Scan_Issue__c>();
        if (String.isBlank(sourceCode)) return issues;
        if (metadataType == 'ApexClass' || metadataType == 'ApexTrigger') {
            issues.addAll(scanApexSecurity(componentName, sourceCode));
        }
        if (metadataType == 'LightningComponentBundle') {
            issues.addAll(SFOpsLWCAnalyzer.analyzeLWC(componentName, sourceCode));
        }
        return issues;
    }

    private static List<Scan_Issue__c> scanApexSecurity(String componentName, String source) {
        List<Scan_Issue__c> issues = new List<Scan_Issue__c>();
        Integer lineNum = 0;
        for (String line : source.split('\n')) {
            lineNum++;
            String lower = line.toLowerCase().trim();
            if (lower.contains('password') && (lower.contains('=') || lower.contains('\''))) {
                issues.add(createIssue(componentName, lineNum, 'Critical', 'Security',
                    'Potential hardcoded password detected.'));
            }
            if (lower.contains('without sharing')) {
                issues.add(createIssue(componentName, lineNum, 'Medium', 'Security',
                    'Class uses "without sharing". Ensure this is intentional.'));
            }
        }
        return issues;
    }

    private static Scan_Issue__c createIssue(String comp, Integer line, String sev, String cat, String desc) {
        return new Scan_Issue__c(
            Component_Name__c = comp, Line_Number__c = line,
            Severity__c = sev, Category__c = cat, Description__c = desc, Status__c = 'Open'
        );
    }
}
