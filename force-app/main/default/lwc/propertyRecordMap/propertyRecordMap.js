import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import NAME from '@salesforce/schema/Property__c.Name';
import LATITUDE from '@salesforce/schema/Property__c.Location__Latitude__s';
import LONGITUDE from '@salesforce/schema/Property__c.Location__Longitude__s';

export default class PropertyRecordMap extends LightningElement {
    @api recordId;
    mapMarkers = [];

    @wire(getRecord, { recordId: '$recordId', fields: [NAME, LATITUDE, LONGITUDE] })
    wiredProperty({ data }) {
        if (!data) {
            return;
        }
        const latitude = data.fields.Location__Latitude__s.value;
        const longitude = data.fields.Location__Longitude__s.value;
        if (latitude && longitude) {
            this.mapMarkers = [{
                location: { Latitude: latitude, Longitude: longitude },
                title: data.fields.Name.value
            }];
        }
    }
}
