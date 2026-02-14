import { LightningElement, wire, track } from 'lwc';
import getReports from '@salesforce/apex/SFOpsComplianceController.getReports';
import generateReport from '@salesforce/apex/SFOpsComplianceController.generateReport';
import getAlerts from '@salesforce/apex/SFOpsComplianceController.getAlerts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class SfopsComplianceDashboard extends LightningElement {
    @track reports = [];
    @track alerts = [];
    @track showGenerateModal = false;
    isLoading = true;
    wiredReportsResult;
    reportType = 'SOX';
    periodStart;
    periodEnd;

    reportTypeOptions = [
        { label: 'SOX', value: 'SOX' }, { label: 'HIPAA', value: 'HIPAA' },
        { label: 'GDPR', value: 'GDPR' }, { label: 'PCI', value: 'PCI' },
        { label: 'Custom', value: 'Custom' }
    ];

    reportColumns = [
        { label: 'Report #', fieldName: 'Name', type: 'text' },
        { label: 'Type', fieldName: 'Type__c', type: 'text' },
        { label: 'Period', fieldName: 'Period_Start__c', type: 'date' },
        { label: 'Status', fieldName: 'Status__c', type: 'text' },
        { label: 'Deployments', fieldName: 'Total_Deployments__c', type: 'number' }
    ];

    alertColumns = [
        { label: 'Alert', fieldName: 'Name', type: 'text' },
        { label: 'Type', fieldName: 'Alert_Type__c', type: 'text' },
        { label: 'Severity', fieldName: 'Severity__c', type: 'text' },
        { label: 'Status', fieldName: 'Status__c', type: 'text' },
        { label: 'Detected', fieldName: 'Detected_At__c', type: 'date' }
    ];

    @wire(getReports, { limitCount: 20 })
    wiredReports(result) {
        this.wiredReportsResult = result;
        this.isLoading = false;
        if (result.data) this.reports = result.data;
    }

    @wire(getAlerts, { environmentId: null, limitCount: 20 })
    wiredAlerts({ data }) { if (data) this.alerts = data; }

    handleOpenGenerate() { this.showGenerateModal = true; }
    handleCloseGenerate() { this.showGenerateModal = false; }
    handleTypeChange(event) { this.reportType = event.detail.value; }
    handleStartChange(event) { this.periodStart = event.detail.value; }
    handleEndChange(event) { this.periodEnd = event.detail.value; }
    get hasAlerts() { return this.alerts && this.alerts.length > 0; }

    async handleGenerate() {
        try {
            await generateReport({ reportType: this.reportType, periodStart: this.periodStart, periodEnd: this.periodEnd });
            this.showGenerateModal = false;
            await refreshApex(this.wiredReportsResult);
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Report generated', variant: 'success' }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body?.message, variant: 'error' }));
        }
    }
}
