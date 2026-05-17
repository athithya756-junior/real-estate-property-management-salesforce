public with sharing class VendorAssignmentService {
    private static final Set<String> ACTIVE_STATUSES = new Set<String>{ 'Open', 'In Progress' };

    public static void assignVendors(List<Maintenance_Request__c> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }

        List<Vendor__c> vendors = [
            SELECT Id, Name
            FROM Vendor__c
            ORDER BY Name
            LIMIT 2000
        ];
        if (vendors.isEmpty()) {
            for (Maintenance_Request__c request : requests) {
                if (request.Vendor__c == null) {
                    request.addError('At least one vendor is required before creating a maintenance request.');
                }
            }
            return;
        }

        Map<Id, Integer> workloadByVendor = getActiveWorkloadByVendor(vendors);
        for (Maintenance_Request__c request : requests) {
            if (request.Vendor__c != null) {
                continue;
            }

            Id selectedVendorId = selectLeastLoadedVendor(vendors, workloadByVendor);
            request.Vendor__c = selectedVendorId;
            workloadByVendor.put(selectedVendorId, workloadByVendor.get(selectedVendorId) + 1);
        }
    }

    public static Id getVendorIdWithMinimumActiveRequests() {
        List<Vendor__c> vendors = [
            SELECT Id, Name
            FROM Vendor__c
            ORDER BY Name
            LIMIT 2000
        ];
        if (vendors.isEmpty()) {
            return null;
        }
        return selectLeastLoadedVendor(vendors, getActiveWorkloadByVendor(vendors));
    }

    private static Map<Id, Integer> getActiveWorkloadByVendor(List<Vendor__c> vendors) {
        Map<Id, Integer> workloadByVendor = new Map<Id, Integer>();
        for (Vendor__c vendor : vendors) {
            workloadByVendor.put(vendor.Id, 0);
        }
        Set<Id> vendorIds = workloadByVendor.keySet();

        for (AggregateResult result : [
            SELECT Vendor__c vendorId, COUNT(Id) workload
            FROM Maintenance_Request__c
            WHERE Vendor__c IN :vendorIds
            AND Status__c IN :ACTIVE_STATUSES
            GROUP BY Vendor__c
            LIMIT 2000
        ]) {
            workloadByVendor.put((Id) result.get('vendorId'), (Integer) result.get('workload'));
        }
        return workloadByVendor;
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
