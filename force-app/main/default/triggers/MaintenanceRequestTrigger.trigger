trigger MaintenanceRequestTrigger on Maintenance_Request__c (before insert) {
    MaintenanceRequestService.assignVendors(Trigger.new);
}
