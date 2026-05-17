import { LightningElement } from 'lwc';

export default class PropertyForm extends LightningElement {
    handlePropertyCreated(event) {
        this.dispatchEvent(new CustomEvent('propertycreated', { detail: event.detail, bubbles: true, composed: true }));
    }
}
