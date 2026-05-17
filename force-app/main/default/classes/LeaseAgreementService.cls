public with sharing class LeaseAgreementService {
    private static final String TASK_SUBJECT = 'Generate Lease Agreement';

    public static void handleAfterInsert(List<Lease_Agreement__c> agreements) {
        createLeaseGenerationTasks(agreements);
        markPropertiesOccupied(agreements);
    }

    private static void createLeaseGenerationTasks(List<Lease_Agreement__c> agreements) {
        List<Task> tasks = new List<Task>();
        for (Lease_Agreement__c agreement : agreements) {
            if (agreement.Tenant__c == null) {
                continue;
            }
            tasks.add(new Task(
                WhatId = agreement.Tenant__c,
                Subject = TASK_SUBJECT,
                Status = 'Not Started',
                Priority = 'Normal',
                ActivityDate = Date.today().addDays(1),
                Description = 'Generate Lease Agreement for this tenant. Draft lease: /lightning/r/Lease_Agreement__c/' + agreement.Id + '/view' +
                    (agreement.Property__c == null ? '' : ' and property ' + agreement.Property__c) +
                    '. Complete the agreement details before sending the PDF.'
            ));
        }
        if (!tasks.isEmpty()) {
            insert tasks;
        }
    }

    private static void markPropertiesOccupied(List<Lease_Agreement__c> agreements) {
        Map<Id, Property__c> propertiesById = new Map<Id, Property__c>();
        for (Lease_Agreement__c agreement : agreements) {
            if (agreement.Property__c != null && agreement.Status__c == 'Active') {
                propertiesById.put(agreement.Property__c, new Property__c(
                    Id = agreement.Property__c,
                    Status__c = 'Occupied'
                ));
            }
        }
        if (!propertiesById.isEmpty()) {
            update propertiesById.values();
        }
    }
}
