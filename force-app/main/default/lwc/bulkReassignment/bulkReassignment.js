import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDoInitValues from '@salesforce/apex/BulkLeadReassignmentController.getDoInitValues';
import getFilteredLeads from '@salesforce/apex/BulkLeadReassignmentController.getFilteredLeads';
import updateLeadOwner from '@salesforce/apex/BulkLeadReassignmentController.updateLeadOwner';

const PAGE_SIZE = 50;

const COLUMNS = [
    { label: 'Lead Id', fieldName: 'Lead_ID__c', type: 'text' },
    { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'Status', fieldName: 'Lead_Status__c', type: 'text' },
    { label: 'Record Type', fieldName: 'Lead_Record_Type__c', type: 'text' },
    { label: 'Mobile Number', fieldName: 'Phone__c', type: 'text' },
    {
        label: 'Created Date', fieldName: 'Created_Date__c', type: 'date',
        typeAttributes: {
            day: 'numeric', month: 'short', year: 'numeric',
            hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true
        }
    },
    { label: 'Allocated Project', fieldName: 'Allocated_Project__c', type: 'text' },
    { label: 'Lead Source', fieldName: 'Source_Type__c', type: 'text' },
    { label: 'Sub Source', fieldName: 'Lead_source__c', type: 'text' },
    { label: 'Lead Owner', fieldName: 'Lead_Owner_Full_Name__c', type: 'text' },
    { label: 'Batch Code', fieldName: 'Campaign__c', type: 'text' },
    {
        label: 'Allocation Date', fieldName: 'Pushed_On__c', type: 'date',
        typeAttributes: {
            day: 'numeric', month: 'short', year: 'numeric',
            hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true
        }
    },
    { label: 'Sub Source Text', fieldName: 'Sub_Source__c', type: 'text' }
];

export default class BulkReassignment extends LightningElement {

    // ─── Table ───
    columns = COLUMNS;
    @track allLeads = [];
    @track paginatedData = [];
    @track selectedRowIds = [];
    @track selectedLeads = [];
    selectedRowsCount = 0;
    currentPage = 1;
    totalPages = 1;

    // ─── User Lookups ───
    @track allUsers = [];
    @track activeUsers = [];
    @track matchUsers = [];
    @track matchUsers2 = [];
    searchText = '';
    searchText2 = '';
    userId = '';
    nextUserId = '';

    // ─── Filters ───
    projectFilter = '';
    leadStatusFilter = '';
    leadSourceFilter = '';
    fromCreatedDate = '';
    toCreatedDate = '';
    fromSiteVisitDate = '';
    toSiteVisitDate = '';
    fromFollowUpDate = '';
    toFollowUpDate = '';
    fromAllocationDate = '';
    toAllocationDate = '';
    subSource = '';
    phoneNumber = '';

    // ─── Picklist Options ───
    @track projectOptions = [];
    @track leadStatusOptions = [];
    @track leadSourceOptions = [];

    // ─── UI State ───
    isLoading = false;
    showFilter = false;
    showDataTable = false;

    // ─── Computed Properties ───
    get showMatchUsers() {
        return this.matchUsers && this.matchUsers.length > 0;
    }

    get showMatchUsers2() {
        return this.matchUsers2 && this.matchUsers2.length > 0;
    }

    get hasLeads() {
        return this.allLeads && this.allLeads.length > 0;
    }

    get hasSelectedRows() {
        return this.selectedRowsCount > 0;
    }

    get isPreviousDisabled() {
        return this.currentPage <= 1;
    }

    get isNextDisabled() {
        return this.currentPage >= this.totalPages;
    }

    // ═══════════════════════════════════════════
    //  LIFECYCLE
    // ═══════════════════════════════════════════

    connectedCallback() {
        this.loadInitValues();
    }

    // ═══════════════════════════════════════════
    //  INIT - Load picklists + users
    // ═══════════════════════════════════════════

    loadInitValues() {
        getDoInitValues()
            .then(result => {
                // Build picklist options
                this.projectOptions = this.buildOptions(result.projectValues);
                this.leadStatusOptions = this.buildOptions(result.leadStatusValues);
                this.leadSourceOptions = this.buildOptions(result.leadSourceValues);

                // User lists - flatten Profile.Name for template access
                this.allUsers = (result.allUserList || []).map(u => ({
                    ...u,
                    ProfileName: u.Profile ? u.Profile.Name : ''
                }));
                this.activeUsers = (result.activeUserList || []).map(u => ({
                    ...u,
                    ProfileName: u.Profile ? u.Profile.Name : ''
                }));
            })
            .catch(error => {
                this.showToast('Error loading init values', this.reduceErrors(error), 'error');
            });
    }

    buildOptions(valueMap) {
        let opts = [{ label: '--None--', value: '' }];
        if (valueMap) {
            Object.keys(valueMap).forEach(key => {
                opts.push({ label: valueMap[key], value: key });
            });
        }
        return opts;
    }

    // ═══════════════════════════════════════════
    //  USER SEARCH - Current User
    // ═══════════════════════════════════════════

    handleSearchText(event) {
        this.searchText = event.target.value;
        if (this.searchText && this.searchText.trim() !== '') {
            const term = this.searchText.toLowerCase();
            this.matchUsers = this.allUsers.filter(u =>
                u.Id !== this.nextUserId &&
                u.Name.toLowerCase().includes(term)
            );
        } else {
            this.matchUsers = [];
            this.allLeads = [];
            this.paginatedData = [];
        }
    }

    handleSelectUser(event) {
        const selectedId = event.currentTarget.dataset.id;
        this.userId = selectedId;
        const selected = this.matchUsers.find(u => u.Id === selectedId);
        if (selected) {
            this.searchText = selected.Name;
        }
        this.matchUsers = [];
        this.showDataTable = true;
        this.showFilter = true;
        this.fetchFilteredLeads();
    }

    // ═══════════════════════════════════════════
    //  USER SEARCH - Assigning To
    // ═══════════════════════════════════════════

    handleSearchText2(event) {
        this.searchText2 = event.target.value;
        if (this.searchText2 && this.searchText2.trim() !== '') {
            const term = this.searchText2.toLowerCase();
            this.matchUsers2 = this.activeUsers.filter(u =>
                u.Id !== this.userId &&
                u.Name.toLowerCase().includes(term)
            );
        } else {
            this.matchUsers2 = [];
        }
    }

    handleSelectUser2(event) {
        const selectedId = event.currentTarget.dataset.id;
        this.nextUserId = selectedId;
        const selected = this.matchUsers2.find(u => u.Id === selectedId);
        if (selected) {
            this.searchText2 = selected.Name;
        }
        this.matchUsers2 = [];
    }

    // ═══════════════════════════════════════════
    //  FILTERS
    // ═══════════════════════════════════════════

    handleFilterChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;

        switch (field) {
            case 'project': this.projectFilter = value; break;
            case 'fromCreatedDate': this.fromCreatedDate = value; break;
            case 'toCreatedDate': this.toCreatedDate = value; break;
            case 'fromSiteVisitDate': this.fromSiteVisitDate = value; break;
            case 'toSiteVisitDate': this.toSiteVisitDate = value; break;
            case 'fromFollowUpDate': this.fromFollowUpDate = value; break;
            case 'toFollowUpDate': this.toFollowUpDate = value; break;
            case 'leadStatus': this.leadStatusFilter = value; break;
            case 'leadSource': this.leadSourceFilter = value; break;
            case 'subSource': this.subSource = value; break;
            case 'fromAllocationDate': this.fromAllocationDate = value; break;
            case 'toAllocationDate': this.toAllocationDate = value; break;
            case 'phoneNumber': this.phoneNumber = value; break;
            default: break;
        }

        this.fetchFilteredLeads();
    }

    // ─── Clear All Filters ───
    handleClearFilters() {
        this.projectFilter = '';
        this.leadStatusFilter = '';
        this.leadSourceFilter = '';
        this.fromCreatedDate = '';
        this.toCreatedDate = '';
        this.fromSiteVisitDate = '';
        this.toSiteVisitDate = '';
        this.fromFollowUpDate = '';
        this.toFollowUpDate = '';
        this.fromAllocationDate = '';
        this.toAllocationDate = '';
        this.subSource = '';
        this.phoneNumber = '';

        this.fetchFilteredLeads();
    }

    // ═══════════════════════════════════════════
    //  FETCH FILTERED LEADS
    // ═══════════════════════════════════════════

    fetchFilteredLeads() {
        if (!this.userId) return;

        this.isLoading = true;

        getFilteredLeads({
            currentUserId: this.userId,
            projectId: this.projectFilter || null,
            leadStatus: this.leadStatusFilter || null,
            leadSource: this.leadSourceFilter || null,
            fromCreatedDate: this.fromCreatedDate || null,
            toCreatedDate: this.toCreatedDate || null,
            batchcode: null,
            subSource: this.subSource || null,
            fromAllocationDate: this.fromAllocationDate || null,
            toAllocationDate: this.toAllocationDate || null,
            fromSiteVisitDate: this.fromSiteVisitDate || null,
            toSiteVisitDate: this.toSiteVisitDate || null,
            fromFollowUpDate: this.fromFollowUpDate || null,
            toFollowUpDate: this.toFollowUpDate || null,
            phoneNumber: this.phoneNumber || null,
            followupSubject: null
        })
            .then(result => {
                this.allLeads = result || [];
                this.totalPages = Math.max(1, Math.ceil(this.allLeads.length / PAGE_SIZE));
                this.currentPage = 1;
                this.selectedRowIds = [];
                this.selectedLeads = [];
                this.selectedRowsCount = 0;
                this.updatePaginatedData();
            })
            .catch(error => {
                this.showToast('Error', this.reduceErrors(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // ═══════════════════════════════════════════
    //  PAGINATION
    // ═══════════════════════════════════════════

    updatePaginatedData() {
        const start = (this.currentPage - 1) * PAGE_SIZE;
        const end = start + PAGE_SIZE;
        this.paginatedData = this.allLeads.slice(start, end);
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
            this.updatePaginatedData();
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage += 1;
            this.updatePaginatedData();
        }
    }

    // ═══════════════════════════════════════════
    //  ROW SELECTION
    // ═══════════════════════════════════════════

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRowsCount = selectedRows.length;
        this.selectedLeads = selectedRows;
        this.selectedRowIds = selectedRows.map(row => row.Id);
    }

    // ═══════════════════════════════════════════
    //  CHANGE OWNER
    // ═══════════════════════════════════════════

    handleChangeOwner() {
        if (!this.nextUserId) {
            this.showToast('Error', 'Please select the Assigning user', 'error');
            return;
        }

        if (this.selectedLeads.length === 0) {
            this.showToast('Error', 'Please select at least one lead', 'error');
            return;
        }

        this.isLoading = true;

        updateLeadOwner({
            leads: this.selectedLeads,
            currentUserId: this.userId,
            assignToId: this.nextUserId
        })
            .then(result => {
                this.allLeads = result || [];
                this.totalPages = Math.max(1, Math.ceil(this.allLeads.length / PAGE_SIZE));
                this.currentPage = 1;
                this.selectedRowIds = [];
                this.selectedLeads = [];
                this.selectedRowsCount = 0;
                this.updatePaginatedData();
                this.showToast('Success', 'Lead owner changed successfully', 'success');
            })
            .catch(error => {
                const msg = this.reduceErrors(error);
                if (msg.includes('inValid')) {
                    this.showToast('Error', 'Cannot change Lead ownership from Sales to Presales, unless it\'s Closed Lost', 'error');
                } else {
                    this.showToast('Error', msg, 'error');
                }
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // ═══════════════════════════════════════════
    //  CANCEL
    // ═══════════════════════════════════════════

    handleCancel() {
        this.searchText = '';
        this.searchText2 = '';
        this.userId = '';
        this.nextUserId = '';
        this.matchUsers = [];
        this.matchUsers2 = [];
        this.allLeads = [];
        this.paginatedData = [];
        this.selectedRowIds = [];
        this.selectedLeads = [];
        this.selectedRowsCount = 0;
        this.currentPage = 1;
        this.totalPages = 1;
        this.showFilter = false;
        this.showDataTable = false;
        this.handleClearFilters();
    }

    // ═══════════════════════════════════════════
    //  UTILITIES
    // ═══════════════════════════════════════════

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceErrors(errors) {
        if (!Array.isArray(errors)) {
            errors = [errors];
        }
        return errors
            .filter(error => !!error)
            .map(error => {
                if (typeof error === 'string') return error;
                if (error.body) {
                    if (typeof error.body.message === 'string') return error.body.message;
                    if (error.body.fieldErrors) {
                        return Object.values(error.body.fieldErrors)
                            .flat()
                            .map(e => e.message)
                            .join(', ');
                    }
                    if (error.body.pageErrors) {
                        return error.body.pageErrors.map(e => e.message).join(', ');
                    }
                }
                if (error.message) return error.message;
                return JSON.stringify(error);
            })
            .join(', ');
    }
}