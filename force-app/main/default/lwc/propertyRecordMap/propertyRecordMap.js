import { LightningElement, api, wire } from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import geocodeProperty from '@salesforce/apex/PropertyController.geocodeProperty';
import NAME from '@salesforce/schema/Property__c.Name';
import LATITUDE from '@salesforce/schema/Property__c.Location__Latitude__s';
import LONGITUDE from '@salesforce/schema/Property__c.Location__Longitude__s';

export default class PropertyRecordMap extends LightningElement {
    @api recordId;
    mapMarkers = [];
    errorMessage;
    isGeocoding = false;
    hasRequestedGeocode = false;

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
            this.geocodeMissingLocation(data);
            return;
        }

        this.setMapMarker(latitude, longitude, getFieldValue(data, NAME));
    }

    async geocodeMissingLocation(record) {
        if (this.hasRequestedGeocode || this.isGeocoding || !this.recordId) {
            return;
        }

        this.hasRequestedGeocode = true;
        this.isGeocoding = true;
        this.errorMessage = undefined;

        try {
            const location = await geocodeProperty({ propertyId: this.recordId });
            this.setMapMarker(location.latitude, location.longitude, getFieldValue(record, NAME));
        } catch (error) {
            this.mapMarkers = [];
            this.errorMessage = error.body?.message || 'Unable to geocode this property location.';
        } finally {
            this.isGeocoding = false;
        }
    }

    setMapMarker(latitude, longitude, title) {
        this.mapMarkers = [{
            location: { Latitude: latitude, Longitude: longitude },
            title
        }];
    }

    get hasMapMarkers() {
        return this.mapMarkers.length > 0;
    }
}
