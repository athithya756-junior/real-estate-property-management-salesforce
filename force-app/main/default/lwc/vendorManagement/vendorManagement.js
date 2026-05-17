import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import listVendors from '@salesforce/apex/VendorController.listVendors';
import createVendor from '@salesforce/apex/VendorController.createVendor';

export default class VendorManagement extends LightningElement {
    vendor = {};
    vendors = [];
    columns = [
        { label: 'Name', fieldName: 'recordUrl', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' } },
        { label: 'Phone Number', fieldName: 'Phone__c', type: 'phone' },
        { label: 'Email', fieldName: 'Email__c', type: 'email' }
    ];

    connectedCallback() {
        this.loadVendors();
    }

    async loadVendors() {
        const records = await listVendors();
        this.vendors = records.map((vendor) => ({
            ...vendor,
            recordUrl: `/lightning/r/Vendor__c/${vendor.Id}/view`
        }));
    }

    handleChange(event) {
        this.vendor = { ...this.vendor, [event.target.dataset.field]: event.detail.value };
    }

    async saveVendor() {
        try {
            await createVendor({ vendor: this.vendor });
            this.dispatchEvent(new ShowToastEvent({ title: 'Vendor created', message: 'Vendor is available for maintenance assignment.', variant: 'success' }));
            this.vendor = {};
            await this.loadVendors();
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Unable to create vendor', message: error.body?.message || error.message, variant: 'error' }));
        }
    }
}
