public with sharing class SFOpsDebtController {
    @AuraEnabled(cacheable=true)
    public static List<Tech_Debt__c> getActiveDebtItems(Integer limitCount) {
        return SFOpsDebtTracker.getActiveDebtItems(limitCount != null ? limitCount : 100);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDebtSummary() {
        return SFOpsDebtCalculator.getDebtSummary();
    }

    @AuraEnabled
    public static void remediateDebt(Id debtId) {
        try {
            SFOpsDebtCalculator.remediateDebt(debtId);
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'remediateDebt'));
        }
    }

    @AuraEnabled
    public static void writeOffDebt(Id debtId, String justification) {
        try {
            SFOpsDebtCalculator.writeOffDebt(debtId, justification, UserInfo.getUserId());
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'writeOffDebt'));
        }
    }

    @AuraEnabled
    public static void assignDebt(Id debtId, Id ownerId) {
        try {
            SFOpsDebtTracker.assignDebtItem(debtId, ownerId);
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'assignDebt'));
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getDebtByType() {
        return SFOpsDebtTracker.getDebtByType();
    }
}
