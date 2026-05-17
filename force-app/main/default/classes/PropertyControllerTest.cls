@IsTest
private class PropertyControllerTest {
    @IsTest
    static void createPropertyRequiresImage() {
        Test.setMock(HttpCalloutMock.class, new MockGeocodingResponse());

        try {
            PropertyController.createProperty(RealEstateTestDataFactory.buildProperty('No Image'), new List<PropertyService.PropertyFileInput>());
            System.assert(false, 'Expected image requirement exception.');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected);
        }
    }

    @IsTest
    static void createPropertyWithImageGeocodesAndCreatesFile() {
        Test.setMock(HttpCalloutMock.class, new MockGeocodingResponse());

        PropertyService.PropertyFileInput file = new PropertyService.PropertyFileInput();
        file.fileName = 'front.jpg';
        file.contentType = 'image/jpeg';
        file.base64Data = EncodingUtil.base64Encode(Blob.valueOf('fake image'));

        Test.startTest();
        Id propertyId = PropertyController.createProperty(
            RealEstateTestDataFactory.buildProperty('With Image'),
            new List<PropertyService.PropertyFileInput>{ file }
        );
        Test.stopTest();

        Property__c saved = [
            SELECT Location__Latitude__s, Location__Longitude__s, Latitude__c, Longitude__c
            FROM Property__c
            WHERE Id = :propertyId
        ];
        System.assertEquals(13.0827, saved.Location__Latitude__s);
        System.assertEquals(80.2707, saved.Location__Longitude__s);
        System.assertEquals(13.0827, saved.Latitude__c);
        System.assertEquals(80.2707, saved.Longitude__c);
        System.assertEquals(true, PropertyService.hasImages(propertyId));

        List<PropertyController.PropertyImage> images = PropertyController.getPropertyImages(propertyId);
        System.assertEquals(1, images.size());
        System.assertEquals('front', images[0].title);

        PropertyController.PropertyPage page = PropertyController.searchProperties(new PropertyController.PropertyFilter());
        Boolean foundCreatedProperty = false;
        for (PropertyController.PropertyRow row : page.records) {
            if (row.propertyId == propertyId) {
                foundCreatedProperty = true;
                System.assertEquals(1, row.imageCount);
                System.assertEquals(true, row.hasImages);
            }
        }
        System.assertEquals(true, foundCreatedProperty, 'Created property should be returned with image count.');
    }

    @IsTest
    static void createPropertyRejectsNonImageFile() {
        PropertyService.PropertyFileInput file = new PropertyService.PropertyFileInput();
        file.fileName = 'notes.txt';
        file.contentType = 'text/plain';
        file.base64Data = EncodingUtil.base64Encode(Blob.valueOf('not an image'));

        try {
            PropertyController.createProperty(
                RealEstateTestDataFactory.buildProperty('Bad File'),
                new List<PropertyService.PropertyFileInput>{ file }
            );
            System.assert(false, 'Expected non-image file exception.');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected);
        }
    }

    @IsTest
    static void geocodePropertyUpdatesExistingPropertyLocation() {
        Test.setMock(HttpCalloutMock.class, new MockGeocodingResponse());
        Property__c propertyRecord = RealEstateTestDataFactory.buildProperty('Existing');
        insert propertyRecord;

        Test.startTest();
        GeocodingService.GeocodeResult result = PropertyController.geocodeProperty(propertyRecord.Id);
        Test.stopTest();

        Property__c saved = [
            SELECT Location__Latitude__s, Location__Longitude__s, Latitude__c, Longitude__c
            FROM Property__c
            WHERE Id = :propertyRecord.Id
        ];
        System.assertEquals(13.0827, result.latitude);
        System.assertEquals(80.2707, result.longitude);
        System.assertEquals(13.0827, saved.Location__Latitude__s);
        System.assertEquals(80.2707, saved.Location__Longitude__s);
        System.assertEquals(13.0827, saved.Latitude__c);
        System.assertEquals(80.2707, saved.Longitude__c);
    }

    @IsTest
    static void getPropertyLocationReturnsSavedCoordinates() {
        Property__c propertyRecord = RealEstateTestDataFactory.buildProperty('Mapped');
        propertyRecord.Location__Latitude__s = 13.0002927;
        propertyRecord.Location__Longitude__s = 80.2666982;
        insert propertyRecord;

        PropertyController.PropertyLocation location = PropertyController.getPropertyLocation(propertyRecord.Id);

        System.assertEquals(propertyRecord.Name, location.propertyName);
        System.assertEquals(Decimal.valueOf('13.000293'), location.latitude.setScale(6));
        System.assertEquals(Decimal.valueOf('80.266698'), location.longitude.setScale(6));
    }

    @IsTest
    static void searchPropertiesPaginatesAndFilters() {
        List<Property__c> properties = new List<Property__c>();
        for (Integer i = 0; i < 30; i++) {
            Property__c propertyRecord = RealEstateTestDataFactory.buildProperty(String.valueOf(i));
            propertyRecord.Rent__c = 10000 + i;
            propertyRecord.Status__c = Math.mod(i, 2) == 0 ? 'Available' : 'Occupied';
            propertyRecord.Furnishing_Status__c = 'Furnished';
            propertyRecord.Location__Latitude__s = 13.0827;
            propertyRecord.Location__Longitude__s = 80.2707;
            properties.add(propertyRecord);
        }
        insert properties;

        PropertyController.PropertyFilter filter = new PropertyController.PropertyFilter();
        filter.pageNumber = 1;

        PropertyController.PropertyPage page = PropertyController.searchProperties(filter);
        System.assertEquals(25, page.records.size());
        System.assertEquals(true, page.hasNext);
        PropertyController.PropertyPage aliasPage = PropertyController.getProperties(filter, 1, 25, null, null, null);
        System.assertEquals(25, aliasPage.pageSize);

        filter.availabilityStatus = 'Available';
        filter.minRent = 10000;
        filter.maxRent = 10020;
        filter.userLatitude = 13.0827;
        filter.userLongitude = 80.2707;
        filter.distanceKm = 5;

        PropertyController.PropertyPage filteredPage = PropertyController.searchProperties(filter);
        System.assert(filteredPage.records.size() > 0, 'Expected filtered property records.');
        for (PropertyController.PropertyRow propertyRecord : filteredPage.records) {
            System.assertEquals('Available', propertyRecord.status);
        }
    }

    @IsTest
    static void searchPropertiesRequiresLocationForDistanceFilter() {
        PropertyController.PropertyFilter filter = new PropertyController.PropertyFilter();
        filter.distanceKm = 5;

        try {
            PropertyController.searchProperties(filter);
            System.assert(false, 'Expected nearby filter location exception.');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected);
        }
    }
}
