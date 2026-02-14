public with sharing class SFOpsAIRuleBuilder {
    public static Rule__c createRuleFromDescription(String ruleDescription, String category, String severity) {
        SFOpsLicenseService.enforceFeature(SFOpsLicenseService.FEATURE_AI_RULE_BUILDER);
        SFOpsSecurityUtils.enforceCreateAccess('Rule__c');
        Agent_Execution__c execution = SFOpsAIAgentService.executeAgent('Quality', ruleDescription, null, null);
        Rule__c rule = new Rule__c(
            Name = 'AI-' + Datetime.now().format('yyyyMMddHHmmss'),
            Category__c = category, Severity__c = severity, Description__c = ruleDescription,
            Detection_Pattern__c = '// AI-generated pattern placeholder',
            Language__c = 'Apex', Is_Active__c = false, Is_Custom__c = true,
            Created_By_AI__c = true, Source__c = 'AIGenerated'
        );
        insert rule;
        return rule;
    }

    public static List<Rule__c> getAIGeneratedRules() {
        SFOpsSecurityUtils.enforceReadAccess('Rule__c');
        return [SELECT Id, Name, Category__c, Severity__c, Description__c, Is_Active__c, CreatedDate
                FROM Rule__c WHERE Created_By_AI__c = true ORDER BY CreatedDate DESC];
    }
}
