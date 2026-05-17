import { LightningElement, api } from 'lwc';
import listLeaseTasks from '@salesforce/apex/LeaseAgreementController.listLeaseTasks';

export default class LeaseAgreementTasks extends LightningElement {
    _recordId;
    tasks = [];
    errorMessage;
    columns = [
        { label: 'Task', fieldName: 'taskUrl', type: 'url', typeAttributes: { label: { fieldName: 'Subject' }, target: '_blank' } },
        { label: 'Status', fieldName: 'Status' },
        { label: 'Priority', fieldName: 'Priority' },
        { label: 'Due Date', fieldName: 'ActivityDate', type: 'date' }
    ];

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.loadTasks();
        }
    }

    async loadTasks() {
        this.errorMessage = undefined;
        try {
            const records = await listLeaseTasks({ agreementId: this.recordId });
            this.tasks = records.map((task) => ({
                ...task,
                taskUrl: `/lightning/r/Task/${task.Id}/view`
            }));
        } catch (error) {
            this.tasks = [];
            this.errorMessage = error.body?.message || 'Unable to load lease tasks.';
        }
    }

    get hasTasks() {
        return this.tasks.length > 0;
    }

    get showEmptyState() {
        return !this.errorMessage && !this.hasTasks;
    }
}
