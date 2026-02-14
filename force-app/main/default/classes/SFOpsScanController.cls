public with sharing class SFOpsScanController {
    @AuraEnabled
    public static Scan__c initiateScan(String scanType, String target, Id environmentId, Id branchId) {
        try {
            return SFOpsScanEngine.initiateScan(scanType, target, environmentId, branchId);
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'initiateScan'));
        }
    }

    @AuraEnabled(cacheable=true)
    public static Scan__c getScan(Id scanId) {
        return SFOpsScanEngine.getScan(scanId);
    }

    @AuraEnabled(cacheable=true)
    public static List<Scan__c> getRecentScans(Integer limitCount) {
        return SFOpsScanEngine.getRecentScans(limitCount != null ? limitCount : 20);
    }

    @AuraEnabled(cacheable=true)
    public static List<Scan_Issue__c> getScanIssues(Id scanId) {
        return SFOpsScanEngine.getScanIssues(scanId);
    }

    @AuraEnabled
    public static void updateIssueStatus(Id issueId, String status) {
        try {
            SFOpsSecurityUtils.enforceUpdateAccess('Scan_Issue__c');
            update new Scan_Issue__c(Id = issueId, Status__c = status);
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'updateIssueStatus'));
        }
    }
}
