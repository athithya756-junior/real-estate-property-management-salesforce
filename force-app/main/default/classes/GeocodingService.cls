public with sharing class GeocodingService {
    public class GeocodeResult {
        @AuraEnabled public Decimal latitude;
        @AuraEnabled public Decimal longitude;
    }

    public class GeocodingException extends Exception {}

    public static GeocodeResult geocode(Property__c propertyRecord) {
        String address = buildAddress(propertyRecord);
        if (String.isBlank(address)) {
            return null;
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(buildEndpoint(address));
        request.setTimeout(10000);

        HttpResponse response = new Http().send(request);
        if (response.getStatusCode() < 200 || response.getStatusCode() > 299) {
            throw new GeocodingException('Geocoding failed: ' + response.getStatus());
        }

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        List<Object> results = (List<Object>) payload.get('results');
        if (results == null || results.isEmpty()) {
            return null;
        }

        Map<String, Object> firstResult = (Map<String, Object>) results[0];
        Map<String, Object> geometry = (Map<String, Object>) firstResult.get('geometry');
        Map<String, Object> location = (Map<String, Object>) geometry.get('location');

        GeocodeResult result = new GeocodeResult();
        result.latitude = Decimal.valueOf(String.valueOf(location.get('lat')));
        result.longitude = Decimal.valueOf(String.valueOf(location.get('lng')));
        return result;
    }

    private static String buildAddress(Property__c propertyRecord) {
        List<String> parts = new List<String>{
            propertyRecord.Address__c,
            propertyRecord.City__c,
            propertyRecord.State__c,
            propertyRecord.Postal_Code__c,
            propertyRecord.Country__c
        };
        List<String> cleanParts = new List<String>();
        for (String part : parts) {
            if (!String.isBlank(part)) {
                cleanParts.add(part.trim());
            }
        }
        return String.join(cleanParts, ', ');
    }

    @TestVisible
    private static String buildEndpoint(String address) {
        return 'callout:Google_Geocoding/maps/api/geocode/json?address=' + EncodingUtil.urlEncode(address, 'UTF-8');
    }
}
