public with sharing class VendorController {
    @AuraEnabled
    public static List<Vendor__c> listVendors() {
        return [
            SELECT Id, Name, Phone__c, Email__c
            FROM Vendor__c
            ORDER BY Name
            LIMIT 500
        ];
    }

    @AuraEnabled
    public static Id createVendor(Vendor__c vendor) {
        if (vendor == null || String.isBlank(vendor.Name)) {
            throw new AuraHandledException('Enter a vendor name.');
        }

        insert vendor;
        return vendor.Id;
    }
}
