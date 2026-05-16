public with sharing class LeaseAgreementEmailService {
    public static void sendLeasePdf(Id agreementId, String pdfBase64) {
        Lease_Agreement__c agreement = LeaseAgreementController.getAgreement(agreementId);
        if (agreement.Tenant__r == null || String.isBlank(agreement.Tenant__r.Email__c)) {
            throw new AuraHandledException('Tenant email is required to send lease agreement.');
        }

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('Lease-' + agreement.Name + '.pdf');
        attachment.setContentType('application/pdf');
        attachment.setBody(EncodingUtil.base64Decode(pdfBase64));

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ agreement.Tenant__r.Email__c });
        email.setSubject('Lease Agreement ' + agreement.Name);
        email.setPlainTextBody('Please find the attached lease agreement for ' + agreement.Property__r.Name + '.');
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }

    public static void sendReminder(List<Lease_Agreement__c> agreements, Integer daysBeforeExpiry) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Lease_Agreement__c agreement : agreements) {
            if (agreement.Tenant__r == null || String.isBlank(agreement.Tenant__r.Email__c)) {
                continue;
            }
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ agreement.Tenant__r.Email__c });
            email.setSubject('Lease agreement expires in ' + daysBeforeExpiry + ' day(s)');
            email.setPlainTextBody(
                'Your lease agreement ' + agreement.Name + ' for ' + agreement.Property__r.Name +
                ' expires on ' + String.valueOf(agreement.End_Date__c) + '.'
            );
            emails.add(email);
        }
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}
