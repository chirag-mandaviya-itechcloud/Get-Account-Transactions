import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import getBalanceOutstanding from '@salesforce/apex/TransactionController.getBalanceOutstanding';
// import getTransactions from '@salesforce/apex/TransactionController.getTransactions';
import getAccountDetails from '@salesforce/apex/GetAccountTransactionsController.getAccountDetails';

export default class GetAccountTransactions extends LightningElement {
    @api recordId; // Account Record ID

    balanceOutstanding = '0';
    fromDate = '2024-01-01';
    toDate = '';
    selectedType = '';
    selectedStatuses = [];
    isLoading = false;
    errorMessage = '';

    // Type picklist options
    typeOptions = [
        { label: '--None--', value: '' },
        { label: 'All', value: 'All' },
        { label: 'Outstanding', value: 'Outstanding' },
        { label: 'Overdue', value: 'Overdue' },
        { label: 'Paid Invoice', value: 'Paid Invoice' },
        { label: 'Credit Notes', value: 'Credit Notes' },
        { label: 'Receipt & Payment', value: 'Receipt & Payment' },
        { label: 'Journals', value: 'Journals' }
    ];

    // Status checkbox options
    statusOptions = [
        { label: 'Draft', value: 'Draft' },
        { label: 'Posted', value: 'Posted' }
    ];

    connectedCallback() {
        // Set today's date as To Date
        const today = new Date();
        this.toDate = today.toISOString().split('T')[0];
        console.log("record ID: ", this.recordId);

        // Fetch balance outstanding
        if (this.recordId) {
            this.fetchAccountDetails();
        }
    }

    fetchAccountDetails() {
        console.log("record ID: ", this.recordId);
        this.isLoading = true;
        getAccountDetails({ recordId: this.recordId })
            .then(result => {
                // this.balanceOutstanding = result ? result.toLocaleString() : '0';
                console.log("result: ", result);
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching balance:', error);
                this.balanceOutstanding = '1,000'; // Fallback value
                this.isLoading = false;
            });
    }

    handleFromDateChange(event) {
        this.fromDate = event.target.value;
        this.errorMessage = '';
    }

    handleToDateChange(event) {
        this.toDate = event.target.value;
        this.errorMessage = '';
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
        this.errorMessage = '';
    }

    handleStatusChange(event) {
        this.selectedStatuses = event.detail.value;
        this.errorMessage = '';
    }

    handleNext() {
        // Validate required fields
        if (!this.fromDate) {
            this.errorMessage = 'Please select From Date';
            return;
        }

        if (!this.toDate) {
            this.errorMessage = 'Please select To Date';
            return;
        }

        if (!this.selectedType) {
            this.errorMessage = 'Please select a Type';
            return;
        }

        // Validate date range
        if (new Date(this.fromDate) > new Date(this.toDate)) {
            this.errorMessage = 'From Date cannot be greater than To Date';
            return;
        }

        // Call Apex method to get transactions
        this.fetchTransactions();
    }

    // fetchTransactions() {
    //     this.isLoading = true;
    //     this.errorMessage = '';

    //     getTransactions({
    //         accountId: this.recordId,
    //         fromDate: this.fromDate,
    //         toDate: this.toDate,
    //         transactionType: this.selectedType,
    //         statuses: this.selectedStatuses
    //     })
    //         .then(result => {
    //             this.isLoading = false;

    //             // Show success message
    //             this.dispatchEvent(
    //                 new ShowToastEvent({
    //                     title: 'Success',
    //                     message: `Found ${result.length} transaction(s)`,
    //                     variant: 'success'
    //                 })
    //             );

    //             // Process the result or navigate to next step
    //             // You can dispatch a custom event here to parent component
    //             this.dispatchEvent(new CustomEvent('transactionsfetched', {
    //                 detail: result
    //             }));

    //             // Close the modal
    //             this.handleClose();
    //         })
    //         .catch(error => {
    //             this.isLoading = false;
    //             this.errorMessage = error.body ? error.body.message : 'An error occurred while fetching transactions';

    //             this.dispatchEvent(
    //                 new ShowToastEvent({
    //                     title: 'Error',
    //                     message: this.errorMessage,
    //                     variant: 'error'
    //                 })
    //             );
    //         });
    // }

    handleClose() {
        // Close the quick action modal
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
