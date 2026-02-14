public with sharing class SFOpsConfigAnalyzer {
    public static List<Scan_Issue__c> analyzeConfig(String componentName, String xmlContent) {
        List<Scan_Issue__c> issues = new List<Scan_Issue__c>();
        if (String.isBlank(xmlContent)) return issues;
        if (xmlContent.contains('<WorkflowRule') && xmlContent.contains('<active>true</active>')) {
            issues.add(new Scan_Issue__c(
                Component_Name__c = componentName, Severity__c = 'Medium', Category__c = 'Maintainability',
                Description__c = 'Active Workflow Rule detected. Consider migrating to Flow.',
                AI_Fix_Suggestion__c = 'Migrate this Workflow Rule to a Flow.', Status__c = 'Open', Line_Number__c = 1
            ));
        }
        if (xmlContent.contains('<ProcessDefinition') && xmlContent.contains('<isActive>true</isActive>')) {
            issues.add(new Scan_Issue__c(
                Component_Name__c = componentName, Severity__c = 'Medium', Category__c = 'Maintainability',
                Description__c = 'Active Process Builder detected. Migrate to Flow.',
                AI_Fix_Suggestion__c = 'Use Migrate to Flow tool.', Status__c = 'Open', Line_Number__c = 1
            ));
        }
        return issues;
    }
}
