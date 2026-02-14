public with sharing class SFOpsRepositoryController {
    @AuraEnabled(cacheable=true)
    public static List<Repository__c> getRepositories() {
        SFOpsSecurityUtils.enforceReadAccess('Repository__c');
        return [SELECT Id, Name, Branch_Strategy__c, Default_Branch__c, Total_Branches__c, Total_Commits__c, Last_Commit_Date__c FROM Repository__c ORDER BY Name ASC];
    }

    @AuraEnabled
    public static Repository__c createRepository(String name, String branchStrategy, String defaultBranch) {
        try {
            return SFOpsVersionControlService.createRepository(name, branchStrategy, defaultBranch);
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'createRepository'));
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Branch__c> getBranches(Id repositoryId) {
        return SFOpsVersionControlService.getBranches(repositoryId);
    }

    @AuraEnabled(cacheable=true)
    public static List<Commit__c> getCommits(Id branchId, Integer limitCount) {
        return SFOpsVersionControlService.getCommits(branchId, limitCount != null ? limitCount : 50);
    }

    @AuraEnabled
    public static Branch__c createBranch(Id repositoryId, String branchName, String branchType, String sourceBranch) {
        try {
            return SFOpsVersionControlService.createBranch(repositoryId, branchName, branchType, sourceBranch);
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'createBranch'));
        }
    }

    @AuraEnabled
    public static Commit__c createCommit(Id branchId, String message) {
        try {
            return SFOpsVersionControlService.createCommit(branchId, message, new List<Component__c>());
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'createCommit'));
        }
    }
}
