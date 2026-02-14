public with sharing class SFOpsTestRunner {

    public static Map<String, Object> getTestCoverageInfo(Id environmentId) {
        Map<String, Object> coverage = new Map<String, Object>();
        coverage.put('environmentId', environmentId);
        coverage.put('timestamp', Datetime.now());
        coverage.put('overallCoverage', 0);
        coverage.put('classCount', 0);
        return coverage;
    }

    public static Map<String, Object> runTestsForComponents(List<String> classNames) {
        Map<String, Object> result = new Map<String, Object>();
        result.put('totalTests', 0);
        result.put('passed', 0);
        result.put('failed', 0);
        result.put('classNames', classNames);
        result.put('status', 'Queued');
        return result;
    }

    public static Decimal calculateCoveragePercentage(Integer coveredLines, Integer totalLines) {
        if (totalLines == null || totalLines == 0) return 0;
        return (Decimal.valueOf(coveredLines) / Decimal.valueOf(totalLines) * 100).setScale(2, RoundingMode.HALF_UP);
    }
}
