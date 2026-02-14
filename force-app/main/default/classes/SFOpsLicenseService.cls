public with sharing class SFOpsLicenseService {
    public static final String PLAN_STARTER = 'Starter';
    public static final String PLAN_PROFESSIONAL = 'Professional';
    public static final String PLAN_ENTERPRISE = 'Enterprise';
    public static final String PLAN_TRIAL = 'Trial';
    public static final String PLAN_INTERNAL = 'Internal';

    public static final String FEATURE_AI_AGENTS = 'AI_AGENTS';
    public static final String FEATURE_CUSTOM_RULES = 'CUSTOM_RULES';
    public static final String FEATURE_AI_RULE_BUILDER = 'AI_RULE_BUILDER';
    public static final String FEATURE_COMPLIANCE_TEMPLATES = 'COMPLIANCE_TEMPLATES';
    public static final String FEATURE_DRIFT_DETECTION = 'DRIFT_DETECTION';
    public static final String FEATURE_UNLIMITED_PIPELINES = 'UNLIMITED_PIPELINES';
    public static final String FEATURE_UNLIMITED_ENVS = 'UNLIMITED_ENVIRONMENTS';

    private static License__c cachedLicense;

    public static License__c getCurrentLicense() {
        if (cachedLicense != null) return cachedLicense;
        String orgId = UserInfo.getOrganizationId();
        List<License__c> licenses = [
            SELECT Id, Customer_Org_Id__c, Plan__c, User_Limit__c, Expiry_Date__c,
                   Is_Trial__c, Features_Enabled__c, Last_Check_Date__c, Is_Active__c
            FROM License__c WHERE Customer_Org_Id__c = :orgId AND Is_Active__c = true
            ORDER BY Expiry_Date__c DESC LIMIT 1
        ];
        cachedLicense = licenses.isEmpty() ? null : licenses[0];
        return cachedLicense;
    }

    public static Boolean isLicenseValid() {
        License__c license = getCurrentLicense();
        if (license == null) return false;
        if (!license.Is_Active__c) return false;
        if (license.Expiry_Date__c != null && license.Expiry_Date__c < Date.today()) return false;
        return true;
    }

    public static String getCurrentPlan() {
        License__c license = getCurrentLicense();
        return license != null ? license.Plan__c : null;
    }

    public static Boolean isFeatureEnabled(String featureName) {
        License__c license = getCurrentLicense();
        if (license == null) return false;
        if (license.Plan__c == PLAN_INTERNAL) return true;
        if (String.isNotBlank(license.Features_Enabled__c)) {
            return license.Features_Enabled__c.contains(featureName);
        }
        return isFeatureInPlan(featureName, license.Plan__c);
    }

    public static Boolean isFeatureInPlan(String featureName, String plan) {
        Map<String, Set<String>> planFeatures = new Map<String, Set<String>>{
            PLAN_STARTER => new Set<String>(),
            PLAN_PROFESSIONAL => new Set<String>{ FEATURE_AI_AGENTS, FEATURE_CUSTOM_RULES, FEATURE_COMPLIANCE_TEMPLATES, FEATURE_DRIFT_DETECTION },
            PLAN_ENTERPRISE => new Set<String>{ FEATURE_AI_AGENTS, FEATURE_CUSTOM_RULES, FEATURE_AI_RULE_BUILDER, FEATURE_COMPLIANCE_TEMPLATES, FEATURE_DRIFT_DETECTION, FEATURE_UNLIMITED_PIPELINES, FEATURE_UNLIMITED_ENVS },
            PLAN_TRIAL => new Set<String>{ FEATURE_AI_AGENTS, FEATURE_CUSTOM_RULES, FEATURE_AI_RULE_BUILDER, FEATURE_COMPLIANCE_TEMPLATES, FEATURE_DRIFT_DETECTION, FEATURE_UNLIMITED_PIPELINES, FEATURE_UNLIMITED_ENVS }
        };
        Set<String> features = planFeatures.get(plan);
        return features != null && features.contains(featureName);
    }

    public static Integer getMaxEnvironments() {
        String plan = getCurrentPlan();
        if (plan == PLAN_STARTER) return 3;
        if (plan == PLAN_PROFESSIONAL) return 10;
        return 999;
    }

    public static Integer getMaxPipelines() {
        String plan = getCurrentPlan();
        if (plan == PLAN_STARTER) return 1;
        if (plan == PLAN_PROFESSIONAL) return 5;
        return 999;
    }

    public static void enforceFeature(String featureName) {
        if (!isLicenseValid()) {
            throw new SFOpsErrorHandler.LicenseException('License has expired');
        }
        if (!isFeatureEnabled(featureName)) {
            throw new SFOpsErrorHandler.LicenseException('This feature requires a higher plan. Current: ' + getCurrentPlan());
        }
    }

    public static void enforceEnvironmentLimit() {
        Integer maxEnvs = getMaxEnvironments();
        Integer currentCount = [SELECT COUNT() FROM Environment__c];
        if (currentCount >= maxEnvs) {
            throw new SFOpsErrorHandler.LicenseException('Environment limit reached (' + maxEnvs + '). Please upgrade.');
        }
    }

    public static void enforcePipelineLimit() {
        Integer maxPipelines = getMaxPipelines();
        Integer currentCount = [SELECT COUNT() FROM Pipeline__c WHERE Status__c != 'Archived'];
        if (currentCount >= maxPipelines) {
            throw new SFOpsErrorHandler.LicenseException('Pipeline limit reached (' + maxPipelines + '). Please upgrade.');
        }
    }

    public static Map<String, Object> getLicenseInfo() {
        License__c license = getCurrentLicense();
        Map<String, Object> info = new Map<String, Object>();
        if (license == null) {
            info.put('isValid', false);
            info.put('plan', 'None');
            return info;
        }
        info.put('isValid', isLicenseValid());
        info.put('plan', license.Plan__c);
        info.put('isTrial', license.Is_Trial__c);
        info.put('expiryDate', license.Expiry_Date__c);
        info.put('userLimit', license.User_Limit__c);
        info.put('maxEnvironments', getMaxEnvironments());
        info.put('maxPipelines', getMaxPipelines());
        return info;
    }

    @TestVisible
    private static void clearCache() {
        cachedLicense = null;
    }
}
