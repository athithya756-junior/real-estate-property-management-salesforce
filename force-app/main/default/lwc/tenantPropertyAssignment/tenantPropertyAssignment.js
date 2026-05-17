import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import listTenants from '@salesforce/apex/TenantController.listTenants';
import listTenantLeases from '@salesforce/apex/TenantController.listTenantLeases';
import assignProperties from '@salesforce/apex/TenantController.assignProperties';
import searchProperties from '@salesforce/apex/PropertyController.searchProperties';

export default class TenantPropertyAssignment extends LightningElement {
    tenantOptions = [];
    propertyOptions = [];
    selectedPropertyIds = [];
    tenantId;
    leases = [];
    isSaving = false;
    columns = [
        { label: 'Lease Agreement', fieldName: 'leaseUrl', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' } },
        { label: 'Property', fieldName: 'propertyUrl', type: 'url', typeAttributes: { label: { fieldName: 'propertyName' }, target: '_blank' } },
        { label: 'Monthly Rent', fieldName: 'Agreed_Monthly_Rent__c', type: 'currency' },
        { label: 'Start Date', fieldName: 'Start_Date__c', type: 'date' },
        { label: 'End Date', fieldName: 'End_Date__c', type: 'date' },
        { label: 'Status', fieldName: 'Status__c' }
    ];

    connectedCallback() {
        this.loadOptions();
    }

    get disableAssign() {
        return this.isSaving || !this.tenantId || !this.selectedPropertyIds.length;
    }

    async loadOptions() {
        try {
            const [tenants, propertyPage] = await Promise.all([
                listTenants(),
                searchProperties({ filter: { pageNumber: 1 } })
            ]);
            this.tenantOptions = tenants.map((tenant) => ({ label: tenant.Name, value: tenant.Id }));
            this.propertyOptions = propertyPage.records.map((propertyRecord) => ({
                label: propertyRecord.propertyName || propertyRecord.Name,
                value: propertyRecord.propertyId || propertyRecord.Id
            }));
        } catch (error) {
            this.toast('Unable to load assignment options', error.body?.message || error.message, 'error');
        }
    }

    async handleTenantChange(event) {
        this.tenantId = event.detail.value;
        this.selectedPropertyIds = [];
        await this.loadAssignedProperties();
    }

    handlePropertyChange(event) {
        this.selectedPropertyIds = event.detail.value;
    }

    async assignSelectedProperties() {
        this.isSaving = true;
        try {
            await assignProperties({ tenantId: this.tenantId, propertyIds: this.selectedPropertyIds });
            this.toast('Properties assigned', 'Draft lease agreements and generation tasks were created.', 'success');
            this.selectedPropertyIds = [];
            await this.loadAssignedProperties();
        } catch (error) {
            this.toast('Unable to assign properties', error.body?.message || error.message, 'error');
        } finally {
            this.isSaving = false;
        }
    }

    async loadAssignedProperties() {
        if (!this.tenantId) {
            this.leases = [];
            return;
        }
        const records = await listTenantLeases({ tenantId: this.tenantId });
        this.leases = records.map((lease) => ({
            ...lease,
            propertyName: lease.Property__r?.Name,
            leaseUrl: `/lightning/r/Lease_Agreement__c/${lease.Id}/view`,
            propertyUrl: lease.Property__c ? `/lightning/r/Property__c/${lease.Property__c}/view` : ''
        }));
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
