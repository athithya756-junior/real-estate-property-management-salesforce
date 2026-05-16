@IsTest
private class LeaseAgreementControllerTest {
    @IsTest
    static void tenantCanHaveMultipleLeasesAndTaskIsCreated() {
        Tenant__c tenant = RealEstateTestDataFactory.createTenant();
        Property__c firstProperty = RealEstateTestDataFactory.createProperty('Lease 1');
        Property__c secondProperty = RealEstateTestDataFactory.createProperty('Lease 2');

        Lease_Agreement__c firstAgreement = new Lease_Agreement__c(
            Tenant__c = tenant.Id,
            Property__c = firstProperty.Id,
            Terms__c = 'Terms',
            Agreed_Monthly_Rent__c = 25000,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(12),
            Status__c = 'Active'
        );
        Lease_Agreement__c secondAgreement = firstAgreement.clone(false, true, false, false);
        secondAgreement.Property__c = secondProperty.Id;

        Test.startTest();
        Id firstId = LeaseAgreementController.createAgreement(firstAgreement);
        Id secondId = LeaseAgreementController.createAgreement(secondAgreement);
        Test.stopTest();

        System.assertNotEquals(null, firstId);
        System.assertNotEquals(null, secondId);
        System.assertEquals(2, [SELECT COUNT() FROM Lease_Agreement__c WHERE Tenant__c = :tenant.Id]);
        System.assertEquals(2, [SELECT COUNT() FROM Task WHERE Subject = 'Generate lease agreement']);
        Set<Id> propertyIds = new Set<Id>{ firstProperty.Id, secondProperty.Id };
        System.assertEquals(2, [SELECT COUNT() FROM Property__c WHERE Id IN :propertyIds AND Status__c = 'Occupied']);
    }

    @IsTest
    static void standardLeaseInsertCreatesTasksAndMarksPropertiesOccupiedInBulk() {
        Tenant__c tenant = RealEstateTestDataFactory.createTenant();
        List<Property__c> properties = new List<Property__c>{
            RealEstateTestDataFactory.buildProperty('Bulk Lease 1'),
            RealEstateTestDataFactory.buildProperty('Bulk Lease 2')
        };
        insert properties;

        List<Lease_Agreement__c> agreements = new List<Lease_Agreement__c>();
        for (Property__c propertyRecord : properties) {
            agreements.add(new Lease_Agreement__c(
                Tenant__c = tenant.Id,
                Property__c = propertyRecord.Id,
                Terms__c = 'Terms',
                Agreed_Monthly_Rent__c = 25000,
                Start_Date__c = Date.today(),
                End_Date__c = Date.today().addMonths(12),
                Status__c = 'Active'
            ));
        }

        Test.startTest();
        insert agreements;
        Test.stopTest();

        System.assertEquals(2, [SELECT COUNT() FROM Task WHERE Subject = 'Generate lease agreement']);
        Set<Id> propertyIds = new Map<Id, Property__c>(properties).keySet();
        System.assertEquals(2, [SELECT COUNT() FROM Property__c WHERE Id IN :propertyIds AND Status__c = 'Occupied']);
    }

    @IsTest
    static void sendLeasePdfEmailsTenant() {
        Tenant__c tenant = RealEstateTestDataFactory.createTenant();
        Property__c propertyRecord = RealEstateTestDataFactory.createProperty('Email');
        Lease_Agreement__c agreement = RealEstateTestDataFactory.createLease(propertyRecord, tenant, Date.today().addMonths(12));

        Test.startTest();
        LeaseAgreementController.sendAgreementPdf(agreement.Id, EncodingUtil.base64Encode(Blob.valueOf('pdf')));
        Test.stopTest();

        System.assertEquals(1, Limits.getEmailInvocations());
    }
}
