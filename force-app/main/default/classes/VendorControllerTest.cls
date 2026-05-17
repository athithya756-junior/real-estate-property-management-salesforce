@IsTest
private class VendorControllerTest {
    @IsTest
    static void createsAndListsVendors() {
        Vendor__c vendor = new Vendor__c(
            Name = 'Reliable Maintenance',
            Phone__c = '8888888888',
            Email__c = 'vendor@example.com'
        );

        Test.startTest();
        Id vendorId = VendorController.createVendor(vendor);
        List<Vendor__c> vendors = VendorController.listVendors();
        Test.stopTest();

        System.assertNotEquals(null, vendorId);
        Boolean found = false;
        for (Vendor__c savedVendor : vendors) {
            if (savedVendor.Id == vendorId) {
                found = true;
                System.assertEquals('8888888888', savedVendor.Phone__c);
                System.assertEquals('vendor@example.com', savedVendor.Email__c);
            }
        }
        System.assertEquals(true, found, 'Created vendor should appear in vendor management list.');
    }

    @IsTest
    static void createVendorRequiresName() {
        try {
            VendorController.createVendor(new Vendor__c(Phone__c = '8888888888'));
            System.assert(false, 'Expected vendor name validation.');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected);
        }
    }
}
