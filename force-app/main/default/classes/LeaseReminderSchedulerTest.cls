@IsTest
private class LeaseReminderSchedulerTest {
    @IsTest
    static void schedulerSendsThirtyAndOneDayReminders() {
        Tenant__c tenant = RealEstateTestDataFactory.createTenant();
        Property__c propertyRecord = RealEstateTestDataFactory.createProperty('Reminder');
        RealEstateTestDataFactory.createLease(propertyRecord, tenant, Date.today().addDays(30));
        RealEstateTestDataFactory.createLease(propertyRecord, tenant, Date.today().addDays(1));

        Test.startTest();
        LeaseAgreementEmailService.lastEmailMessageCount = 0;
        new LeaseReminderScheduler().execute(null);
        Test.stopTest();

        System.assertEquals(2, LeaseAgreementEmailService.lastEmailMessageCount);
    }
}
