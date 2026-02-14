public with sharing class SFOpsComplianceController {
    @AuraEnabled
    public static Compliance_Report__c generateReport(String reportType, Date periodStart, Date periodEnd) {
        try {
            return SFOpsComplianceEngine.generateReport(reportType, periodStart, periodEnd);
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'generateReport'));
        }
    }

    @AuraEnabled(cacheable=true)
    public static Compliance_Report__c getReport(Id reportId) {
        return SFOpsComplianceEngine.getReport(reportId);
    }

    @AuraEnabled(cacheable=true)
    public static List<Compliance_Report__c> getReports(Integer limitCount) {
        return SFOpsComplianceEngine.getReports(limitCount != null ? limitCount : 20);
    }

    @AuraEnabled
    public static void finalizeReport(Id reportId) {
        try {
            SFOpsComplianceEngine.finalizeReport(reportId);
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'finalizeReport'));
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Operational_Alert__c> getAlerts(Id environmentId, Integer limitCount) {
        return SFOpsDriftMonitor.getAlerts(environmentId, limitCount != null ? limitCount : 50);
    }

    @AuraEnabled
    public static void acknowledgeAlert(Id alertId) {
        try {
            SFOpsDriftMonitor.acknowledgeAlert(alertId);
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'acknowledgeAlert'));
        }
    }

    @AuraEnabled
    public static void resolveAlert(Id alertId, String notes) {
        try {
            SFOpsDriftMonitor.resolveAlert(alertId, notes);
        } catch (Exception e) {
            throw new AuraHandledException(SFOpsErrorHandler.handleError(e, 'resolveAlert'));
        }
    }
}
