public with sharing class SFOpsVersionControlService {

    public static Repository__c createRepository(String name, String branchStrategy, String defaultBranch) {
        SFOpsSecurityUtils.enforceCreateAccess('Repository__c');
        Repository__c repo = new Repository__c(
            Name = name,
            Branch_Strategy__c = branchStrategy,
            Default_Branch__c = String.isNotBlank(defaultBranch) ? defaultBranch : 'main',
            Total_Branches__c = 0,
            Total_Commits__c = 0,
            Storage_Used__c = 0
        );
        insert repo;
        createBranch(repo.Id, repo.Default_Branch__c, 'Main', null);
        return repo;
    }

    public static Branch__c createBranch(Id repositoryId, String branchName, String branchType, String sourceBranch) {
        SFOpsSecurityUtils.enforceCreateAccess('Branch__c');
        Branch__c branch = new Branch__c(
            Name = branchName,
            Repository__c = repositoryId,
            Type__c = branchType,
            Source_Branch__c = sourceBranch,
            Status__c = 'Active',
            Merge_Status__c = 'NotMerged',
            Conflict_Count__c = 0,
            Created_By_User__c = UserInfo.getName()
        );
        insert branch;

        Repository__c repo = new Repository__c(Id = repositoryId);
        repo.Total_Branches__c = [SELECT COUNT() FROM Branch__c WHERE Repository__c = :repositoryId];
        update repo;

        return branch;
    }

    public static Commit__c createCommit(Id branchId, String message, List<Component__c> components) {
        SFOpsSecurityUtils.enforceCreateAccess('Commit__c');
        Commit__c commitRec = new Commit__c(
            Branch__c = branchId,
            Message__c = message,
            Author__c = UserInfo.getName(),
            Commit_Timestamp__c = Datetime.now(),
            Component_Count__c = components != null ? components.size() : 0,
            Hash__c = SFOpsSecurityUtils.generateHash(message + Datetime.now().getTime()),
            Is_Deployed__c = false,
            Deployment_Status__c = 'NotDeployed'
        );
        insert commitRec;

        if (components != null && !components.isEmpty()) {
            for (Component__c comp : components) {
                comp.Commit__c = commitRec.Id;
                comp.Branch__c = branchId;
            }
            upsert components;
        }

        Branch__c branch = [SELECT Repository__c FROM Branch__c WHERE Id = :branchId LIMIT 1];
        Repository__c repo = new Repository__c(Id = branch.Repository__c);
        repo.Total_Commits__c = [SELECT COUNT() FROM Commit__c WHERE Branch__c IN (SELECT Id FROM Branch__c WHERE Repository__c = :branch.Repository__c)];
        repo.Last_Commit_Date__c = Datetime.now();
        update repo;

        return commitRec;
    }

    public static List<Branch__c> getBranches(Id repositoryId) {
        SFOpsSecurityUtils.enforceReadAccess('Branch__c');
        return [
            SELECT Id, Name, Type__c, Source_Branch__c, Status__c, Merge_Status__c,
                   Conflict_Count__c, Created_By_User__c, CreatedDate
            FROM Branch__c WHERE Repository__c = :repositoryId ORDER BY CreatedDate DESC
        ];
    }

    public static List<Commit__c> getCommits(Id branchId, Integer limitCount) {
        SFOpsSecurityUtils.enforceReadAccess('Commit__c');
        return [
            SELECT Id, Name, Message__c, Author__c, Commit_Timestamp__c, Component_Count__c,
                   Hash__c, Is_Deployed__c, Deployment_Status__c
            FROM Commit__c WHERE Branch__c = :branchId
            ORDER BY Commit_Timestamp__c DESC LIMIT :limitCount
        ];
    }

    public static List<Component__c> getCommitComponents(Id commitId) {
        SFOpsSecurityUtils.enforceReadAccess('Component__c');
        return [
            SELECT Id, Name, API_Name__c, Metadata_Type__c, Version__c, Hash__c, Size_Bytes__c, Is_Deleted__c
            FROM Component__c WHERE Commit__c = :commitId
        ];
    }

    public static Branch__c mergeBranch(Id sourceBranchId, Id targetBranchId) {
        SFOpsSecurityUtils.enforceUpdateAccess('Branch__c');
        Branch__c source = [SELECT Id, Name, Status__c FROM Branch__c WHERE Id = :sourceBranchId LIMIT 1];
        source.Status__c = 'Merged';
        source.Merge_Status__c = 'Merged';
        update source;
        return source;
    }

    public static void archiveBranch(Id branchId) {
        SFOpsSecurityUtils.enforceUpdateAccess('Branch__c');
        update new Branch__c(Id = branchId, Status__c = 'Archived');
    }
}
