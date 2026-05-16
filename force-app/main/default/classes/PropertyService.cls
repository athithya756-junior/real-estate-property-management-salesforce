public with sharing class PropertyService {
    public class PropertyFileInput {
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String base64Data { get; set; }
        @AuraEnabled public String contentType { get; set; }
    }

    public class PropertyServiceException extends Exception {}

    @AuraEnabled
    public static Id createProperty(Property__c propertyRecord, List<PropertyFileInput> files) {
        if (files == null || files.isEmpty()) {
            throw new AuraHandledException('At least one property image is required.');
        }

        GeocodingService.GeocodeResult geocode = GeocodingService.geocode(propertyRecord);
        if (geocode != null) {
            propertyRecord.Location__Latitude__s = geocode.latitude;
            propertyRecord.Location__Longitude__s = geocode.longitude;
        }

        insert propertyRecord;

        List<ContentVersion> versions = new List<ContentVersion>();
        for (PropertyFileInput file : files) {
            if (String.isBlank(file.fileName) || String.isBlank(file.base64Data)) {
                throw new AuraHandledException('Each image must include a file name and body.');
            }
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

    public static Boolean hasImages(Id propertyId) {
        return [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :propertyId
        ] > 0;
    }
}
