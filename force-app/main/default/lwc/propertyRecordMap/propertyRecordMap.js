import { LightningElement, api, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import NAME from '@salesforce/schema/Property__c.Name';
import LATITUDE from '@salesforce/schema/Property__c.Location__Latitude__s';
import LONGITUDE from '@salesforce/schema/Property__c.Location__Longitude__s';

export default class PropertyRecordMap extends LightningElement {
    @api recordId;
    mapMarkers = [];
    errorMessage;

    @wire(getRecord, { recordId: '$recordId', fields: [NAME, LATITUDE, LONGITUDE] })
    wiredProperty({ data, error }) {
        if (error) {
            this.mapMarkers = [];
            this.errorMessage = error.body?.message || 'Unable to load property location fields.';
            return;
        }

        if (!data) {
            return;
        }

        this.errorMessage = undefined;
        const latitude = Number(getFieldValue(data, LATITUDE));
        const longitude = Number(getFieldValue(data, LONGITUDE));

        if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
            this.mapMarkers = [];
            return;
        }

        this.mapMarkers = [{
            location: { Latitude: latitude, Longitude: longitude },
            title: getFieldValue(data, NAME)
        }];
    }

    get hasMapMarkers() {
        return this.mapMarkers.length > 0;
    }
}
