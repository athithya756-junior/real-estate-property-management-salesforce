import { LightningElement, api } from 'lwc';
import getPropertyLocation from '@salesforce/apex/PropertyController.getPropertyLocation';

export default class PropertyRecordMap extends LightningElement {
    _recordId;
    mapMarkers = [];
    errorMessage;
    isLoading = false;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.loadLocation();
        }
    }

    async loadLocation() {
        if (!this.recordId) {
            return;
        }

        this.isLoading = true;
        this.errorMessage = undefined;

        try {
            const propertyLocation = await getPropertyLocation({ propertyId: this.recordId });
            const latitude = Number(propertyLocation.latitude);
            const longitude = Number(propertyLocation.longitude);

            if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
                this.mapMarkers = [];
                this.errorMessage = 'No geocoded location is available.';
                return;
            }

            this.setMapMarker(latitude, longitude, propertyLocation.propertyName);
        } catch (error) {
            this.mapMarkers = [];
            this.errorMessage = error.body?.message || 'Unable to load this property location.';
        } finally {
            this.isLoading = false;
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
