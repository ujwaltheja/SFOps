import { LightningElement, wire, track } from 'lwc';
import getEnvironments from '@salesforce/apex/SFOpsEnvironmentController.getEnvironments';
import createEnvironment from '@salesforce/apex/SFOpsEnvironmentController.createEnvironment';
import deleteEnvironment from '@salesforce/apex/SFOpsEnvironmentController.deleteEnvironment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class SfopsEnvironmentManager extends LightningElement {
    @track environments = [];
    @track error;
    @track showCreateModal = false;
    isLoading = true;
    wiredEnvResult;
    newEnv = { name: '', type: '', orgId: '', instanceUrl: '' };

    envTypeOptions = [
        { label: 'Production', value: 'Production' }, { label: 'Developer', value: 'Developer' },
        { label: 'QA', value: 'QA' }, { label: 'Staging', value: 'Staging' },
        { label: 'Integration', value: 'Integration' }, { label: 'Scratch', value: 'Scratch' }
    ];

    columns = [
        { label: 'Name', fieldName: 'Name', type: 'text' },
        { label: 'Type', fieldName: 'Type__c', type: 'text' },
        { label: 'Status', fieldName: 'Auth_Status__c', type: 'text' },
        { label: 'Org ID', fieldName: 'Org_Id__c', type: 'text' },
        { label: 'Components', fieldName: 'Metadata_Count__c', type: 'number' },
        { label: 'Last Sync', fieldName: 'Last_Sync_Date__c', type: 'date', typeAttributes: { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' } },
        { type: 'action', typeAttributes: { rowActions: [{ label: 'View', name: 'view' }, { label: 'Sync', name: 'sync' }, { label: 'Delete', name: 'delete' }] } }
    ];

    @wire(getEnvironments)
    wiredEnvironments(result) {
        this.wiredEnvResult = result;
        this.isLoading = false;
        if (result.data) { this.environments = result.data; this.error = undefined; }
        else if (result.error) { this.error = result.error.body?.message; }
    }

    handleOpenCreate() { this.showCreateModal = true; }
    handleCloseCreate() { this.showCreateModal = false; }
    handleFieldChange(event) { this.newEnv[event.target.dataset.field] = event.target.value; }

    async handleCreateEnvironment() {
        try {
            await createEnvironment({ name: this.newEnv.name, envType: this.newEnv.type, orgId: this.newEnv.orgId, instanceUrl: this.newEnv.instanceUrl });
            this.showCreateModal = false;
            this.newEnv = { name: '', type: '', orgId: '', instanceUrl: '' };
            await refreshApex(this.wiredEnvResult);
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Environment created', variant: 'success' }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body?.message || 'Failed', variant: 'error' }));
        }
    }

    async handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;
        if (action === 'delete') {
            try {
                await deleteEnvironment({ environmentId: row.Id });
                await refreshApex(this.wiredEnvResult);
                this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Environment deleted', variant: 'success' }));
            } catch (error) {
                this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body?.message, variant: 'error' }));
            }
        }
    }
}
