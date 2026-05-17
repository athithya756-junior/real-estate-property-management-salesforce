@IsTest
private class ReportingControllerTest {
    @IsTest
    static void metricsReturnDashboardValues() {
        Vendor__c vendor = RealEstateTestDataFactory.createVendor('Report');
        Tenant__c tenant = RealEstateTestDataFactory.createTenant();
        Property__c availableProperty = RealEstateTestDataFactory.createProperty('Available');
        Property__c occupiedProperty = RealEstateTestDataFactory.createProperty('Occupied');
        occupiedProperty.Status__c = 'Occupied';
        update occupiedProperty;

        RealEstateTestDataFactory.createLease(occupiedProperty, tenant, Date.today().addDays(20));
        insert new Maintenance_Request__c(
            Property__c = availableProperty.Id,
            Vendor__c = vendor.Id,
            Status__c = 'Open',
            Description__c = 'Report request'
        );

        ReportingController.DashboardMetrics metrics = ReportingController.getMetrics();

        System.assertEquals(1, metrics.expiringLeasesNext30Days);
        System.assertEquals(Decimal.valueOf('50.0'), metrics.occupancyRate.setScale(1));
        System.assertEquals(1, metrics.maintenanceByStatus.get('Open'));
    }
}
