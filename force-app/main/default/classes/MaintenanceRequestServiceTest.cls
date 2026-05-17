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
        Id leastLoadedVendorId = VendorAssignmentService.getVendorIdWithMinimumActiveRequests();
        insert requests;
        Test.stopTest();

        System.assertEquals(availableVendor.Id, leastLoadedVendorId);
        List<Maintenance_Request__c> saved = [
            SELECT Vendor__c
            FROM Maintenance_Request__c
            WHERE Id IN :requests
        ];
        System.assertEquals(availableVendor.Id, saved[0].Vendor__c, 'First new request should go to least loaded vendor.');
    }

    @IsTest
    static void controllerCreatesAndListsRequestsWithVendor() {
        Vendor__c vendor = RealEstateTestDataFactory.createVendor('Controller');
        Property__c propertyRecord = RealEstateTestDataFactory.createProperty('Controller Maintenance');

        Test.startTest();
        Maintenance_Request__c request = MaintenanceRequestController.createRequest(propertyRecord.Id, 'Fix plumbing');
        List<Maintenance_Request__c> requests = MaintenanceRequestController.listRequests();
        Test.stopTest();

        System.assertEquals(vendor.Id, request.Vendor__c);
        Boolean found = false;
        for (Maintenance_Request__c savedRequest : requests) {
            if (savedRequest.Id == request.Id) {
                found = true;
                System.assertEquals(propertyRecord.Name, savedRequest.Property__r.Name);
                System.assertEquals(vendor.Name, savedRequest.Vendor__r.Name);
                System.assertEquals('Open', savedRequest.Status__c);
            }
        }
        System.assertEquals(true, found, 'Created request should appear in the maintenance management list.');
    }

    @IsTest
    static void maintenanceRequestRequiresVendorInventory() {
        Property__c propertyRecord = RealEstateTestDataFactory.createProperty('No Vendor');

        try {
            MaintenanceRequestController.createRequest(propertyRecord.Id, 'Fix electrical issue');
            System.assert(false, 'Expected maintenance request to require at least one vendor.');
        } catch (DmlException expected) {
            System.assertNotEquals(null, expected);
        }
    }
}
