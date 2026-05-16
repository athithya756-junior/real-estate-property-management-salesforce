public with sharing class ReportingController {
    public class DashboardMetrics {
        @AuraEnabled public Integer expiringLeasesNext30Days;
        @AuraEnabled public Decimal occupancyRate;
        @AuraEnabled public Map<String, Integer> maintenanceByStatus;
    }

    @AuraEnabled(cacheable=true)
    public static DashboardMetrics getMetrics() {
        DashboardMetrics metrics = new DashboardMetrics();
        metrics.expiringLeasesNext30Days = [
            SELECT COUNT()
            FROM Lease_Agreement__c
            WHERE End_Date__c >= :Date.today()
            AND End_Date__c <= :Date.today().addDays(30)
            AND Status__c = 'Active'
        ];

        Integer totalProperties = [SELECT COUNT() FROM Property__c];
        Integer occupiedProperties = [SELECT COUNT() FROM Property__c WHERE Status__c = 'Occupied'];
        metrics.occupancyRate = totalProperties == 0 ? 0 : ((Decimal) occupiedProperties / totalProperties) * 100;

        metrics.maintenanceByStatus = new Map<String, Integer>();
        for (AggregateResult result : [
            SELECT Status__c statusValue, COUNT(Id) requestCount
            FROM Maintenance_Request__c
            GROUP BY Status__c
        ]) {
            metrics.maintenanceByStatus.put((String) result.get('statusValue'), (Integer) result.get('requestCount'));
        }
        return metrics;
    }
}
