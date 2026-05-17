public with sharing class PropertyService {
    public class PropertyFileInput {
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String base64Data { get; set; }
        @AuraEnabled public String contentType { get; set; }
    }

    public class PropertyServiceException extends Exception {}

    @AuraEnabled
    public static Id createProperty(Property__c propertyRecord, List<PropertyFileInput> files) {
        validateImageFiles(files);

        GeocodingService.GeocodeResult geocode = GeocodingService.geocode(propertyRecord);
        insert propertyRecord;

        if (geocode != null) {
            update new Property__c(
                Id = propertyRecord.Id,
                Location__Latitude__s = geocode.latitude,
                Location__Longitude__s = geocode.longitude,
                Latitude__c = geocode.latitude,
                Longitude__c = geocode.longitude
            );
        }

        List<ContentVersion> versions = new List<ContentVersion>();
        for (PropertyFileInput file : files) {
            versions.add(new ContentVersion(
                Title = file.fileName.contains('.') ? file.fileName.substringBeforeLast('.') : file.fileName,
                PathOnClient = file.fileName,
                VersionData = EncodingUtil.base64Decode(file.base64Data),
                FirstPublishLocationId = propertyRecord.Id
            ));
        }
        insert versions;

        return propertyRecord.Id;
    }

    private static void validateImageFiles(List<PropertyFileInput> files) {
        if (files == null || files.isEmpty()) {
            throw new AuraHandledException('At least one property image is required.');
        }
        for (PropertyFileInput file : files) {
            if (file == null || String.isBlank(file.fileName) || String.isBlank(file.base64Data)) {
                throw new AuraHandledException('Each image must include a file name and body.');
            }
            if (!isImageFile(file)) {
                throw new AuraHandledException('Only image files can be uploaded for a property.');
            }
        }
    }

    private static Boolean isImageFile(PropertyFileInput file) {
        if (!String.isBlank(file.contentType) && file.contentType.toLowerCase().startsWith('image/')) {
            return true;
        }
        String fileName = String.isBlank(file.fileName) ? '' : file.fileName.toLowerCase();
        return fileName.endsWith('.jpg') ||
            fileName.endsWith('.jpeg') ||
            fileName.endsWith('.png') ||
            fileName.endsWith('.gif') ||
            fileName.endsWith('.webp');
    }

    public static Boolean hasImages(Id propertyId) {
        return [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :propertyId
        ] > 0;
    }
}
