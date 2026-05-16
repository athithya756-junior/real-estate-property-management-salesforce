public with sharing class PropertyController {
    public class PropertyFilter {
        @AuraEnabled public Decimal minRent;
        @AuraEnabled public Decimal maxRent;
        @AuraEnabled public String availabilityStatus;
        @AuraEnabled public String furnishingStatus;
        @AuraEnabled public Decimal userLatitude;
        @AuraEnabled public Decimal userLongitude;
        @AuraEnabled public Decimal distanceKm;
        @AuraEnabled public Integer pageNumber;
    }

    public class PropertyPage {
        @AuraEnabled public List<Property__c> records;
        @AuraEnabled public Integer pageNumber;
        @AuraEnabled public Integer pageSize;
        @AuraEnabled public Integer totalRecords;
        @AuraEnabled public Boolean hasPrevious;
        @AuraEnabled public Boolean hasNext;
    }

    private static final Integer PAGE_SIZE = 25;

    @AuraEnabled(cacheable=true)
    public static PropertyPage searchProperties(PropertyFilter filter) {
        if (filter == null) {
            filter = new PropertyFilter();
        }
        Integer pageNumber = filter.pageNumber == null || filter.pageNumber < 1 ? 1 : filter.pageNumber;
        Integer offsetRows = (pageNumber - 1) * PAGE_SIZE;

        List<String> whereClauses = buildWhereClauses(filter);
        String whereClause = whereClauses.isEmpty() ? '' : ' WHERE ' + String.join(whereClauses, ' AND ');

        String query =
            'SELECT Id, Name, Address__c, City__c, State__c, Postal_Code__c, Country__c, Type__c, ' +
            'Furnishing_Status__c, Status__c, Rent__c, Description__c, Location__Latitude__s, Location__Longitude__s ' +
            'FROM Property__c' + whereClause + ' ORDER BY CreatedDate DESC LIMIT :PAGE_SIZE OFFSET :offsetRows';
        List<Property__c> properties = Database.query(query);

        Integer totalRecords = Database.countQuery('SELECT COUNT() FROM Property__c' + whereClause);

        PropertyPage page = new PropertyPage();
        page.records = properties;
        page.pageNumber = pageNumber;
        page.pageSize = PAGE_SIZE;
        page.totalRecords = totalRecords;
        page.hasPrevious = pageNumber > 1;
        page.hasNext = offsetRows + properties.size() < totalRecords;
        return page;
    }

    @AuraEnabled
    public static Id createProperty(Property__c propertyRecord, List<PropertyService.PropertyFileInput> files) {
        return PropertyService.createProperty(propertyRecord, files);
    }

    @AuraEnabled
    public static GeocodingService.GeocodeResult geocodeProperty(Id propertyId) {
        if (propertyId == null) {
            throw new AuraHandledException('Property Id is required.');
        }

        Property__c propertyRecord = [
            SELECT Name, Address__c, City__c, State__c, Postal_Code__c, Country__c
            FROM Property__c
            WHERE Id = :propertyId
            LIMIT 1
        ];

        try {
            GeocodingService.GeocodeResult geocode = GeocodingService.geocode(propertyRecord);
            if (geocode == null) {
                throw new AuraHandledException('Add a property address before loading the map.');
            }

            propertyRecord.Location__Latitude__s = geocode.latitude;
            propertyRecord.Location__Longitude__s = geocode.longitude;
            update propertyRecord;
            return geocode;
        } catch (GeocodingService.GeocodingException error) {
            throw new AuraHandledException(error.getMessage());
        }
    }

    private static List<String> buildWhereClauses(PropertyFilter filter) {
        List<String> clauses = new List<String>();
        if (filter.minRent != null) {
            clauses.add('Rent__c >= ' + filter.minRent);
        }
        if (filter.maxRent != null) {
            clauses.add('Rent__c <= ' + filter.maxRent);
        }
        if (!String.isBlank(filter.availabilityStatus)) {
            clauses.add('Status__c = \'' + String.escapeSingleQuotes(filter.availabilityStatus) + '\'');
        }
        if (!String.isBlank(filter.furnishingStatus)) {
            clauses.add('Furnishing_Status__c = \'' + String.escapeSingleQuotes(filter.furnishingStatus) + '\'');
        }
        if (filter.userLatitude != null && filter.userLongitude != null && filter.distanceKm != null) {
            clauses.add(
                'DISTANCE(Location__c, GEOLOCATION(' + filter.userLatitude + ', ' + filter.userLongitude + '), \'km\') <= ' +
                filter.distanceKm
            );
        }
        return clauses;
    }
}
