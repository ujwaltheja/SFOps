public with sharing class SFOpsErrorHandler {
    public class SFOpsException extends Exception {}
    public class ConfigurationException extends Exception {}
    public class DeploymentException extends Exception {}
    public class ScanException extends Exception {}
    public class ValidationException extends Exception {}
    public class LicenseException extends Exception {}
    public class IntegrationException extends Exception {}

    public static String handleError(Exception e, String context) {
        logError(e, context);
        return getUserFriendlyMessage(e, context);
    }

    public static void logError(Exception e, String context) {
        String errorDetails = buildErrorDetails(e, context);
        System.debug(LoggingLevel.ERROR, errorDetails);
        try {
            SFOpsAuditService.logEvent('Error', errorDetails, SFOpsAuditService.STATUS_ERROR);
        } catch (Exception auditEx) {
            System.debug(LoggingLevel.ERROR, 'Failed to audit log error: ' + auditEx.getMessage());
        }
    }

    public static String buildErrorDetails(Exception e, String context) {
        String details = 'Context: ' + (context != null ? context : 'Unknown') + '\n';
        details += 'Type: ' + e.getTypeName() + '\n';
        details += 'Message: ' + e.getMessage() + '\n';
        details += 'Line: ' + e.getLineNumber() + '\n';
        if (e.getCause() != null) {
            details += 'Cause: ' + e.getCause().getMessage() + '\n';
        }
        String stackTrace = e.getStackTraceString();
        if (String.isNotBlank(stackTrace)) {
            details += 'Stack Trace: ' + stackTrace + '\n';
        }
        if (e instanceof DmlException) {
            DmlException dmlEx = (DmlException) e;
            for (Integer i = 0; i < dmlEx.getNumDml(); i++) {
                details += 'DML Error [' + i + ']: ' + dmlEx.getDmlMessage(i) +
                          ' (Fields: ' + String.join(dmlEx.getDmlFieldNames(i), ', ') + ')\n';
            }
        }
        return details;
    }

    public static String getUserFriendlyMessage(Exception e, String context) {
        if (e instanceof SFOpsSecurityUtils.SecurityException) {
            return 'You do not have permission to perform this action. Please contact your administrator.';
        }
        if (e instanceof LicenseException) {
            return 'This feature is not available with your current license. Please upgrade your plan.';
        }
        if (e instanceof ValidationException) {
            return e.getMessage();
        }
        if (e instanceof ConfigurationException) {
            return 'Configuration error: ' + e.getMessage();
        }
        if (e instanceof DmlException) {
            return 'A data error occurred: ' + ((DmlException)e).getDmlMessage(0);
        }
        return 'An error occurred. Please try again.';
    }

    public static List<String> handleDmlResults(List<Database.SaveResult> results) {
        List<String> errors = new List<String>();
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    errors.add('Record ' + i + ': ' + err.getMessage());
                }
            }
        }
        return errors;
    }

    public static Map<String, Object> createSuccessResponse(Object data) {
        return new Map<String, Object>{ 'success' => true, 'data' => data, 'error' => null };
    }

    public static Map<String, Object> createErrorResponse(String message) {
        return new Map<String, Object>{ 'success' => false, 'data' => null, 'error' => message };
    }

    public static Map<String, Object> createErrorResponse(Exception e, String context) {
        logError(e, context);
        return new Map<String, Object>{ 'success' => false, 'data' => null, 'error' => getUserFriendlyMessage(e, context) };
    }
}
