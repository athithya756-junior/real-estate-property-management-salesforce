@IsTest
private class PropertyControllerTest {
    @IsTest
    static void createPropertyRequiresImage() {
        Test.setMock(HttpCalloutMock.class, new MockGeocodingResponse());

        try {
            PropertyController.createProperty(RealEstateTestDataFactory.buildProperty('No Image'), new List<PropertyService.PropertyFileInput>());
            System.assert(false, 'Expected image requirement exception.');
        } catch (AuraHandledException expected) {
            System.assert(expected.getMessage().contains('image'));
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
            SELECT Location__Latitude__s, Location__Longitude__s
            FROM Property__c
            WHERE Id = :propertyId
        ];
        System.assertEquals(13.0827, saved.Location__Latitude__s);
        System.assertEquals(80.2707, saved.Location__Longitude__s);
        System.assertEquals(true, PropertyService.hasImages(propertyId));
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

        filter.availabilityStatus = 'Available';
        filter.minRent = 10000;
        filter.maxRent = 10020;
        filter.userLatitude = 13.0827;
        filter.userLongitude = 80.2707;
        filter.distanceKm = 5;

        PropertyController.PropertyPage filteredPage = PropertyController.searchProperties(filter);
        System.assert(filteredPage.records.size() > 0, 'Expected filtered property records.');
        for (Property__c propertyRecord : filteredPage.records) {
            System.assertEquals('Available', propertyRecord.Status__c);
        }
    }
}
