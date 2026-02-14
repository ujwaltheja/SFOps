public with sharing class SFOpsQualityGateEvaluator {

    public class GateResult {
        @AuraEnabled public Boolean passed;
        @AuraEnabled public String gateName;
        @AuraEnabled public String gateType;
        @AuraEnabled public Decimal actualValue;
        @AuraEnabled public Decimal thresholdValue;
        @AuraEnabled public String operator;
        @AuraEnabled public String message;
        @AuraEnabled public String action;
    }

    public static GateResult evaluateGate(Id qualityGateId, Id scanId) {
        Quality_Gate__c gate = [
            SELECT Id, Name, Type__c, Threshold_Operator__c, Threshold_Value__c, On_Failure__c, Is_Active__c
            FROM Quality_Gate__c WHERE Id = :qualityGateId LIMIT 1
        ];
        if (!gate.Is_Active__c) {
            GateResult result = new GateResult();
            result.passed = true;
            result.gateName = gate.Name;
            result.message = 'Gate is inactive - auto-pass';
            return result;
        }

        Scan__c scan = SFOpsScanEngine.getScan(scanId);
        Decimal actualValue = getMetricValue(gate.Type__c, scan);

        GateResult result = new GateResult();
        result.gateName = gate.Name;
        result.gateType = gate.Type__c;
        result.actualValue = actualValue;
        result.thresholdValue = gate.Threshold_Value__c;
        result.operator = gate.Threshold_Operator__c;
        result.action = gate.On_Failure__c;
        result.passed = evaluateThreshold(actualValue, gate.Threshold_Operator__c, gate.Threshold_Value__c);

        if (!result.passed) {
            result.message = gate.Name + ' failed: actual ' + actualValue + ' ' + gate.Threshold_Operator__c + ' ' + gate.Threshold_Value__c;
        } else {
            result.message = gate.Name + ' passed';
        }

        return result;
    }

    public static List<GateResult> evaluateAllGates(Id pipelineStageId, Id scanId) {
        List<GateResult> results = new List<GateResult>();
        Pipeline_Stage__c stage = [
            SELECT Id, Quality_Gate__c FROM Pipeline_Stage__c WHERE Id = :pipelineStageId LIMIT 1
        ];
        if (stage.Quality_Gate__c != null) {
            results.add(evaluateGate(stage.Quality_Gate__c, scanId));
        }
        return results;
    }

    private static Decimal getMetricValue(String gateType, Scan__c scan) {
        if (gateType == 'CodeQuality') return scan.Quality_Score__c;
        if (gateType == 'Security') return scan.Critical_Count__c;
        if (gateType == 'TechDebt') return scan.Debt_Hours_Added__c;
        return 0;
    }

    private static Boolean evaluateThreshold(Decimal actual, String operator, Decimal threshold) {
        if (actual == null) actual = 0;
        if (threshold == null) threshold = 0;
        if (operator == 'GreaterThanOrEqual') return actual >= threshold;
        if (operator == 'LessThanOrEqual') return actual <= threshold;
        if (operator == 'Equals') return actual == threshold;
        if (operator == 'NotEquals') return actual != threshold;
        if (operator == 'GreaterThan') return actual > threshold;
        if (operator == 'LessThan') return actual < threshold;
        return false;
    }
}
