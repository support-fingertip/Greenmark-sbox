import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import getBooking from '@salesforce/apex/BookingAmountAdjustmentController.getBooking';
import saveAdjustment from '@salesforce/apex/BookingAmountAdjustmentController.saveAdjustment';

const ROUND_TO = 1000;

export default class BookingAmountAdjustment extends LightningElement {
    @api recordId;

    @track loading = true;
    @track saving = false;
    bookingName = '';
    scheduleCount = 0;

    before = {
        plotLand: 0,
        construction: 0,
        extraLand: 0,
        totalLand: 0,
        total: 0
    };

    @track after = {
        plotLand: 0,
        construction: 0,
        totalLand: 0,
        total: 0
    };

    errorMsg = '';

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        this.loading = true;
        getBooking({ recordId: this.recordId })
            .then(result => {
                const b = result.booking || {};
                this.bookingName = b.Name || '';
                this.scheduleCount = result.scheduleCount || 0;

                const plotLand = Number(b.Plot_Land_Cost__c) || 0;
                const construction = Number(b.Construction_Cost__c) || 0;
                const extraLand = Number(b.Extra_Land_Amount__c) || 0;
                const totalLand = Number(b.Total_Land_Amount__c) || (plotLand + extraLand);
                const total = Number(b.Total_Amount__c) || 0;

                this.before = { plotLand, construction, extraLand, totalLand, total };
                this.after = {
                    plotLand,
                    construction,
                    totalLand,
                    total
                };
            })
            .catch(error => {
                this.showError('Load failed', this.reduceError(error));
            })
            .finally(() => {
                this.loading = false;
            });
    }

    handlePlotLandChange(event) {
        const raw = event.target.value;
        const newPlotLand = raw === '' || raw === null ? 0 : Number(raw);
        this.applyPlotLand(newPlotLand);
    }

    handleRoundOff() {
        const rounded = Math.round(this.after.plotLand / ROUND_TO) * ROUND_TO;
        this.applyPlotLand(rounded);
        const input = this.template.querySelector('[data-id="plot-land-input"]');
        if (input) {
            input.value = rounded;
        }
    }

    applyPlotLand(newPlotLand) {
        const diff = newPlotLand - this.before.plotLand;
        const newConstruction = this.before.construction - diff;
        const newTotalLand = newPlotLand + this.before.extraLand;

        this.after = {
            plotLand: newPlotLand,
            construction: newConstruction,
            totalLand: newTotalLand,
            total: this.before.total
        };

        if (newPlotLand < 0) {
            this.errorMsg = 'Plot Land Cost cannot be negative.';
        } else if (newConstruction < 0) {
            this.errorMsg = 'Construction Cost would go below zero. Reduce the Plot Land Cost change.';
        } else {
            this.errorMsg = '';
        }
    }

    get diffPlotLand() {
        return this.after.plotLand - this.before.plotLand;
    }

    get diffConstruction() {
        return this.after.construction - this.before.construction;
    }

    get plotLandChanged() {
        return this.diffPlotLand !== 0;
    }

    get constructionChanged() {
        return this.diffConstruction !== 0;
    }

    get plotLandRowClass() {
        return this.plotLandChanged ? 'changed-row' : '';
    }

    get constructionRowClass() {
        return this.constructionChanged ? 'changed-row' : '';
    }

    get diffPlotLandClass() {
        if (this.diffPlotLand > 0) return 'diff-pos';
        if (this.diffPlotLand < 0) return 'diff-neg';
        return '';
    }

    get diffConstructionClass() {
        if (this.diffConstruction > 0) return 'diff-pos';
        if (this.diffConstruction < 0) return 'diff-neg';
        return '';
    }

    get isDirty() {
        return this.after.plotLand !== this.before.plotLand;
    }

    get hasError() {
        return !!this.errorMsg;
    }

    get saveDisabled() {
        return this.saving || !this.isDirty || this.hasError;
    }

    get scheduleSummary() {
        const label = this.scheduleCount === 1 ? 'payment schedule' : 'payment schedules';
        return `${this.scheduleCount} ${label} will be recalculated`;
    }

    handleSave() {
        if (this.saveDisabled) return;
        this.saving = true;
        saveAdjustment({
            bookingId: this.recordId,
            newPlotLandCost: this.after.plotLand,
            newConstructionCost: this.after.construction
        })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Saved',
                    message: 'Booking amounts and payment schedules updated.',
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
        this.dispatchEvent(new CustomEvent('close', { bubbles: true, composed: true }));
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