public with sharing class SFOpsGateOverrideService {
    public static Map<String, Object> requestOverride(Id deploymentId, Id qualityGateId, String justification) {
        SFOpsAuditService.logEvent(SFOpsAuditService.ACTION_OVERRIDE,
            'Gate override requested for deployment ' + deploymentId + '. Justification: ' + justification,
            SFOpsAuditService.STATUS_WARNING, null, deploymentId, null);
        return new Map<String, Object>{
            'status' => 'Requested', 'deploymentId' => deploymentId,
            'requestedBy' => UserInfo.getName(), 'timestamp' => Datetime.now()
        };
    }

    public static Map<String, Object> approveOverride(Id deploymentId, Id qualityGateId, String approverNotes) {
        SFOpsAuditService.logEvent(SFOpsAuditService.ACTION_OVERRIDE,
            'Gate override approved for deployment ' + deploymentId + '. Notes: ' + approverNotes,
            SFOpsAuditService.STATUS_SUCCESS, null, deploymentId, null);
        return new Map<String, Object>{
            'status' => 'Approved', 'approvedBy' => UserInfo.getName(), 'timestamp' => Datetime.now()
        };
    }
}
