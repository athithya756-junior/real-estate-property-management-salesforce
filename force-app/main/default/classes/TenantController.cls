public with sharing class TenantController {
    private static final String LEASE_TASK_SUBJECT = 'Generate Lease Agreement';

    @AuraEnabled(cacheable=true)
    public static List<Tenant__c> getTenants() {
        return listTenants();
    }

    @AuraEnabled(cacheable=true)
    public static List<Tenant__c> listTenants() {
        return [
            SELECT Id, Name, Phone__c, Email__c
            FROM Tenant__c
            ORDER BY Name
            LIMIT 500
        ];
    }

    @AuraEnabled
    public static Id createTenant(Tenant__c tenant) {
        if (tenant == null) {
            throw new AuraHandledException('Tenant details are required.');
        }
        if (String.isBlank(tenant.Name)) {
            throw new AuraHandledException('Tenant name is required.');
        }
        insert tenant;
        return tenant.Id;
    }

    @AuraEnabled(cacheable=true)
    public static Tenant__c getTenant(Id tenantId) {
        if (tenantId == null) {
            throw new AuraHandledException('Tenant Id is required.');
        }

        return [
            SELECT Id, Name, Phone__c, Email__c
            FROM Tenant__c
            WHERE Id = :tenantId
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Lease_Agreement__c> listTenantLeases(Id tenantId) {
        if (tenantId == null) {
            throw new AuraHandledException('Tenant Id is required.');
        }

        return [
            SELECT Id, Name, Property__c, Property__r.Name, Agreed_Monthly_Rent__c,
                Start_Date__c, End_Date__c, Status__c
            FROM Lease_Agreement__c
            WHERE Tenant__c = :tenantId
            ORDER BY Start_Date__c DESC, CreatedDate DESC
            LIMIT 500
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Task> listLeaseGenerationTasks(Id tenantId) {
        if (tenantId == null) {
            throw new AuraHandledException('Tenant Id is required.');
        }

        return [
            SELECT Id, Subject, Status, Priority, ActivityDate, Description
            FROM Task
            WHERE WhatId = :tenantId
            AND Subject = :LEASE_TASK_SUBJECT
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];
    }

    @AuraEnabled
    public static List<Lease_Agreement__c> assignProperties(Id tenantId, List<Id> propertyIds) {
        if (tenantId == null) {
            throw new AuraHandledException('Select a tenant.');
        }
        if (propertyIds == null || propertyIds.isEmpty()) {
            throw new AuraHandledException('Select at least one property.');
        }

        List<Property__c> properties = [
            SELECT Id, Name, Rent__c
            FROM Property__c
            WHERE Id IN :propertyIds
            ORDER BY Name
            LIMIT 200
        ];
        if (properties.isEmpty()) {
            throw new AuraHandledException('Selected properties were not found.');
        }

        List<Lease_Agreement__c> draftLeases = new List<Lease_Agreement__c>();
        for (Property__c propertyRecord : properties) {
            draftLeases.add(new Lease_Agreement__c(
                Tenant__c = tenantId,
                Property__c = propertyRecord.Id,
                Terms__c = 'Lease generation pending.',
                Agreed_Monthly_Rent__c = propertyRecord.Rent__c == null ? 0 : propertyRecord.Rent__c,
                Start_Date__c = Date.today(),
                End_Date__c = Date.today().addMonths(12),
                Status__c = 'Draft'
            ));
        }
        insert draftLeases;

        Set<Id> draftLeaseIds = new Map<Id, Lease_Agreement__c>(draftLeases).keySet();
        return [
            SELECT Id, Name, Property__c, Property__r.Name, Agreed_Monthly_Rent__c,
                Start_Date__c, End_Date__c, Status__c
            FROM Lease_Agreement__c
            WHERE Id IN :draftLeaseIds
            ORDER BY CreatedDate DESC
            LIMIT 200
        ];
    }
}
