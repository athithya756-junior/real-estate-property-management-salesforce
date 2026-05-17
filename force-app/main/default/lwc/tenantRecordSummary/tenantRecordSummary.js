import { LightningElement, api } from 'lwc';
import getTenant from '@salesforce/apex/TenantController.getTenant';
import listTenantLeases from '@salesforce/apex/TenantController.listTenantLeases';
import listLeaseGenerationTasks from '@salesforce/apex/TenantController.listLeaseGenerationTasks';

export default class TenantRecordSummary extends LightningElement {
    _recordId;
    tenant;
    leases = [];
    tasks = [];
    errorMessage;
    leaseColumns = [
        { label: 'Lease Agreement', fieldName: 'leaseUrl', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' } },
        { label: 'Property', fieldName: 'propertyUrl', type: 'url', typeAttributes: { label: { fieldName: 'propertyName' }, target: '_blank' } },
        { label: 'Monthly Rent', fieldName: 'Agreed_Monthly_Rent__c', type: 'currency' },
        { label: 'Start Date', fieldName: 'Start_Date__c', type: 'date' },
        { label: 'End Date', fieldName: 'End_Date__c', type: 'date' },
        { label: 'Status', fieldName: 'Status__c' }
    ];
    taskColumns = [
        { label: 'Task', fieldName: 'taskUrl', type: 'url', typeAttributes: { label: { fieldName: 'Subject' }, target: '_blank' } },
        { label: 'Status', fieldName: 'Status' },
        { label: 'Priority', fieldName: 'Priority' },
        { label: 'Due Date', fieldName: 'ActivityDate', type: 'date' },
        { label: 'Instructions', fieldName: 'Description', wrapText: true }
    ];

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.loadTenant();
        }
    }

    async loadTenant() {
        this.errorMessage = undefined;
        try {
            const [tenant, leases, tasks] = await Promise.all([
                getTenant({ tenantId: this.recordId }),
                listTenantLeases({ tenantId: this.recordId }),
                listLeaseGenerationTasks({ tenantId: this.recordId })
            ]);
            this.tenant = tenant;
            this.leases = leases.map((lease) => ({
                ...lease,
                propertyName: lease.Property__r?.Name,
                leaseUrl: `/lightning/r/Lease_Agreement__c/${lease.Id}/view`,
                propertyUrl: lease.Property__c ? `/lightning/r/Property__c/${lease.Property__c}/view` : ''
            }));
            this.tasks = tasks.map((task) => ({
                ...task,
                taskUrl: `/lightning/r/Task/${task.Id}/view`
            }));
        } catch (error) {
            this.tenant = undefined;
            this.leases = [];
            this.tasks = [];
            this.errorMessage = error.body?.message || 'Unable to load tenant details.';
        }
    }
}
