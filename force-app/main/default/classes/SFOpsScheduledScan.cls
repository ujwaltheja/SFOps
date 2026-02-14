public class SFOpsScheduledScan implements Schedulable {
    public void execute(SchedulableContext sc) {
        List<Environment__c> environments = [
            SELECT Id FROM Environment__c WHERE Auth_Status__c = 'Connected' LIMIT 10
        ];
        for (Environment__c env : environments) {
            SFOpsScanEngine.initiateScan('Full', 'Org', env.Id, null);
        }
    }
}
