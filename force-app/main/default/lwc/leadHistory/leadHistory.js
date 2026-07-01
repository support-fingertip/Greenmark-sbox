import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getLeadHistory from '@salesforce/apex/LeadHistoryController.getLeadHistory';

export default class LeadHistory extends LightningElement {
    @api recordId;

    phone;
    leads = [];
    error;
    _wiredResult;

    @wire(getLeadHistory, { recordId: '$recordId' })
    wiredLeads(result) {
        this._wiredResult = result;
        if (result.data) {
            this.phone = result.data.phone;
            this.leads = result.data.leads || [];
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.leads = [];
        }
    }

    get hasLeads() {
        return this.leads && this.leads.length > 0;
    }

    get isEmpty() {
        return !this.error && !this.hasLeads;
    }

    get count() {
        return this.leads ? this.leads.length : 0;
    }

    get subtitle() {
        return this.phone
            ? 'Showing all leads with the same phone number: ' + this.phone
            : 'This lead has no phone number.';
    }

    get footer() {
        return this.count + ' previous lead(s) found with the same phone number.';
    }

    handleRefresh() {
        return refreshApex(this._wiredResult);
    }
}