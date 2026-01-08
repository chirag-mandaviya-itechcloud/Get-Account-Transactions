import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccountDetails from '@salesforce/apex/GetAccountTransactionsController.getAccountDetails';
import getAllTransactionMasterObject from '@salesforce/apex/GetAccountTransactionsController.getAllTransactionMasterObject';
import getAllTransactionMasterObjectData from '@salesforce/apex/GetAccountTransactionsController.getAllTransactionMasterObjectData';

export default class GetAccountTransactions extends LightningElement {
    recordId; // Account Record ID
    balanceOutstanding = '0';
    fromDate = '2024-01-01';
    toDate = '';
    selectedType = '';
    selectedStatuses = [];
    isLoading = false;
    homePage = true;
    transactionsPage = false;
    transactionObjectNames = [];
    transactionsData = [];

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
    }

    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef) {
            // Quick Action recordId comes from state.recordId
            this.recordId = pageRef.state?.recordId;
            this.baseUrl = window.location.origin;

            if (this.recordId) {
                console.log('Record ID from PageReference:', this.recordId);
                this.fetchAccountDetails();
            }
        }
    }

    fetchAccountDetails() {
        this.isLoading = true;
        getAccountDetails({ recordId: this.recordId })
            .then(result => {
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
        console.log('fromDate:', this.fromDate);
    }

    handleToDateChange(event) {

        this.toDate = event.target.value;
        console.log('toDate:', this.toDate);
    }

    handleTypeChange(event) {

        this.selectedType = event.detail.value;
        console.log('selectedType:', this.selectedType);
    }

    handleStatusChange(event) {

        this.selectedStatuses = event.detail.value;
        console.log('selectedStatuses:', this.selectedStatuses);
    }

    async handleNext() {
        if (!this.fromDate || !this.toDate || !this.selectedType) {
            this.showToast("Error", "Please fill all required fields", "error");
            return;
        }
        // Validate date range
        if (new Date(this.fromDate) > new Date(this.toDate)) {
            this.showToast("Error", "From Date should be less than or equal to To Date", "error");
            return;
        }

        this.homePage = false;
        this.transactionsPage = true;
        await this.getTransactionObjects();
        await this.getTransactionObjectsData();
    }

    async getTransactionObjects() {
        this.isLoading = true;
        try {
            if (this.selectedType == 'All') {
                const result = await getAllTransactionMasterObject()
                console.log("All Transactions objects : ", result);
                this.transactionObjectNames = result;
            } else if (this.selectedType == 'Outstanding') {

            } else if (this.selectedType == 'Overdue') {

            } else if (this.selectedType == 'Paid Invoice') {

            } else if (this.selectedType == 'Credit Notes') {

            } else if (this.selectedType == 'Receipt & Payment') {

            } else if (this.selectedType == 'Journals') {

            }
        } catch (error) {
            console.error("Error fetching all transactions objects : ", error);
        } finally {
            this.isLoading = false;
        }
    }

    async getTransactionObjectsData() {
        this.isLoading = true;
        try {
            if (this.selectedType == 'All') {
                // Use map to create an array of promises
                const promises = this.transactionObjectNames.map(objName =>
                    getAllTransactionMasterObjectData({
                        objectName: objName,
                        accountId: this.recordId,
                        fromDate: this.fromDate,
                        toDate: this.toDate,
                        statuses: this.selectedStatuses
                    })
                );

                // Wait for all promises to resolve
                const results = await Promise.all(promises);

                // Map results to wrapper data
                this.transactionsData = results.map(result => ({
                    objectName: result.objectName,
                    displayLabel: result.displayLabel,
                    records: result.records,
                    recordCount: result.recordCount
                }));

                console.log("All Data: ", this.transactionsData);

            } else if (this.selectedType == 'Outstanding') {

            } else if (this.selectedType == 'Overdue') {

            } else if (this.selectedType == 'Paid Invoice') {

            } else if (this.selectedType == 'Credit Notes') {

            } else if (this.selectedType == 'Receipt & Payment') {

            } else if (this.selectedType == 'Journals') {

            }
        } catch (error) {
            console.error("Error fetching all transactions objects data : ", error);
        } finally {
            this.isLoading = false;
        }
    }


    handleDone() {
        // Close the quick action modal
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(mTitle, mMessage, mVariant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: mTitle,
                message: mMessage,
                variant: mVariant
            }),
        )
    }
}
