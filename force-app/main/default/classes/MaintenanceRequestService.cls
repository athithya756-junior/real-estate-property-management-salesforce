public with sharing class MaintenanceRequestService {
    private static final Set<String> ACTIVE_STATUSES = new Set<String>{ 'Open', 'In Progress' };

    public static void assignVendors(List<Maintenance_Request__c> requests) {
        List<Vendor__c> vendors = [SELECT Id, Name FROM Vendor__c ORDER BY Name];
        if (vendors.isEmpty()) {
            return;
        }

        Map<Id, Integer> workloadByVendor = new Map<Id, Integer>();
        for (Vendor__c vendor : vendors) {
            workloadByVendor.put(vendor.Id, 0);
        }

        for (AggregateResult result : [
            SELECT Vendor__c vendorId, COUNT(Id) workload
            FROM Maintenance_Request__c
            WHERE Vendor__c != null
            AND Status__c IN :ACTIVE_STATUSES
            GROUP BY Vendor__c
        ]) {
            workloadByVendor.put((Id) result.get('vendorId'), (Integer) result.get('workload'));
        }

        for (Maintenance_Request__c request : requests) {
            if (request.Vendor__c != null) {
                continue;
            }
            Id selectedVendorId = selectLeastLoadedVendor(vendors, workloadByVendor);
            request.Vendor__c = selectedVendorId;
            workloadByVendor.put(selectedVendorId, workloadByVendor.get(selectedVendorId) + 1);
        }
    }

    private static Id selectLeastLoadedVendor(List<Vendor__c> vendors, Map<Id, Integer> workloadByVendor) {
        Id selectedVendorId = vendors[0].Id;
        Integer selectedWorkload = workloadByVendor.get(selectedVendorId);
        for (Vendor__c vendor : vendors) {
            Integer workload = workloadByVendor.get(vendor.Id);
            if (workload < selectedWorkload) {
                selectedVendorId = vendor.Id;
                selectedWorkload = workload;
            }
        }
        return selectedVendorId;
    }
}
