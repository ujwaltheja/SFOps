public with sharing class SFOpsApexAnalyzer {

    public static List<Scan_Issue__c> analyzeApexClass(String className, String sourceCode) {
        List<Scan_Issue__c> issues = new List<Scan_Issue__c>();
        if (String.isBlank(sourceCode)) return issues;

        checkSOQLInLoops(className, sourceCode, issues);
        checkDMLInLoops(className, sourceCode, issues);
        checkHardcodedIds(className, sourceCode, issues);
        checkMissingBulkification(className, sourceCode, issues);
        checkSecurityVulnerabilities(className, sourceCode, issues);
        checkCRUDFLS(className, sourceCode, issues);
        checkBestPractices(className, sourceCode, issues);

        return issues;
    }

    private static void checkSOQLInLoops(String className, String source, List<Scan_Issue__c> issues) {
        String lowerSource = source.toLowerCase();
        Boolean inLoop = false;
        Integer lineNum = 0;
        for (String line : source.split('\n')) {
            lineNum++;
            String lowerLine = line.toLowerCase().trim();
            if (lowerLine.contains('for (') || lowerLine.contains('for(') || lowerLine.contains('while (') || lowerLine.contains('while(')) {
                inLoop = true;
            }
            if (inLoop && (lowerLine.contains('[select ') || lowerLine.contains('database.query'))) {
                issues.add(createIssue(className, lineNum, 'Critical', 'Performance',
                    'SOQL query inside loop detected. Move query outside loop to avoid governor limits.',
                    'Move the SOQL query before the loop and use a Map or Set for filtering.'));
            }
        }
    }

    private static void checkDMLInLoops(String className, String source, List<Scan_Issue__c> issues) {
        Integer lineNum = 0;
        Boolean inLoop = false;
        for (String line : source.split('\n')) {
            lineNum++;
            String trimmed = line.trim().toLowerCase();
            if (trimmed.contains('for (') || trimmed.contains('for(') || trimmed.contains('while (')) inLoop = true;
            if (inLoop && (trimmed.startsWith('insert ') || trimmed.startsWith('update ') || trimmed.startsWith('delete ') || trimmed.startsWith('upsert '))) {
                issues.add(createIssue(className, lineNum, 'Critical', 'Performance',
                    'DML statement inside loop detected. Collect records and perform DML outside loop.',
                    'Add records to a List and perform bulk DML after the loop.'));
            }
        }
    }

    private static void checkHardcodedIds(String className, String source, List<Scan_Issue__c> issues) {
        Integer lineNum = 0;
        Pattern idPattern = Pattern.compile('[\'"][a-zA-Z0-9]{15,18}[\'"]');
        for (String line : source.split('\n')) {
            lineNum++;
            Matcher m = idPattern.matcher(line);
            if (m.find() && !line.trim().startsWith('//') && !line.trim().startsWith('*')) {
                String match = m.group();
                try {
                    Id.valueOf(match.substring(1, match.length()-1));
                    issues.add(createIssue(className, lineNum, 'High', 'Maintainability',
                        'Hardcoded Salesforce ID detected. Use Custom Labels, Custom Metadata, or queries instead.',
                        'Replace hardcoded ID with a Custom Label or dynamic query.'));
                } catch (Exception e) { /* Not an ID */ }
            }
        }
    }

    private static void checkMissingBulkification(String className, String source, List<Scan_Issue__c> issues) {
        if (source.toLowerCase().contains('trigger ') && !source.toLowerCase().contains('list<') && !source.toLowerCase().contains('for (')) {
            issues.add(createIssue(className, 1, 'High', 'Performance',
                'Trigger may not be bulkified. Ensure trigger handles collections of records.',
                'Process Trigger.new as a collection, not individual records.'));
        }
    }

    private static void checkSecurityVulnerabilities(String className, String source, List<Scan_Issue__c> issues) {
        Integer lineNum = 0;
        for (String line : source.split('\n')) {
            lineNum++;
            String trimmed = line.trim().toLowerCase();
            if (trimmed.contains('string.format') && trimmed.contains('select') && (trimmed.contains('+') || trimmed.contains('concatenat'))) {
                issues.add(createIssue(className, lineNum, 'Critical', 'Security',
                    'Potential SOQL injection vulnerability. Use bind variables instead of string concatenation.',
                    'Use bind variables (:variableName) in SOQL queries instead of string concatenation.'));
            }
        }
    }

    private static void checkCRUDFLS(String className, String source, List<Scan_Issue__c> issues) {
        if (!source.contains('with sharing') && !source.contains('without sharing') && !source.contains('inherited sharing')) {
            issues.add(createIssue(className, 1, 'High', 'Security',
                'Class does not specify sharing model. Add "with sharing" keyword.',
                'Add "with sharing" to the class declaration to enforce record-level security.'));
        }
        if (source.contains('[SELECT') && !source.contains('WITH SECURITY_ENFORCED') && !source.contains('stripInaccessible') && !source.contains('isAccessible')) {
            issues.add(createIssue(className, 1, 'Medium', 'Security',
                'SOQL queries may not enforce FLS. Consider using WITH SECURITY_ENFORCED or Security.stripInaccessible().',
                'Add WITH SECURITY_ENFORCED to SOQL queries or use Security.stripInaccessible().'));
        }
    }

    private static void checkBestPractices(String className, String source, List<Scan_Issue__c> issues) {
        Integer lineNum = 0;
        for (String line : source.split('\n')) {
            lineNum++;
            if (line.trim().toLowerCase().startsWith('system.debug') && !line.trim().startsWith('//')) {
                issues.add(createIssue(className, lineNum, 'Low', 'BestPractice',
                    'System.debug statement found. Remove or use proper logging framework for production.',
                    'Remove System.debug or replace with a structured logging utility.'));
            }
        }
    }

    private static Scan_Issue__c createIssue(String componentName, Integer lineNumber, String severity, String category, String description, String fixSuggestion) {
        return new Scan_Issue__c(
            Component_Name__c = componentName,
            Line_Number__c = lineNumber,
            Severity__c = severity,
            Category__c = category,
            Description__c = description,
            AI_Fix_Suggestion__c = fixSuggestion,
            Status__c = 'Open'
        );
    }
}
