import { LightningElement, track } from 'lwc';
import searchLead from '@salesforce/apex/LeadGlobalSearchController.searchLead';
import { NavigationMixin } from 'lightning/navigation';

export default class LeadGlobalSearch extends NavigationMixin(LightningElement) {

    searchText = '';
    @track leads;
    noResult = false;
    isLoading = false;

    get isSearchDisabled() {
        return !this.searchText || this.isLoading;
    }

    get isClearDisabled() {
        return !this.searchText && !this.leads;
    }

    get showResults() {
        return this.leads && this.leads.length > 0 && !this.isLoading;
    }

    get resultCount() {
        return this.leads ? this.leads.length : 0;
    }

    get resultLabel() {
        return this.resultCount === 1 ? 'Lead Found' : 'Leads Found';
    }

    handleChange(event) {
        this.searchText = event.target.value;
        this.noResult = false;
    }

    handleKeyPress(event) {
        if (event.keyCode === 13 && this.searchText) {
            this.handleSearch();
        }
    }

    handleSearch() {
        if (!this.searchText) return;

        this.isLoading = true;
        this.noResult = false;
        this.leads = null;

        searchLead({ searchText: this.searchText })
            .then(result => {
                this.leads = result;
                this.noResult = result.length === 0;
            })
            .catch(error => {
                console.error('Search error:', error);
                this.noResult = true;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleClear() {
        this.searchText = '';
        this.leads = null;
        this.noResult = false;
        
        // Focus back on input
        const input = this.template.querySelector('lightning-input');
        if (input) {
            input.focus();
        }
    }

    openLead(event) {
        const leadId = event.target.dataset.id;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: leadId,
                objectApiName: 'Lead',
                actionName: 'view'
            }
        });
    }
}