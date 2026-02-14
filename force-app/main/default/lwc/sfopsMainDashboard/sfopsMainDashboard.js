import { LightningElement, wire, track } from 'lwc';
import getDashboardData from '@salesforce/apex/SFOpsDashboardController.getDashboardData';
import getRecentDeployments from '@salesforce/apex/SFOpsDashboardController.getRecentDeployments';

export default class SfopsMainDashboard extends LightningElement {
    @track dashboardData = {};
    @track recentDeployments = [];
    @track error;
    isLoading = true;

    deploymentColumns = [
        { label: 'Name', fieldName: 'Name', type: 'text' },
        { label: 'Status', fieldName: 'Status__c', type: 'text' },
        { label: 'Environment', fieldName: 'Target_Environment__c', type: 'text' },
        { label: 'Components', fieldName: 'Total_Components__c', type: 'number' },
        { label: 'Started', fieldName: 'Start_Time__c', type: 'date', typeAttributes: { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' } }
    ];

    @wire(getDashboardData)
    wiredDashboard({ error, data }) {
        this.isLoading = false;
        if (data) { this.dashboardData = data; this.error = undefined; }
        else if (error) { this.error = error.body?.message || 'Failed to load dashboard'; }
    }

    @wire(getRecentDeployments)
    wiredDeployments({ error, data }) {
        if (data) this.recentDeployments = data;
        else if (error) this.error = error.body?.message;
    }

    get environmentCount() { return this.dashboardData.environmentCount || 0; }
    get pipelineCount() { return this.dashboardData.pipelineCount || 0; }
    get openIssues() { return this.dashboardData.openIssues || 0; }
    get activeDebt() { return this.dashboardData.activeDebt || 0; }
    get hasDeployments() { return this.recentDeployments && this.recentDeployments.length > 0; }
    get deploymentStats() {
        const stats = this.dashboardData.deploymentStats || {};
        return { total: stats.total || 0, successful: stats.successful || 0, failed: stats.failed || 0, inProgress: stats.inProgress || 0 };
    }

    handleNavigate(event) {
        this.dispatchEvent(new CustomEvent('navigate', { detail: { target: event.currentTarget.dataset.target } }));
    }
}
