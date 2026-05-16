@IsTest
private class MaintenanceRequestServiceTest {
    @IsTest
    static void assignsLeastLoadedVendorInBulk() {
        Vendor__c busyVendor = RealEstateTestDataFactory.createVendor('Busy');
        Vendor__c availableVendor = RealEstateTestDataFactory.createVendor('Available');
        Property__c propertyRecord = RealEstateTestDataFactory.createProperty('Maintenance');

        insert new Maintenance_Request__c(
            Property__c = propertyRecord.Id,
            Vendor__c = busyVendor.Id,
            Status__c = 'Open',
            Description__c = 'Existing request'
        );

        List<Maintenance_Request__c> requests = new List<Maintenance_Request__c>();
        for (Integer i = 0; i < 3; i++) {
            requests.add(new Maintenance_Request__c(
                Property__c = propertyRecord.Id,
                Status__c = 'Open',
                Description__c = 'New request ' + i
            ));
        }

        Test.startTest();
        insert requests;
        Test.stopTest();

        List<Maintenance_Request__c> saved = [
            SELECT Vendor__c
            FROM Maintenance_Request__c
            WHERE Id IN :requests
        ];
        System.assertEquals(availableVendor.Id, saved[0].Vendor__c, 'First new request should go to least loaded vendor.');
    }
}
