public with sharing class SFOpsDashboardController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardData() {
        Map<String, Object> data = new Map<String, Object>();
        data.put('deploymentStats', SFOpsDeploymentEngine.getDeploymentStats());
        data.put('environmentCount', [SELECT COUNT() FROM Environment__c]);
        data.put('pipelineCount', [SELECT COUNT() FROM Pipeline__c WHERE Status__c = 'Active']);
        data.put('openIssues', [SELECT COUNT() FROM Scan_Issue__c WHERE Status__c = 'Open']);
        data.put('activeDebt', [SELECT COUNT() FROM Tech_Debt__c WHERE Status__c = 'Active']);
        data.put('recentScans', SFOpsScanEngine.getRecentScans(5));
        data.put('licenseInfo', SFOpsLicenseService.getLicenseInfo());
        data.put('unreadNotifications', SFOpsNotificationService.getUnreadCount());
        return data;
    }

    @AuraEnabled(cacheable=true)
    public static List<Deployment__c> getRecentDeployments() {
        return SFOpsDeploymentEngine.getDeploymentHistory(null, 10);
    }

    @AuraEnabled(cacheable=true)
    public static List<Scan__c> getRecentScans() {
        return SFOpsScanEngine.getRecentScans(10);
    }

    @AuraEnabled(cacheable=true)
    public static List<Notification__c> getNotifications() {
        return SFOpsNotificationService.getUnreadNotifications(20);
    }

    @AuraEnabled
    public static void markNotificationRead(Id notificationId) {
        SFOpsNotificationService.markAsRead(notificationId);
    }
}
