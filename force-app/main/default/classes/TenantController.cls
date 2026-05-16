public with sharing class TenantController {
    @AuraEnabled(cacheable=true)
    public static List<Tenant__c> listTenants() {
        return [
            SELECT Id, Name, Phone__c, Email__c
            FROM Tenant__c
            ORDER BY Name
            LIMIT 500
        ];
    }
}
