import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import listAgreements from '@salesforce/apex/LeaseAgreementController.listAgreements';
import createAgreement from '@salesforce/apex/LeaseAgreementController.createAgreement';
import listTenants from '@salesforce/apex/TenantController.listTenants';
import searchProperties from '@salesforce/apex/PropertyController.searchProperties';

export default class LeaseAgreementList extends LightningElement {
    agreements = [];
    tenantOptions = [];
    propertyOptions = [];
    agreement = { Status__c: 'Active' };
    columns = [
        { label: 'Agreement', fieldName: 'recordUrl', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' } },
        { label: 'Tenant', fieldName: 'tenantName' },
        { label: 'Property', fieldName: 'propertyName' },
        { label: 'Rent', fieldName: 'Agreed_Monthly_Rent__c', type: 'currency' },
        { label: 'End Date', fieldName: 'End_Date__c', type: 'date' },
        { label: 'Status', fieldName: 'Status__c' }
    ];
    statusOptions = [
        { label: 'Draft', value: 'Draft' },
        { label: 'Active', value: 'Active' },
        { label: 'Expired', value: 'Expired' },
        { label: 'Terminated', value: 'Terminated' }
    ];

    connectedCallback() {
        this.loadOptions();
        this.loadAgreements();
    }

    async loadOptions() {
        const [tenants, propertyPage] = await Promise.all([
            listTenants(),
            searchProperties({ filter: { pageNumber: 1 } })
        ]);
        this.tenantOptions = tenants.map((tenant) => ({ label: tenant.Name, value: tenant.Id }));
        this.propertyOptions = propertyPage.records.map((propertyRecord) => ({
            label: propertyRecord.propertyName || propertyRecord.Name,
            value: propertyRecord.propertyId || propertyRecord.Id
        }));
    }

    async loadAgreements() {
        const records = await listAgreements();
        this.agreements = records.map((agreement) => ({
            ...agreement,
            tenantName: agreement.Tenant__r?.Name,
            propertyName: agreement.Property__r?.Name,
            recordUrl: `/lightning/r/Lease_Agreement__c/${agreement.Id}/view`
        }));
    }

    handleChange(event) {
        this.agreement = { ...this.agreement, [event.target.dataset.field]: event.detail.value };
    }

    async saveAgreement() {
        try {
            await createAgreement({ agreement: this.agreement });
            this.dispatchEvent(new ShowToastEvent({ title: 'Lease created', message: 'Task was also created for lease generation.', variant: 'success' }));
            this.agreement = { Status__c: 'Active' };
            await this.loadAgreements();
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Unable to create lease', message: error.body?.message || error.message, variant: 'error' }));
        }
    }
}
