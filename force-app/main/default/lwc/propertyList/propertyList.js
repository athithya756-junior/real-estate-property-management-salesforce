import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchProperties from '@salesforce/apex/PropertyController.searchProperties';

const COLUMNS = [
    { label: 'Name', fieldName: 'recordUrl', type: 'url', typeAttributes: { label: { fieldName: 'propertyName' }, target: '_blank' } },
    { label: 'City', fieldName: 'city' },
    { label: 'Type', fieldName: 'propertyType' },
    { label: 'Status', fieldName: 'status' },
    { label: 'Furnishing', fieldName: 'furnishingStatus' },
    { label: 'Rent', fieldName: 'rent', type: 'currency' },
    { label: 'Images', fieldName: 'imageCount', type: 'number' }
];

export default class PropertyList extends LightningElement {
    columns = COLUMNS;
    properties = [];
    pageNumber = 1;
    totalRecords = 0;
    pageSize = 25;
    filters = {};
    isLoading = false;
    showPropertyForm = false;

    statusOptions = [
        { label: 'Any', value: '' },
        { label: 'Available', value: 'Available' },
        { label: 'Occupied', value: 'Occupied' }
    ];

    furnishingOptions = [
        { label: 'Any', value: '' },
        { label: 'Furnished', value: 'Furnished' },
        { label: 'Semi-Furnished', value: 'Semi-Furnished' },
        { label: 'Unfurnished', value: 'Unfurnished' }
    ];

    connectedCallback() {
        this.loadProperties();
    }

    get totalPages() {
        return Math.max(1, Math.ceil(this.totalRecords / this.pageSize));
    }

    get disablePrevious() {
        return this.pageNumber <= 1;
    }

    get disableNext() {
        return this.pageNumber >= this.totalPages;
    }

    get newPropertyLabel() {
        return this.showPropertyForm ? 'Hide New Property' : 'New Property';
    }

    handleFilterChange(event) {
        const field = event.target.dataset.field;
        let value = event.detail.value;
        if (['minRent', 'maxRent', 'distanceKm'].includes(field)) {
            value = value === '' || value === null ? null : Number(value);
        }
        this.filters = { ...this.filters, [field]: value };
    }

    async useLocation() {
        try {
            const position = await this.getCurrentPosition();
            this.filters = {
                ...this.filters,
                userLatitude: position.coords.latitude,
                userLongitude: position.coords.longitude
            };
            this.toast('Location captured', 'Nearby filtering will use your current location.', 'success');
            return true;
        } catch (error) {
            this.toast('Location unavailable', error.message || 'Allow browser location access and try again.', 'error');
            return false;
        }
    }

    getCurrentPosition() {
        if (!navigator.geolocation) {
            return Promise.reject(new Error('Browser location is not available.'));
        }
        return new Promise((resolve, reject) => {
            navigator.geolocation.getCurrentPosition(resolve, reject);
        });
    }

    async applyFilters() {
        this.pageNumber = 1;
        if (this.filters.distanceKm && (!this.filters.userLatitude || !this.filters.userLongitude)) {
            const hasLocation = await this.useLocation();
            if (!hasLocation) {
                return;
            }
        }
        await this.loadProperties();
    }

    async loadProperties() {
        this.isLoading = true;
        try {
            const page = await searchProperties({ filter: { ...this.filters, pageNumber: this.pageNumber } });
            this.pageSize = page.pageSize;
            this.totalRecords = page.totalRecords;
            this.properties = page.records.map((record) => this.normalizeProperty(record));
        } catch (error) {
            this.toast('Unable to load properties', error.body?.message || error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    normalizeProperty(record) {
        const propertyId = record.propertyId || record.Id;
        return {
            ...record,
            propertyId,
            propertyName: record.propertyName || record.Name,
            city: record.city || record.City__c,
            propertyType: record.propertyType || record.Type__c,
            status: record.status || record.Status__c,
            furnishingStatus: record.furnishingStatus || record.Furnishing_Status__c,
            rent: record.rent ?? record.Rent__c,
            imageCount: record.imageCount ?? 0,
            recordUrl: propertyId ? `/lightning/r/Property__c/${propertyId}/view` : ''
        };
    }

    clearFilters() {
        this.filters = {};
        this.pageNumber = 1;
        this.loadProperties();
    }

    previousPage() {
        this.pageNumber -= 1;
        this.loadProperties();
    }

    nextPage() {
        this.pageNumber += 1;
        this.loadProperties();
    }

    togglePropertyForm() {
        this.showPropertyForm = !this.showPropertyForm;
    }

    handlePropertyCreated() {
        this.showPropertyForm = false;
        this.pageNumber = 1;
        this.loadProperties();
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
