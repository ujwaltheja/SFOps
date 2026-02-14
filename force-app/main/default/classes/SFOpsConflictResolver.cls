public with sharing class SFOpsConflictResolver {
    public static List<Conflict__c> detectConflicts(Id deploymentId, List<Component__c> sourceComponents, List<Component__c> targetComponents) {
        SFOpsSecurityUtils.enforceCreateAccess('Conflict__c');
        List<Conflict__c> conflicts = new List<Conflict__c>();
        Map<String, Component__c> targetMap = new Map<String, Component__c>();
        for (Component__c comp : targetComponents) {
            targetMap.put(comp.API_Name__c + ':' + comp.Metadata_Type__c, comp);
        }
        for (Component__c source : sourceComponents) {
            String key = source.API_Name__c + ':' + source.Metadata_Type__c;
            Component__c target = targetMap.get(key);
            if (target != null && SFOpsMetadataUtils.hasContentChanged(source.Hash__c, target.Hash__c)) {
                conflicts.add(new Conflict__c(
                    Deployment__c = deploymentId, Component__c = source.Id,
                    Component_Name__c = source.API_Name__c, Metadata_Type__c = source.Metadata_Type__c,
                    Source_Value__c = source.XML_Content__c, Target_Value__c = target.XML_Content__c,
                    Resolution_Status__c = 'Open'
                ));
            }
        }
        if (!conflicts.isEmpty()) insert conflicts;
        return conflicts;
    }

    public static Conflict__c resolveConflict(Id conflictId, String resolution) {
        SFOpsSecurityUtils.enforceUpdateAccess('Conflict__c');
        Conflict__c conflict = new Conflict__c(
            Id = conflictId, Resolution_Status__c = resolution,
            Resolved_By__c = UserInfo.getName(), Resolution_Date__c = Datetime.now()
        );
        update conflict;
        return conflict;
    }

    public static List<Conflict__c> getConflicts(Id deploymentId) {
        SFOpsSecurityUtils.enforceReadAccess('Conflict__c');
        return [SELECT Id, Name, Component_Name__c, Metadata_Type__c, Source_Value__c, Target_Value__c,
                       Resolution_Status__c, AI_Suggestion__c, Confidence_Score__c, Resolved_By__c
                FROM Conflict__c WHERE Deployment__c = :deploymentId ORDER BY Component_Name__c ASC];
    }

    public static Integer getUnresolvedCount(Id deploymentId) {
        return [SELECT COUNT() FROM Conflict__c WHERE Deployment__c = :deploymentId AND Resolution_Status__c = 'Open'];
    }
}
