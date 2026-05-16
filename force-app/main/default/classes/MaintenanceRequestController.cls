public with sharing class MaintenanceRequestController {
    @AuraEnabled
    public static Maintenance_Request__c createRequest(Id propertyId, String description) {
        Maintenance_Request__c request = new Maintenance_Request__c(
            Property__c = propertyId,
            Status__c = 'Open',
            Description__c = description
        );
        insert request;
        return [
            SELECT Id, Name, Status__c, Description__c, Property__r.Name, Vendor__c, Vendor__r.Name
            FROM Maintenance_Request__c
            WHERE Id = :request.Id
        ];
    }
}
