public class SFOpsScheduledBackup implements Schedulable {
    public void execute(SchedulableContext sc) {
        Setting__c settings = Setting__c.getInstance();
        if (settings == null || !settings.Auto_Backup_Enabled__c) return;
        List<Environment__c> environments = [
            SELECT Id FROM Environment__c WHERE Auth_Status__c = 'Connected' AND Is_Production__c = true
        ];
        for (Environment__c env : environments) {
            SFOpsRollbackService.createSnapshot(env.Id, 'Full', null);
        }
    }
}
