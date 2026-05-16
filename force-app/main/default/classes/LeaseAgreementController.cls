public with sharing class LeaseAgreementController {
    @AuraEnabled(cacheable=true)
    public static List<Lease_Agreement__c> listAgreements() {
        return [
            SELECT Id, Name, Tenant__c, Tenant__r.Name, Tenant__r.Email__c, Property__c, Property__r.Name,
                Terms__c, Agreed_Monthly_Rent__c, Start_Date__c, End_Date__c, Status__c
            FROM Lease_Agreement__c
            ORDER BY End_Date__c ASC
            LIMIT 500
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Lease_Agreement__c getAgreement(Id agreementId) {
        return [
            SELECT Id, Name, Tenant__c, Tenant__r.Name, Tenant__r.Email__c, Property__c, Property__r.Name,
                Property__r.Address__c, Property__r.City__c, Property__r.State__c, Property__r.Postal_Code__c,
                Property__r.Country__c, Terms__c, Agreed_Monthly_Rent__c, Start_Date__c, End_Date__c, Status__c
            FROM Lease_Agreement__c
            WHERE Id = :agreementId
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static Id createAgreement(Lease_Agreement__c agreement) {
        insert agreement;
        return agreement.Id;
    }

    @AuraEnabled
    public static void sendAgreementPdf(Id agreementId, String pdfBase64) {
        LeaseAgreementEmailService.sendLeasePdf(agreementId, pdfBase64);
    }
}
