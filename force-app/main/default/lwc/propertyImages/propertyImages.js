import { LightningElement, api } from 'lwc';
import getPropertyImages from '@salesforce/apex/PropertyController.getPropertyImages';

export default class PropertyImages extends LightningElement {
    _recordId;
    images = [];
    isLoading = false;
    errorMessage;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.loadImages();
        }
    }

    async loadImages() {
        this.isLoading = true;
        this.errorMessage = undefined;
        try {
            this.images = await getPropertyImages({ propertyId: this.recordId });
        } catch (error) {
            this.images = [];
            this.errorMessage = error.body?.message || 'Unable to load property images.';
        } finally {
            this.isLoading = false;
        }
    }

    get hasImages() {
        return this.images.length > 0;
    }

    get showEmptyState() {
        return !this.errorMessage && !this.hasImages;
    }
}
