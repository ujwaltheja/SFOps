public with sharing class SFOpsDebtTracker {
    public static List<Tech_Debt__c> getActiveDebtItems(Integer limitCount) {
        SFOpsSecurityUtils.enforceReadAccess('Tech_Debt__c');
        return [SELECT Id, Name, Component_Name__c, Debt_Type__c, Estimated_Hours__c, Priority__c,
                       Status__c, Owner__c, Due_Date__c, First_Detected_Date__c, Scan_Count__c
                FROM Tech_Debt__c WHERE Status__c IN ('Active', 'InProgress')
                ORDER BY Priority__c ASC, Estimated_Hours__c DESC LIMIT :limitCount];
    }

    public static List<Tech_Debt__c> getDebtByStatus(String status) {
        SFOpsSecurityUtils.enforceReadAccess('Tech_Debt__c');
        return [SELECT Id, Name, Component_Name__c, Debt_Type__c, Estimated_Hours__c, Priority__c,
                       Status__c, Owner__c, Due_Date__c
                FROM Tech_Debt__c WHERE Status__c = :status ORDER BY Priority__c ASC];
    }

    public static void assignDebtItem(Id debtId, Id ownerId) {
        SFOpsSecurityUtils.enforceUpdateAccess('Tech_Debt__c');
        update new Tech_Debt__c(Id = debtId, Owner__c = ownerId, Status__c = 'InProgress');
    }

    public static void deferDebtItem(Id debtId, Date dueDate) {
        SFOpsSecurityUtils.enforceUpdateAccess('Tech_Debt__c');
        update new Tech_Debt__c(Id = debtId, Status__c = 'Deferred', Due_Date__c = dueDate);
    }

    public static Map<String, Integer> getDebtByType() {
        Map<String, Integer> byType = new Map<String, Integer>();
        for (AggregateResult ar : [
            SELECT Debt_Type__c, COUNT(Id) cnt FROM Tech_Debt__c WHERE Status__c = 'Active' GROUP BY Debt_Type__c
        ]) { byType.put((String)ar.get('Debt_Type__c'), (Integer)ar.get('cnt')); }
        return byType;
    }
}
