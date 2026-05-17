import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchProperties from '@salesforce/apex/PropertyController.searchProperties';
import listRequests from '@salesforce/apex/MaintenanceRequestController.listRequests';
import createRequest from '@salesforce/apex/MaintenanceRequestController.createRequest';

export default class MaintenanceRequestCreate extends LightningElement {
    propertyOptions = [];
    propertyId;
    description;
    createdRequest;
    requests = [];
    columns = [
        { label: 'Request', fieldName: 'recordUrl', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' } },
        { label: 'Property', fieldName: 'propertyName' },
        { label: 'Vendor', fieldName: 'vendorName' },
        { label: 'Status', fieldName: 'Status__c' },
        { label: 'Description', fieldName: 'Description__c' }
    ];

    async connectedCallback() {
        const [page] = await Promise.all([
            searchProperties({ filter: { pageNumber: 1 } }),
            this.loadRequests()
        ]);
        this.propertyOptions = page.records.map((propertyRecord) => ({
            label: propertyRecord.propertyName || propertyRecord.Name,
            value: propertyRecord.propertyId || propertyRecord.Id
        }));
    }

    async loadRequests() {
        const records = await listRequests();
        this.requests = records.map((request) => ({
            ...request,
            propertyName: request.Property__r?.Name,
            vendorName: request.Vendor__r?.Name || 'Unassigned',
            recordUrl: `/lightning/r/Maintenance_Request__c/${request.Id}/view`
        }));
    }

    handleProperty(event) {
        this.propertyId = event.detail.value;
    }

    handleDescription(event) {
        this.description = event.detail.value;
    }

    async saveRequest() {
        try {
            this.createdRequest = await createRequest({ propertyId: this.propertyId, description: this.description });
            const vendorName = this.createdRequest.Vendor__r?.Name || 'a vendor';
            this.dispatchEvent(new ShowToastEvent({ title: 'Request created', message: `Assigned to ${vendorName}.`, variant: 'success' }));
            this.propertyId = null;
            this.description = null;
            await this.loadRequests();
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Unable to create request', message: error.body?.message || error.message, variant: 'error' }));
        }
    }
}
