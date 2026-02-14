import { LightningElement, wire, track } from 'lwc';
import getActiveDebtItems from '@salesforce/apex/SFOpsDebtController.getActiveDebtItems';
import getDebtSummary from '@salesforce/apex/SFOpsDebtController.getDebtSummary';
import remediateDebt from '@salesforce/apex/SFOpsDebtController.remediateDebt';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class SfopsDebtDashboard extends LightningElement {
    @track debtItems = [];
    @track summary = {};
    isLoading = true;
    wiredItemsResult;

    columns = [
        { label: 'ID', fieldName: 'Name', type: 'text' },
        { label: 'Component', fieldName: 'Component_Name__c', type: 'text' },
        { label: 'Type', fieldName: 'Debt_Type__c', type: 'text' },
        { label: 'Priority', fieldName: 'Priority__c', type: 'text' },
        { label: 'Hours', fieldName: 'Estimated_Hours__c', type: 'number' },
        { label: 'Status', fieldName: 'Status__c', type: 'text' },
        { type: 'action', typeAttributes: { rowActions: [{ label: 'Remediate', name: 'remediate' }, { label: 'Defer', name: 'defer' }] } }
    ];

    @wire(getActiveDebtItems, { limitCount: 100 })
    wiredItems(result) {
        this.wiredItemsResult = result;
        this.isLoading = false;
        if (result.data) this.debtItems = result.data;
    }

    @wire(getDebtSummary)
    wiredSummary({ data }) { if (data) this.summary = data; }

    get totalActive() { return this.summary.totalActive || 0; }
    get totalHours() { return this.summary.totalHours || 0; }

    async handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;
        if (action === 'remediate') {
            try {
                await remediateDebt({ debtId: row.Id });
                await refreshApex(this.wiredItemsResult);
                this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Debt item remediated', variant: 'success' }));
            } catch (error) {
                this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body?.message, variant: 'error' }));
            }
        }
    }
}
