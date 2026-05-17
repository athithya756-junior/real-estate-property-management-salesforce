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
        @AuraEnabled public List<PropertyRow> records;
        @AuraEnabled public Integer pageNumber;
        @AuraEnabled public Integer pageSize;
        @AuraEnabled public Integer totalRecords;
        @AuraEnabled public Boolean hasPrevious;
        @AuraEnabled public Boolean hasNext;
    }

    public class PropertyRow {
        @AuraEnabled public Id propertyId;
        @AuraEnabled public String propertyName;
        @AuraEnabled public String address;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String country;
        @AuraEnabled public String propertyType;
        @AuraEnabled public String furnishingStatus;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal rent;
        @AuraEnabled public String description;
        @AuraEnabled public Decimal latitude;
        @AuraEnabled public Decimal longitude;
        @AuraEnabled public Integer imageCount;
        @AuraEnabled public Boolean hasImages;
    }

    public class PropertyLocation {
        @AuraEnabled public String propertyName;
        @AuraEnabled public Decimal latitude;
        @AuraEnabled public Decimal longitude;
    }

    public class PropertyImage {
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public Id versionId;
        @AuraEnabled public String title;
        @AuraEnabled public String fileType;
        @AuraEnabled public String previewUrl;
        @AuraEnabled public String downloadUrl;
    }

    private static final Integer PAGE_SIZE = 25;

    @AuraEnabled(cacheable=true)
    public static PropertyPage getProperties(
        PropertyFilter filters,
        Integer pageNumber,
        Integer pageSize,
        Decimal userLat,
        Decimal userLng,
        Decimal distanceKm
    ) {
        if (filters == null) {
            filters = new PropertyFilter();
        }
        if (pageNumber != null) {
            filters.pageNumber = pageNumber;
        }
        if (userLat != null) {
            filters.userLatitude = userLat;
        }
        if (userLng != null) {
            filters.userLongitude = userLng;
        }
        if (distanceKm != null) {
            filters.distanceKm = distanceKm;
        }
        return searchProperties(filters);
    }

    @AuraEnabled(cacheable=true)
    public static PropertyPage searchProperties(PropertyFilter filter) {
        if (filter == null) {
            filter = new PropertyFilter();
        }
        validateFilter(filter);
        Integer pageNumber = filter.pageNumber == null || filter.pageNumber < 1 ? 1 : filter.pageNumber;
        Integer offsetRows = (pageNumber - 1) * PAGE_SIZE;

        List<String> whereClauses = buildWhereClauses(filter);
        String whereClause = whereClauses.isEmpty() ? '' : ' WHERE ' + String.join(whereClauses, ' AND ');

        String query =
            'SELECT Id, Name, Address__c, City__c, State__c, Postal_Code__c, Country__c, Type__c, ' +
            'Furnishing_Status__c, Status__c, Rent__c, Description__c, Latitude__c, Longitude__c, ' +
            'Location__Latitude__s, Location__Longitude__s ' +
            'FROM Property__c' + whereClause + ' ORDER BY CreatedDate DESC LIMIT :PAGE_SIZE OFFSET :offsetRows';
        List<Property__c> properties = Database.query(query);
        Map<Id, Integer> imageCountByPropertyId = getImageCounts(new Map<Id, Property__c>(properties).keySet());

        Integer totalRecords = Database.countQuery('SELECT COUNT() FROM Property__c' + whereClause);

        PropertyPage page = new PropertyPage();
        page.records = buildRows(properties, imageCountByPropertyId);
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

    @AuraEnabled(cacheable=true)
    public static List<PropertyImage> getPropertyImages(Id propertyId) {
        if (propertyId == null) {
            throw new AuraHandledException('Property Id is required.');
        }

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :propertyId
            LIMIT 200
        ];
        Set<Id> documentIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            documentIds.add(link.ContentDocumentId);
        }
        if (documentIds.isEmpty()) {
            return new List<PropertyImage>();
        }

        List<PropertyImage> images = new List<PropertyImage>();
        for (ContentVersion version : [
            SELECT Id, ContentDocumentId, Title, FileType
            FROM ContentVersion
            WHERE ContentDocumentId IN :documentIds
            AND IsLatest = true
            ORDER BY CreatedDate DESC
            LIMIT 200
        ]) {
            PropertyImage image = new PropertyImage();
            image.contentDocumentId = version.ContentDocumentId;
            image.versionId = version.Id;
            image.title = version.Title;
            image.fileType = version.FileType;
            image.previewUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=' + version.Id;
            image.downloadUrl = '/sfc/servlet.shepherd/version/download/' + version.Id;
            images.add(image);
        }
        return images;
    }

    @AuraEnabled
    public static GeocodingService.GeocodeResult geocodeProperty(Id propertyId) {
        if (propertyId == null) {
            throw new AuraHandledException('Property Id is required.');
        }

        Property__c propertyRecord = [
            SELECT Name, Address__c, City__c, State__c, Postal_Code__c, Country__c,
                Latitude__c, Longitude__c
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
            propertyRecord.Latitude__c = geocode.latitude;
            propertyRecord.Longitude__c = geocode.longitude;
            update propertyRecord;
            return geocode;
        } catch (GeocodingService.GeocodingException error) {
            throw new AuraHandledException(error.getMessage());
        }
    }

    @AuraEnabled
    public static PropertyLocation getPropertyLocation(Id propertyId) {
        if (propertyId == null) {
            throw new AuraHandledException('Property Id is required.');
        }

        Property__c propertyRecord = [
            SELECT Id, Name, Address__c, City__c, State__c, Postal_Code__c, Country__c,
                Latitude__c, Longitude__c, Location__Latitude__s, Location__Longitude__s
            FROM Property__c
            WHERE Id = :propertyId
            LIMIT 1
        ];

        Decimal latitude = propertyRecord.Location__Latitude__s == null ? propertyRecord.Latitude__c : propertyRecord.Location__Latitude__s;
        Decimal longitude = propertyRecord.Location__Longitude__s == null ? propertyRecord.Longitude__c : propertyRecord.Location__Longitude__s;
        if (latitude == null || longitude == null) {
            try {
                GeocodingService.GeocodeResult geocode = GeocodingService.geocode(propertyRecord);
                if (geocode == null) {
                    throw new AuraHandledException('Add a property address before loading the map.');
                }

                propertyRecord.Location__Latitude__s = geocode.latitude;
                propertyRecord.Location__Longitude__s = geocode.longitude;
                propertyRecord.Latitude__c = geocode.latitude;
                propertyRecord.Longitude__c = geocode.longitude;
                update propertyRecord;
                latitude = geocode.latitude;
                longitude = geocode.longitude;
            } catch (GeocodingService.GeocodingException error) {
                throw new AuraHandledException(error.getMessage());
            }
        } else if (propertyRecord.Location__Latitude__s == null || propertyRecord.Location__Longitude__s == null) {
            update new Property__c(
                Id = propertyRecord.Id,
                Location__Latitude__s = latitude,
                Location__Longitude__s = longitude
            );
        } else if (propertyRecord.Latitude__c == null || propertyRecord.Longitude__c == null) {
            update new Property__c(
                Id = propertyRecord.Id,
                Latitude__c = latitude,
                Longitude__c = longitude
            );
        }

        PropertyLocation location = new PropertyLocation();
        location.propertyName = propertyRecord.Name;
        location.latitude = latitude;
        location.longitude = longitude;
        return location;
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
                'DISTANCE(Location__c, GEOLOCATION(' + filter.userLatitude + ', ' + filter.userLongitude + '), \'km\') < ' +
                filter.distanceKm
            );
        }
        return clauses;
    }

    private static void validateFilter(PropertyFilter filter) {
        if (filter.minRent != null && filter.maxRent != null && filter.minRent > filter.maxRent) {
            throw new AuraHandledException('Minimum rent cannot be greater than maximum rent.');
        }
        if (filter.distanceKm != null) {
            if (filter.distanceKm <= 0) {
                throw new AuraHandledException('Nearby distance must be greater than zero.');
            }
            if (filter.userLatitude == null || filter.userLongitude == null) {
                throw new AuraHandledException('Use your current location before applying the nearby distance filter.');
            }
        }
    }

    private static List<PropertyRow> buildRows(List<Property__c> properties, Map<Id, Integer> imageCountByPropertyId) {
        List<PropertyRow> rows = new List<PropertyRow>();
        for (Property__c propertyRecord : properties) {
            Integer imageCount = imageCountByPropertyId.containsKey(propertyRecord.Id)
                ? imageCountByPropertyId.get(propertyRecord.Id)
                : 0;
            PropertyRow row = new PropertyRow();
            row.propertyId = propertyRecord.Id;
            row.propertyName = propertyRecord.Name;
            row.address = propertyRecord.Address__c;
            row.city = propertyRecord.City__c;
            row.state = propertyRecord.State__c;
            row.postalCode = propertyRecord.Postal_Code__c;
            row.country = propertyRecord.Country__c;
            row.propertyType = propertyRecord.Type__c;
            row.furnishingStatus = propertyRecord.Furnishing_Status__c;
            row.status = propertyRecord.Status__c;
            row.rent = propertyRecord.Rent__c;
            row.description = propertyRecord.Description__c;
            row.latitude = propertyRecord.Location__Latitude__s == null ? propertyRecord.Latitude__c : propertyRecord.Location__Latitude__s;
            row.longitude = propertyRecord.Location__Longitude__s == null ? propertyRecord.Longitude__c : propertyRecord.Location__Longitude__s;
            row.imageCount = imageCount;
            row.hasImages = imageCount > 0;
            rows.add(row);
        }
        return rows;
    }

    private static Map<Id, Integer> getImageCounts(Set<Id> propertyIds) {
        Map<Id, Integer> imageCountByPropertyId = new Map<Id, Integer>();
        if (propertyIds.isEmpty()) {
            return imageCountByPropertyId;
        }
        for (AggregateResult result : [
            SELECT LinkedEntityId, COUNT(Id) imageCount
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :propertyIds
            GROUP BY LinkedEntityId
        ]) {
            imageCountByPropertyId.put((Id) result.get('LinkedEntityId'), (Integer) result.get('imageCount'));
        }
        return imageCountByPropertyId;
    }
}
