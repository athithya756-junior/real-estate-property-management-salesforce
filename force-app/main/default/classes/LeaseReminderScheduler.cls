global with sharing class LeaseReminderScheduler implements Schedulable {
    global void execute(SchedulableContext context) {
        sendRemindersFor(Date.today().addDays(30), 30);
        sendRemindersFor(Date.today().addDays(1), 1);
    }

    @TestVisible
    private static void sendRemindersFor(Date targetDate, Integer daysBeforeExpiry) {
        List<Lease_Agreement__c> agreements = [
            SELECT Id, Name, End_Date__c, Tenant__r.Email__c, Property__r.Name
            FROM Lease_Agreement__c
            WHERE End_Date__c = :targetDate
            AND Status__c = 'Active'
        ];
        LeaseAgreementEmailService.sendReminder(agreements, daysBeforeExpiry);
    }
}
