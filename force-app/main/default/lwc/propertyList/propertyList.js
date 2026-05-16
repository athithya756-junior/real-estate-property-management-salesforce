import { LightningElement } from 'lwc';
import searchProperties from '@salesforce/apex/PropertyController.searchProperties';

const COLUMNS = [
    { label: 'Name', fieldName: 'recordUrl', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' } },
    { label: 'City', fieldName: 'City__c' },
    { label: 'Type', fieldName: 'Type__c' },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Furnishing', fieldName: 'Furnishing_Status__c' },
    { label: 'Rent', fieldName: 'Rent__c', type: 'currency' }
];

export default class PropertyList extends LightningElement {
    columns = COLUMNS;
    properties = [];
    pageNumber = 1;
    totalRecords = 0;
    pageSize = 25;
    filters = {};

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

    handleFilterChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;
        this.filters = { ...this.filters, [field]: value };
    }

    async useLocation() {
        const position = await new Promise((resolve, reject) => {
            navigator.geolocation.getCurrentPosition(resolve, reject);
        });
        this.filters = {
            ...this.filters,
            userLatitude: position.coords.latitude,
            userLongitude: position.coords.longitude
        };
    }

    async loadProperties() {
        const page = await searchProperties({ filter: { ...this.filters, pageNumber: this.pageNumber } });
        this.pageSize = page.pageSize;
        this.totalRecords = page.totalRecords;
        this.properties = page.records.map((record) => ({
            ...record,
            recordUrl: `/lightning/r/Property__c/${record.Id}/view`
        }));
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
}
