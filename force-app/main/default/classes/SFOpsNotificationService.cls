public with sharing class SFOpsNotificationService {
    public static final String TYPE_DEPLOYMENT = 'Deployment';
    public static final String TYPE_SCAN = 'Scan';
    public static final String TYPE_ALERT = 'Alert';
    public static final String TYPE_REVIEW = 'Review';
    public static final String TYPE_APPROVAL = 'Approval';
    public static final String TYPE_SYSTEM = 'System';
    public static final String TYPE_AI = 'AI';

    public static final String PRIORITY_HIGH = 'High';
    public static final String PRIORITY_MEDIUM = 'Medium';
    public static final String PRIORITY_LOW = 'Low';

    public static Notification__c sendNotification(Id recipientId, String notificationType, String message, String priority) {
        return sendNotification(recipientId, notificationType, message, priority, null);
    }

    public static Notification__c sendNotification(Id recipientId, String notificationType, String message, String priority, String actionUrl) {
        Notification__c notification = new Notification__c(
            Recipient__c = recipientId,
            Type__c = notificationType,
            Message__c = message,
            Priority__c = priority,
            Read_Status__c = false,
            Action_URL__c = actionUrl
        );
        insert notification;
        return notification;
    }

    public static List<Notification__c> sendBulkNotifications(List<Id> recipientIds, String notificationType, String message, String priority) {
        List<Notification__c> notifications = new List<Notification__c>();
        for (Id recipientId : recipientIds) {
            notifications.add(new Notification__c(
                Recipient__c = recipientId, Type__c = notificationType,
                Message__c = message, Priority__c = priority, Read_Status__c = false
            ));
        }
        if (!notifications.isEmpty()) insert notifications;
        return notifications;
    }

    public static void notifyDeploymentStatus(Id deploymentId, String status, List<Id> recipientIds) {
        String message = status == 'Success' ? 'Deployment completed successfully' : 'Deployment failed';
        String priority = status == 'Failed' ? PRIORITY_HIGH : PRIORITY_MEDIUM;
        String actionUrl = '/lightning/r/Deployment__c/' + deploymentId + '/view';
        for (Id recipientId : recipientIds) {
            sendNotification(recipientId, TYPE_DEPLOYMENT, message, priority, actionUrl);
        }
    }

    public static void notifyScanComplete(Id scanId, Integer issueCount, List<Id> recipientIds) {
        String message = 'Scan completed - ' + issueCount + ' issues found.';
        String priority = issueCount > 0 ? PRIORITY_MEDIUM : PRIORITY_LOW;
        for (Id recipientId : recipientIds) {
            sendNotification(recipientId, TYPE_SCAN, message, priority);
        }
    }

    public static void markAsRead(Id notificationId) {
        update new Notification__c(Id = notificationId, Read_Status__c = true);
    }

    public static void markAllAsRead(Id userId) {
        List<Notification__c> unread = [SELECT Id FROM Notification__c WHERE Recipient__c = :userId AND Read_Status__c = false];
        for (Notification__c n : unread) n.Read_Status__c = true;
        if (!unread.isEmpty()) update unread;
    }

    public static List<Notification__c> getUnreadNotifications(Integer limitCount) {
        return [SELECT Id, Type__c, Message__c, Priority__c, Action_URL__c, CreatedDate
                FROM Notification__c WHERE Recipient__c = :UserInfo.getUserId() AND Read_Status__c = false
                ORDER BY CreatedDate DESC LIMIT :limitCount];
    }

    public static Integer getUnreadCount() {
        return [SELECT COUNT() FROM Notification__c WHERE Recipient__c = :UserInfo.getUserId() AND Read_Status__c = false];
    }

    public static void sendEmailNotification(String toAddress, String subject, String body) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ toAddress });
        email.setSubject('[SFOps] ' + subject);
        email.setPlainTextBody(body);
        email.setSaveAsActivity(false);
        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        } catch (Exception e) {
            SFOpsErrorHandler.logError(e, 'Email notification failed');
        }
    }
}
