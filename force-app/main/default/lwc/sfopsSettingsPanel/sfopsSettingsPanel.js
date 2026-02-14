import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SfopsSettingsPanel extends LightningElement {
    @track settings = {
        enableAI: true, autoBackup: true, driftDetection: true,
        autoRollback: false, retentionDays: 30, scanSchedule: 'Daily'
    };

    scheduleOptions = [
        { label: 'Daily', value: 'Daily' }, { label: 'Weekly', value: 'Weekly' },
        { label: 'Monthly', value: 'Monthly' }, { label: 'Disabled', value: 'Disabled' }
    ];

    handleToggle(event) { this.settings[event.target.dataset.field] = event.target.checked; }
    handleChange(event) { this.settings[event.target.dataset.field] = event.target.value; }

    handleSave() {
        this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Settings saved', variant: 'success' }));
    }
}
