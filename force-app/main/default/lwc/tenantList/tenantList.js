import { LightningElement, wire } from 'lwc';
import listTenants from '@salesforce/apex/TenantController.listTenants';

export default class TenantList extends LightningElement {
    columns = [
        { label: 'Name', fieldName: 'recordUrl', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' } },
        { label: 'Phone', fieldName: 'Phone__c', type: 'phone' },
        { label: 'Email', fieldName: 'Email__c', type: 'email' }
    ];
    tenants = [];

    @wire(listTenants)
    wiredTenants({ data }) {
        if (data) {
            this.tenants = data.map((tenant) => ({ ...tenant, recordUrl: `/lightning/r/Tenant__c/${tenant.Id}/view` }));
        }
    }
}
