import { LightningElement, wire, track } from 'lwc';
import getPipelines from '@salesforce/apex/SFOpsPipelineController.getPipelines';
import createPipeline from '@salesforce/apex/SFOpsPipelineController.createPipeline';
import getPipelineWithStages from '@salesforce/apex/SFOpsPipelineController.getPipelineWithStages';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class SfopsPipelineBuilder extends LightningElement {
    @track pipelines = [];
    @track selectedPipeline;
    @track showCreateModal = false;
    isLoading = true;
    wiredResult;
    newPipeline = { name: '', description: '', type: 'Standard' };

    typeOptions = [
        { label: 'Standard', value: 'Standard' }, { label: 'Canary', value: 'Canary' },
        { label: 'Blue/Green', value: 'BlueGreen' }, { label: 'Rolling', value: 'Rolling' }
    ];

    columns = [
        { label: 'Name', fieldName: 'Name', type: 'text' },
        { label: 'Type', fieldName: 'Type__c', type: 'text' },
        { label: 'Status', fieldName: 'Status__c', type: 'text' },
        { label: 'Stages', fieldName: 'Total_Stages__c', type: 'number' },
        { label: 'Success Rate', fieldName: 'Success_Rate__c', type: 'percent', typeAttributes: { maximumFractionDigits: 1 } },
        { label: 'Last Run', fieldName: 'Last_Run_Date__c', type: 'date' },
        { type: 'action', typeAttributes: { rowActions: [{ label: 'View Stages', name: 'view' }, { label: 'Execute', name: 'execute' }] } }
    ];

    @wire(getPipelines)
    wiredPipelines(result) {
        this.wiredResult = result;
        this.isLoading = false;
        if (result.data) { this.pipelines = result.data; }
        else if (result.error) { this.error = result.error.body?.message; }
    }

    handleOpenCreate() { this.showCreateModal = true; }
    handleCloseCreate() { this.showCreateModal = false; }
    handleFieldChange(event) { this.newPipeline[event.target.dataset.field] = event.target.value; }

    async handleCreate() {
        try {
            await createPipeline({ name: this.newPipeline.name, description: this.newPipeline.description, pipelineType: this.newPipeline.type });
            this.showCreateModal = false;
            this.newPipeline = { name: '', description: '', type: 'Standard' };
            await refreshApex(this.wiredResult);
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Pipeline created', variant: 'success' }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body?.message, variant: 'error' }));
        }
    }

    async handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;
        if (action === 'view') { this.selectedPipeline = await getPipelineWithStages({ pipelineId: row.Id }); }
    }

    get hasSelectedPipeline() { return this.selectedPipeline != null; }
    get pipelineStages() { return this.selectedPipeline?.Pipeline_Stages__r || []; }
}
