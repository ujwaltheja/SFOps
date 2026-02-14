public with sharing class SFOpsSecurityUtils {
    public class SecurityException extends Exception {}

    public static Boolean hasReadAccess(String objectName) {
        Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectName)?.getDescribe();
        return objDescribe != null && objDescribe.isAccessible();
    }

    public static Boolean hasCreateAccess(String objectName) {
        Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectName)?.getDescribe();
        return objDescribe != null && objDescribe.isCreateable();
    }

    public static Boolean hasUpdateAccess(String objectName) {
        Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectName)?.getDescribe();
        return objDescribe != null && objDescribe.isUpdateable();
    }

    public static Boolean hasDeleteAccess(String objectName) {
        Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objectName)?.getDescribe();
        return objDescribe != null && objDescribe.isDeletable();
    }

    public static void enforceReadAccess(String objectName) {
        if (!hasReadAccess(objectName)) {
            throw new SecurityException('Insufficient read access to ' + objectName);
        }
    }

    public static void enforceCreateAccess(String objectName) {
        if (!hasCreateAccess(objectName)) {
            throw new SecurityException('Insufficient create access to ' + objectName);
        }
    }

    public static void enforceUpdateAccess(String objectName) {
        if (!hasUpdateAccess(objectName)) {
            throw new SecurityException('Insufficient update access to ' + objectName);
        }
    }

    public static void enforceDeleteAccess(String objectName) {
        if (!hasDeleteAccess(objectName)) {
            throw new SecurityException('Insufficient delete access to ' + objectName);
        }
    }

    public static Boolean isFieldAccessible(String objectName, String fieldName) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(objectName);
        if (sot == null) return false;
        Schema.SObjectField field = sot.getDescribe().fields.getMap().get(fieldName);
        return field != null && field.getDescribe().isAccessible();
    }

    public static List<SObject> stripInaccessibleFields(List<SObject> records, System.AccessType accessType) {
        if (records == null || records.isEmpty()) return records;
        SObjectAccessDecision decision = Security.stripInaccessible(accessType, records);
        return decision.getRecords();
    }

    public static SObject stripInaccessibleFields(SObject record, System.AccessType accessType) {
        if (record == null) return null;
        List<SObject> stripped = stripInaccessibleFields(new List<SObject>{ record }, accessType);
        return stripped.isEmpty() ? null : stripped[0];
    }

    public static String generateHash(String content) {
        if (String.isBlank(content)) return '';
        Blob contentBlob = Blob.valueOf(content);
        Blob hashBlob = Crypto.generateDigest('SHA-256', contentBlob);
        return EncodingUtil.convertToHex(hashBlob);
    }

    public static String generateUUID() {
        Blob b = Crypto.generateAesKey(128);
        String h = EncodingUtil.convertToHex(b);
        return h.substring(0,8) + '-' + h.substring(8,12) + '-4' +
               h.substring(13,16) + '-' + h.substring(16,20) + '-' + h.substring(20,32);
    }

    public static Boolean isValidSalesforceId(String idStr) {
        if (String.isBlank(idStr)) return false;
        if (idStr.length() != 15 && idStr.length() != 18) return false;
        try {
            Id testId = Id.valueOf(idStr);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public static String sanitizeForSOQL(String input) {
        if (String.isBlank(input)) return '';
        return String.escapeSingleQuotes(input.trim());
    }
}
