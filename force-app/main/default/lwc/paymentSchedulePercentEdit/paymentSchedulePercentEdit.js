import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import getSchedules from '@salesforce/apex/PaymentSchedulePercentEditController.getSchedules';
import saveSchedules from '@salesforce/apex/PaymentSchedulePercentEditController.saveSchedules';

export default class PaymentSchedulePercentEdit extends LightningElement {
    @api recordId; // Payment_schedule__c Id the quick action was launched from

    @track rows = [];
    @track loading = true;
    @track saving = false;

    bookingId;
    bookingName;
    bookingTotal = 0;
    landTotal = 0;
    constTotal = 0;
    projectType = '';
    expectedTotal = 100;

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        this.loading = true;
        getSchedules({ recordId: this.recordId })
            .then(result => {
                const booking = result.booking || {};
                this.bookingId = booking.Id;
                this.bookingName = booking.Name;
                this.bookingTotal = booking.Total_Amount__c || 0;
                this.landTotal = booking.Total_Land_Amount__c || 0;
                this.constTotal = booking.Construction_Cost__c || 0;
                this.projectType = booking.Project_Type__c || '';
                this.expectedTotal = result.expectedTotal;

                const schedules = result.schedules || [];
                this.rows = schedules.map(s => this.buildRow(s));
            })
            .catch(error => {
                this.showError('Load failed', this.reduceError(error));
            })
            .finally(() => {
                this.loading = false;
            });
    }

    buildRow(s) {
        const pct = s.Payment_percent__c == null ? 0 : Number(s.Payment_percent__c);
        const received = s.Received_Amount1__c == null ? 0 : Number(s.Received_Amount1__c);
        const amount = this.calcAmount(pct, s.Type__c);
        const isDemanded = !!s.Is_Demanded__c;
        return {
            id: s.Id,
            name: s.Name,
            sNo: s.S_No__c,
            type: s.Type__c,
            originalPct: pct,
            pct: pct,
            amount: amount,
            received: received,
            isDemanded: isDemanded,
            disabled: isDemanded,
            errorMsg: '',
            statusLabel: isDemanded ? 'Demanded' : 'Not Demanded',
            statusClass: isDemanded
                ? 'slds-theme_success slds-m-left_xx-small'
                : 'slds-theme_info slds-m-left_xx-small',
            rowClass: isDemanded ? 'ps-row-disabled' : ''
        };
    }

    calcAmount(pct, type) {
        const n = Number(pct) || 0;
        let base = this.bookingTotal;
        if (this.projectType === 'Villas') {
            if (type === 'Land') {
                base = this.landTotal;
            } else if (type === 'Construction') {
                base = this.constTotal;
            }
        }
        return Math.round(((base * n) / 100) * 100) / 100;
    }

    handlePctChange(event) {
        const id = event.target.dataset.id;
        const raw = event.target.value;
        const newPct = raw === '' || raw === null ? 0 : Number(raw);

        this.rows = this.rows.map(row => {
            if (row.id !== id) return row;
            const newAmount = this.calcAmount(newPct, row.type);
            let errorMsg = '';
            if (newPct < 0) {
                errorMsg = 'Percentage cannot be negative.';
            } else if (newAmount < row.received) {
                errorMsg = `Amount (${newAmount}) is below received (${row.received}).`;
            }
            return { ...row, pct: newPct, amount: newAmount, errorMsg };
        });
    }

    get totalPct() {
        const sum = this.rows.reduce((acc, r) => acc + (Number(r.pct) || 0), 0);
        return Math.round(sum * 100) / 100;
    }

    get totalAmount() {
        const sum = this.rows.reduce((acc, r) => acc + (Number(r.amount) || 0), 0);
        return Math.round(sum * 100) / 100;
    }

    get isTotalValid() {
        return this.totalPct === this.expectedTotal;
    }

    get hasRowErrors() {
        return this.rows.some(r => !!r.errorMsg);
    }

    get isDirty() {
        return this.rows.some(r => Number(r.pct) !== Number(r.originalPct));
    }

    get saveDisabled() {
        return this.saving || !this.isDirty || !this.isTotalValid || this.hasRowErrors;
    }

    get totalPctClass() {
        return this.isTotalValid
            ? 'slds-text-align_right slds-text-color_success'
            : 'slds-text-align_right slds-text-color_error';
    }

    handleSave() {
        if (this.saveDisabled) return;

        const edits = this.rows
            .filter(r => Number(r.pct) !== Number(r.originalPct))
            .map(r => ({
                Id: r.id,
                Payment_percent__c: Number(r.pct)
            }));

        if (edits.length === 0) {
            this.close();
            return;
        }

        this.saving = true;
        saveSchedules({ bookingId: this.bookingId, edits })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Saved',
                    message: 'Payment percentages updated.',
                    variant: 'success'
                }));
                this.close();
            })
            .catch(error => {
                this.showError('Save failed', this.reduceError(error));
            })
            .finally(() => {
                this.saving = false;
            });
    }

    handleCancel() {
        this.close();
    }

    close() {
        // Notify an Aura parent that's rendering us via <aura:if>.
        this.dispatchEvent(new CustomEvent('close', { bubbles: true, composed: true }));
        // Also fire CloseActionScreenEvent in case we're launched as a Quick Action.
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showError(title, message) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant: 'error',
            mode: 'sticky'
        }));
    }

    reduceError(error) {
        if (!error) return 'Unknown error';
        if (Array.isArray(error.body)) {
            return error.body.map(e => e.message).join(', ');
        }
        if (error.body && typeof error.body.message === 'string') {
            return error.body.message;
        }
        if (typeof error.message === 'string') return error.message;
        return JSON.stringify(error);
    }
}