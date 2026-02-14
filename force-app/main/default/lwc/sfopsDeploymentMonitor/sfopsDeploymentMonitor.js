import { LightningElement, api, track } from 'lwc';
import getDeployment from '@salesforce/apex/SFOpsPipelineController.getDeployment';
import cancelDeployment from '@salesforce/apex/SFOpsPipelineController.cancelDeployment';
import { subscribe, unsubscribe } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SfopsDeploymentMonitor extends LightningElement {
    @api recordId;
    @track deployment = {};
    @track progressEvents = [];
    @track error;
    subscription = {};
    channelName = '/event/Deployment_Progress__e';

    connectedCallback() {
        if (this.recordId) this.loadDeployment();
        this.subscribeToEvents();
    }
    disconnectedCallback() { if (this.subscription) unsubscribe(this.subscription); }

    async loadDeployment() {
        try { this.deployment = await getDeployment({ deploymentId: this.recordId }); }
        catch (error) { this.error = error.body?.message; }
    }

    subscribeToEvents() {
        subscribe(this.channelName, -1, (message) => {
            const event = message.data.payload;
            if (event.Deployment_Id__c === this.recordId) {
                this.progressEvents = [event, ...this.progressEvents].slice(0, 50);
                if (event.Status__c === 'Success' || event.Status__c === 'Failed') this.loadDeployment();
            }
        }).then(response => { this.subscription = response; });
    }

    async handleCancel() {
        try {
            await cancelDeployment({ deploymentId: this.recordId });
            this.loadDeployment();
            this.dispatchEvent(new ShowToastEvent({ title: 'Cancelled', message: 'Deployment cancelled', variant: 'warning' }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body?.message, variant: 'error' }));
        }
    }

    get isInProgress() { return ['Pending', 'Queued', 'InProgress', 'Validating', 'Testing'].includes(this.deployment.Status__c); }
    get hasEvents() { return this.progressEvents.length > 0; }
}
