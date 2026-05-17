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

    get fileSummary() {
        if (!this.files.length) {
            return '';
        }
        return `${this.files.length} image(s) selected: ${this.files.map((file) => file.fileName).join(', ')}`;
    }

    get hasSelectedImages() {
        return this.files.length > 0;
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
            if (this.files.length) {
                this.toast('Images ready', `${this.files.length} image(s) selected.`, 'success');
            }
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
                    key: `${file.name}-${file.size}-${file.lastModified}`,
                    fileName: file.name,
                    contentType: file.type || 'application/octet-stream',
                    base64Data,
                    previewUrl: dataUrl
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
            const files = this.files.map((file) => ({
                fileName: file.fileName,
                contentType: file.contentType,
                base64Data: file.base64Data
            }));
            const propertyId = await createProperty({ propertyRecord: event.detail.fields, files });
            this.toast('Property created', 'The property and images were saved.', 'success');
            this.dispatchEvent(new CustomEvent('propertycreated', { detail: { recordId: propertyId }, bubbles: true, composed: true }));
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
