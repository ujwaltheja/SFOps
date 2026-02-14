import { LightningElement, wire, track } from 'lwc';
import getRecentScans from '@salesforce/apex/SFOpsScanController.getRecentScans';
import initiateScan from '@salesforce/apex/SFOpsScanController.initiateScan';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class SfopsScanDashboard extends LightningElement {
    @track scans = [];
    @track showScanModal = false;
    isLoading = true;
    wiredResult;
    scanType = 'Full';
    scanTarget = 'Org';

    scanTypeOptions = [
        { label: 'Full Scan', value: 'Full' }, { label: 'Quality', value: 'Quality' },
        { label: 'Security', value: 'Security' }, { label: 'Compliance', value: 'Compliance' }
    ];
    targetOptions = [
        { label: 'Org', value: 'Org' }, { label: 'Branch', value: 'Branch' }, { label: 'Component', value: 'Component' }
    ];

    columns = [
        { label: 'Scan #', fieldName: 'Name', type: 'text' },
        { label: 'Type', fieldName: 'Type__c', type: 'text' },
        { label: 'Status', fieldName: 'Status__c', type: 'text' },
        { label: 'Issues', fieldName: 'Total_Issues__c', type: 'number' },
        { label: 'Critical', fieldName: 'Critical_Count__c', type: 'number' },
        { label: 'Quality', fieldName: 'Quality_Score__c', type: 'number', typeAttributes: { maximumFractionDigits: 1 } },
        { label: 'Date', fieldName: 'Start_Time__c', type: 'date' }
    ];

    @wire(getRecentScans, { limitCount: 20 })
    wiredScans(result) {
        this.wiredResult = result;
        this.isLoading = false;
        if (result.data) this.scans = result.data;
    }

    handleOpenScan() { this.showScanModal = true; }
    handleCloseScan() { this.showScanModal = false; }
    handleTypeChange(event) { this.scanType = event.detail.value; }
    handleTargetChange(event) { this.scanTarget = event.detail.value; }

    async handleStartScan() {
        try {
            await initiateScan({ scanType: this.scanType, target: this.scanTarget, environmentId: null, branchId: null });
            this.showScanModal = false;
            await refreshApex(this.wiredResult);
            this.dispatchEvent(new ShowToastEvent({ title: 'Scan Started', message: 'Scan has been queued', variant: 'success' }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body?.message, variant: 'error' }));
        }
    }
}
