import { LightningElement, wire } from 'lwc';
import getMetrics from '@salesforce/apex/ReportingController.getMetrics';

export default class ReportingDashboard extends LightningElement {
    metrics;

    @wire(getMetrics)
    wiredMetrics({ data }) {
        if (data) {
            this.metrics = data;
        }
    }

    get occupancyRate() {
        return this.metrics ? Number(this.metrics.occupancyRate).toFixed(1) : '0.0';
    }

    get statusRows() {
        if (!this.metrics?.maintenanceByStatus) {
            return [];
        }
        return Object.keys(this.metrics.maintenanceByStatus).map((status) => ({
            status,
            count: this.metrics.maintenanceByStatus[status]
        }));
    }
}
