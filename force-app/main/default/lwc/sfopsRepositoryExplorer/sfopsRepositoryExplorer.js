import { LightningElement, wire, track } from 'lwc';
import getRepositories from '@salesforce/apex/SFOpsRepositoryController.getRepositories';
import getBranches from '@salesforce/apex/SFOpsRepositoryController.getBranches';
import getCommits from '@salesforce/apex/SFOpsRepositoryController.getCommits';
import createRepository from '@salesforce/apex/SFOpsRepositoryController.createRepository';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class SfopsRepositoryExplorer extends LightningElement {
    @track repositories = [];
    @track branches = [];
    @track commits = [];
    @track selectedRepoId;
    @track showCreateModal = false;
    isLoading = true;
    wiredRepoResult;
    newRepo = { name: '', strategy: 'Feature', defaultBranch: 'main' };

    strategyOptions = [
        { label: 'Feature Branching', value: 'Feature' },
        { label: 'Release Branching', value: 'Release' },
        { label: 'Trunk Based', value: 'Trunk' }
    ];

    repoColumns = [
        { label: 'Name', fieldName: 'Name', type: 'text' },
        { label: 'Strategy', fieldName: 'Branch_Strategy__c', type: 'text' },
        { label: 'Branches', fieldName: 'Total_Branches__c', type: 'number' },
        { label: 'Commits', fieldName: 'Total_Commits__c', type: 'number' },
        { label: 'Last Commit', fieldName: 'Last_Commit_Date__c', type: 'date' },
        { type: 'action', typeAttributes: { rowActions: [{ label: 'View Branches', name: 'view' }] } }
    ];

    branchColumns = [
        { label: 'Branch', fieldName: 'Name', type: 'text' },
        { label: 'Type', fieldName: 'Type__c', type: 'text' },
        { label: 'Status', fieldName: 'Status__c', type: 'text' },
        { label: 'Merge', fieldName: 'Merge_Status__c', type: 'text' },
        { label: 'Conflicts', fieldName: 'Conflict_Count__c', type: 'number' },
        { type: 'action', typeAttributes: { rowActions: [{ label: 'View Commits', name: 'commits' }] } }
    ];

    @wire(getRepositories)
    wiredRepos(result) {
        this.wiredRepoResult = result;
        this.isLoading = false;
        if (result.data) this.repositories = result.data;
    }

    handleOpenCreate() { this.showCreateModal = true; }
    handleCloseCreate() { this.showCreateModal = false; }
    handleFieldChange(event) { this.newRepo[event.target.dataset.field] = event.target.value; }

    async handleCreate() {
        try {
            await createRepository({ name: this.newRepo.name, branchStrategy: this.newRepo.strategy, defaultBranch: this.newRepo.defaultBranch });
            this.showCreateModal = false;
            await refreshApex(this.wiredRepoResult);
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Repository created', variant: 'success' }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body?.message, variant: 'error' }));
        }
    }

    async handleRepoAction(event) {
        if (event.detail.action.name === 'view') {
            this.selectedRepoId = event.detail.row.Id;
            this.branches = await getBranches({ repositoryId: this.selectedRepoId });
        }
    }

    async handleBranchAction(event) {
        if (event.detail.action.name === 'commits') {
            this.commits = await getCommits({ branchId: event.detail.row.Id, limitCount: 50 });
        }
    }

    get hasBranches() { return this.branches && this.branches.length > 0; }
    get hasCommits() { return this.commits && this.commits.length > 0; }
}
