import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import createProperty from '@salesforce/apex/PropertyController.createProperty';

export default class PropertyCreate extends NavigationMixin(LightningElement) {
    files = [];
    isSaving = false;
    isReadingFiles = false;

    get disableSave() {
        return this.isSaving || this.isReadingFiles;
    }

    async handleFiles(event) {
        const selectedFiles = Array.from(event.target.files || event.detail?.files || []);
        this.files = [];

        if (!selectedFiles.length) {
            return;
        }

        this.isReadingFiles = true;
        try {
            this.files = (await Promise.all(selectedFiles.map((file) => this.readFile(file))))
                .filter((file) => file.fileName && file.base64Data);
        } catch (error) {
            this.toast('Unable to read image', error.message, 'error');
        } finally {
            this.isReadingFiles = false;
        }
    }

    readFile(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
                const dataUrl = String(reader.result || '');
                const base64Data = dataUrl.includes(',') ? dataUrl.split(',')[1] : '';
                resolve({
                    fileName: file.name,
                    contentType: file.type || 'application/octet-stream',
                    base64Data
                });
            };
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }

    async handleSubmit(event) {
        event.preventDefault();
        if (this.isReadingFiles) {
            this.toast('Image still loading', 'Please wait a moment and click Create Property again.', 'info');
            return;
        }
        if (!this.files.length) {
            this.toast('Image required', 'Upload at least one property image.', 'error');
            return;
        }

        this.isSaving = true;
        try {
            const propertyId = await createProperty({ propertyRecord: event.detail.fields, files: this.files });
            this.toast('Property created', 'The property and images were saved.', 'success');
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId: propertyId, objectApiName: 'Property__c', actionName: 'view' }
            });
        } catch (error) {
            this.toast('Unable to create property', error.body?.message || error.message, 'error');
        } finally {
            this.isSaving = false;
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
