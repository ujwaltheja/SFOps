import { LightningElement, track } from 'lwc';

export default class SfopsQualityGateManager extends LightningElement {
    @track gates = [];
    @track showCreateModal = false;
    isLoading = false;

    columns = [
        { label: 'Name', fieldName: 'Name', type: 'text' },
        { label: 'Type', fieldName: 'Type__c', type: 'text' },
        { label: 'Operator', fieldName: 'Threshold_Operator__c', type: 'text' },
        { label: 'Threshold', fieldName: 'Threshold_Value__c', type: 'number' },
        { label: 'On Failure', fieldName: 'On_Failure__c', type: 'text' },
        { label: 'Active', fieldName: 'Is_Active__c', type: 'boolean' }
    ];

    handleOpenCreate() { this.showCreateModal = true; }
    handleCloseCreate() { this.showCreateModal = false; }
}
