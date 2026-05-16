import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchProperties from '@salesforce/apex/PropertyController.searchProperties';
import createRequest from '@salesforce/apex/MaintenanceRequestController.createRequest';

export default class MaintenanceRequestCreate extends LightningElement {
    propertyOptions = [];
    propertyId;
    description;
    createdRequest;

    async connectedCallback() {
        const page = await searchProperties({ filter: { pageNumber: 1 } });
        this.propertyOptions = page.records.map((propertyRecord) => ({ label: propertyRecord.Name, value: propertyRecord.Id }));
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
            this.dispatchEvent(new ShowToastEvent({ title: 'Request created', message: `Assigned to ${this.createdRequest.Vendor__r.Name}.`, variant: 'success' }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Unable to create request', message: error.body?.message || error.message, variant: 'error' }));
        }
    }
}
