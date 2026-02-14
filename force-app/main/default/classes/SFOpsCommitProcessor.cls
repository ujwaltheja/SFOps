public class SFOpsCommitProcessor implements Queueable {
    private Id commitId;

    public SFOpsCommitProcessor(Id commitId) {
        this.commitId = commitId;
    }

    public void execute(QueueableContext context) {
        try {
            List<Component__c> components = [
                SELECT Id, XML_Content__c, Hash__c FROM Component__c WHERE Commit__c = :commitId
            ];
            for (Component__c comp : components) {
                if (String.isNotBlank(comp.XML_Content__c) && String.isBlank(comp.Hash__c)) {
                    comp.Hash__c = SFOpsSecurityUtils.generateHash(comp.XML_Content__c);
                    comp.Size_Bytes__c = SFOpsMetadataUtils.calculateSizeBytes(comp.XML_Content__c);
                }
            }
            if (!components.isEmpty()) update components;

            Commit__c commitRec = new Commit__c(Id = commitId, Component_Count__c = components.size());
            update commitRec;
        } catch (Exception e) {
            SFOpsErrorHandler.logError(e, 'SFOpsCommitProcessor');
        }
    }
}
