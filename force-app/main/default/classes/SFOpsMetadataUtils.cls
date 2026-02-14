public with sharing class SFOpsMetadataUtils {
    public static final String CATEGORY_CODE = 'Code';
    public static final String CATEGORY_CONFIG = 'Configuration';
    public static final String CATEGORY_UI = 'UI';
    public static final String CATEGORY_SECURITY = 'Security';
    public static final String CATEGORY_AUTOMATION = 'Automation';

    private static final Map<String, String> METADATA_TYPE_CATEGORIES = new Map<String, String>{
        'ApexClass' => CATEGORY_CODE, 'ApexTrigger' => CATEGORY_CODE,
        'ApexComponent' => CATEGORY_CODE, 'ApexPage' => CATEGORY_CODE,
        'AuraDefinitionBundle' => CATEGORY_UI, 'LightningComponentBundle' => CATEGORY_UI,
        'FlexiPage' => CATEGORY_UI, 'Layout' => CATEGORY_UI,
        'CustomObject' => CATEGORY_CONFIG, 'CustomField' => CATEGORY_CONFIG,
        'CustomTab' => CATEGORY_CONFIG, 'CustomLabel' => CATEGORY_CONFIG,
        'Flow' => CATEGORY_AUTOMATION, 'WorkflowRule' => CATEGORY_AUTOMATION,
        'ValidationRule' => CATEGORY_CONFIG, 'Profile' => CATEGORY_SECURITY,
        'PermissionSet' => CATEGORY_SECURITY, 'StaticResource' => CATEGORY_UI,
        'NamedCredential' => CATEGORY_SECURITY, 'ConnectedApp' => CATEGORY_SECURITY
    };

    public static String getMetadataCategory(String metadataType) {
        String category = METADATA_TYPE_CATEGORIES.get(metadataType);
        return category != null ? category : 'Other';
    }

    public static String computeContentHash(String content) {
        return SFOpsSecurityUtils.generateHash(content);
    }

    public static Boolean hasContentChanged(String hash1, String hash2) {
        if (String.isBlank(hash1) && String.isBlank(hash2)) return false;
        if (String.isBlank(hash1) || String.isBlank(hash2)) return true;
        return hash1 != hash2;
    }

    public static String extractApiName(String fullName) {
        if (String.isBlank(fullName)) return fullName;
        Integer dotIndex = fullName.lastIndexOf('.');
        if (dotIndex > 0) {
            String extension = fullName.substring(dotIndex + 1).toLowerCase();
            Set<String> fileExtensions = new Set<String>{ 'cls', 'trigger', 'page', 'component', 'resource', 'xml', 'js', 'html', 'css' };
            if (fileExtensions.contains(extension)) return fullName.substring(0, dotIndex);
        }
        return fullName;
    }

    public static String getFileExtension(String metadataType) {
        Map<String, String> extensions = new Map<String, String>{
            'ApexClass' => '.cls', 'ApexTrigger' => '.trigger', 'ApexPage' => '.page',
            'StaticResource' => '.resource', 'LightningComponentBundle' => '.js'
        };
        String ext = extensions.get(metadataType);
        return ext != null ? ext : '.xml';
    }

    public static String extractXmlElement(String xmlContent, String elementName) {
        if (String.isBlank(xmlContent) || String.isBlank(elementName)) return null;
        String openTag = '<' + elementName + '>';
        String closeTag = '</' + elementName + '>';
        Integer startIndex = xmlContent.indexOf(openTag);
        if (startIndex < 0) return null;
        startIndex += openTag.length();
        Integer endIndex = xmlContent.indexOf(closeTag, startIndex);
        if (endIndex < 0) return null;
        return xmlContent.substring(startIndex, endIndex);
    }

    public static Integer calculateSizeBytes(String content) {
        if (String.isBlank(content)) return 0;
        return Blob.valueOf(content).size();
    }

    public static String formatFileSize(Decimal sizeBytes) {
        if (sizeBytes == null || sizeBytes == 0) return '0 B';
        if (sizeBytes < 1024) return sizeBytes.intValue() + ' B';
        if (sizeBytes < 1048576) return (sizeBytes / 1024).setScale(1, RoundingMode.HALF_UP) + ' KB';
        return (sizeBytes / 1048576).setScale(2, RoundingMode.HALF_UP) + ' MB';
    }

    public static String buildPackageXml(Map<String, List<String>> typeToMembers, String apiVersion) {
        String xml = '<?xml version="1.0" encoding="UTF-8"?>\n<Package xmlns="http://soap.sforce.com/2006/04/metadata">\n';
        for (String metadataType : typeToMembers.keySet()) {
            xml += '    <types>\n';
            for (String member : typeToMembers.get(metadataType)) {
                xml += '        <members>' + member + '</members>\n';
            }
            xml += '        <name>' + metadataType + '</name>\n    </types>\n';
        }
        xml += '    <version>' + apiVersion + '</version>\n</Package>';
        return xml;
    }

    public static String normalizeXml(String xmlContent) {
        if (String.isBlank(xmlContent)) return '';
        String normalized = xmlContent.replaceAll('<\\?xml[^?]*\\?>', '');
        normalized = normalized.replaceAll('\\s+', ' ');
        return normalized.trim();
    }
}
