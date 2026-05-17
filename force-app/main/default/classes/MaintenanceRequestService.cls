public with sharing class MaintenanceRequestService {
    public static void assignVendors(List<Maintenance_Request__c> requests) {
        VendorAssignmentService.assignVendors(requests);
    }
}
