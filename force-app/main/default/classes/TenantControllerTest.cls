@IsTest
private class TenantControllerTest {
    @IsTest
    static void listsTenantsAndTenantLeaseAssignments() {
        Tenant__c tenant = RealEstateTestDataFactory.createTenant();
        Property__c firstProperty = RealEstateTestDataFactory.createProperty('Tenant Lease 1');
        Property__c secondProperty = RealEstateTestDataFactory.createProperty('Tenant Lease 2');

        RealEstateTestDataFactory.createLease(firstProperty, tenant, Date.today().addMonths(6));
        RealEstateTestDataFactory.createLease(secondProperty, tenant, Date.today().addMonths(12));

        Test.startTest();
        List<Tenant__c> aliasedTenants = TenantController.getTenants();
        List<Tenant__c> tenants = TenantController.listTenants();
        Tenant__c tenantDetails = TenantController.getTenant(tenant.Id);
        List<Lease_Agreement__c> leases = TenantController.listTenantLeases(tenant.Id);
        List<Task> leaseTasks = TenantController.listLeaseGenerationTasks(tenant.Id);
        Test.stopTest();

        System.assertEquals('tenant@example.com', tenantDetails.Email__c);
        System.assertEquals(true, aliasedTenants.size() > 0);
        System.assertEquals(true, tenants.size() > 0);
        System.assertEquals(2, leases.size(), 'A tenant can rent multiple properties through lease agreements.');
        System.assertEquals(2, leaseTasks.size(), 'Lease generation tasks are tracked on the tenant record.');
        Set<Id> propertyIds = new Set<Id>();
        for (Lease_Agreement__c lease : leases) {
            propertyIds.add(lease.Property__c);
        }
        System.assertEquals(new Set<Id>{ firstProperty.Id, secondProperty.Id }, propertyIds);
    }

    @IsTest
    static void assignPropertiesCreatesDraftLeasesAndTasks() {
        Tenant__c tenant = RealEstateTestDataFactory.createTenant();
        Property__c firstProperty = RealEstateTestDataFactory.createProperty('Assign 1');
        Property__c secondProperty = RealEstateTestDataFactory.createProperty('Assign 2');

        Test.startTest();
        List<Lease_Agreement__c> draftLeases = TenantController.assignProperties(
            tenant.Id,
            new List<Id>{ firstProperty.Id, secondProperty.Id }
        );
        Test.stopTest();

        System.assertEquals(2, draftLeases.size());
        Set<Id> draftLeaseIds = new Map<Id, Lease_Agreement__c>(draftLeases).keySet();
        System.assertEquals(2, [
            SELECT COUNT()
            FROM Lease_Agreement__c
            WHERE Id IN :draftLeaseIds
            AND Tenant__c = :tenant.Id
            AND Status__c = 'Draft'
        ]);
        System.assertEquals(2, [
            SELECT COUNT()
            FROM Task
            WHERE WhatId = :tenant.Id
            AND Subject = 'Generate Lease Agreement'
        ]);
    }

    @IsTest
    static void createTenantCreatesTrackedContactDetails() {
        Tenant__c tenant = new Tenant__c(Name = 'New Tenant', Phone__c = '9888888881', Email__c = 'newtenant@example.com');

        Test.startTest();
        Id tenantId = TenantController.createTenant(tenant);
        Test.stopTest();

        Tenant__c saved = [SELECT Name, Phone__c, Email__c FROM Tenant__c WHERE Id = :tenantId LIMIT 1];
        System.assertEquals('New Tenant', saved.Name);
        System.assertEquals('9888888881', saved.Phone__c);
        System.assertEquals('newtenant@example.com', saved.Email__c);
    }
}
