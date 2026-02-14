import { LightningElement, wire, track } from 'lwc';
import getNotifications from '@salesforce/apex/SFOpsDashboardController.getNotifications';
import markNotificationRead from '@salesforce/apex/SFOpsDashboardController.markNotificationRead';
import { refreshApex } from '@salesforce/apex';

export default class SfopsNotificationCenter extends LightningElement {
    @track notifications = [];
    wiredResult;

    @wire(getNotifications)
    wiredNotifications(result) {
        this.wiredResult = result;
        if (result.data) this.notifications = result.data;
    }

    get hasNotifications() { return this.notifications && this.notifications.length > 0; }
    get notificationCount() { return this.notifications ? this.notifications.length : 0; }
    get badgeLabel() { return this.notificationCount > 0 ? String(this.notificationCount) : ''; }

    async handleMarkRead(event) {
        const notifId = event.currentTarget.dataset.id;
        await markNotificationRead({ notificationId: notifId });
        await refreshApex(this.wiredResult);
    }
}
