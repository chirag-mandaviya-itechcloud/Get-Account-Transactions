import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccountDetails from '@salesforce/apex/GetAccountTransactionsController.getAccountDetails';
import getAllTransactionMasterObject from '@salesforce/apex/GetAccountTransactionsController.getAllTransactionMasterObject';
import getTransactionMasterObjectData from '@salesforce/apex/GetAccountTransactionsController.getTransactionMasterObjectData';
import getOutstandingTransactionMasterObject from '@salesforce/apex/GetAccountTransactionsController.getOutstandingTransactionMasterObject'

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
                const result = await getOutstandingTransactionMasterObject();
                console.log("Outstanding Transaction objects : ", result);
                this.transactionObjectNames = result;
            } else if (this.selectedType == 'Overdue') {

            } else if (this.selectedType == 'Paid Invoice') {

            } else if (this.selectedType == 'Credit Notes') {

            } else if (this.selectedType == 'Receipt & Payment') {

            } else if (this.selectedType == 'Journals') {

            }
        } catch (error) {
            console.error("Error fetching all transactions objects : ", error);
            this.showToast("Error", "Error fetching transaction objects", "error");
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
                    getTransactionMasterObjectData({
                        objectName: objName,
                        accountId: this.recordId,
                        fromDate: this.fromDate,
                        toDate: this.toDate,
                        statuses: this.selectedStatuses,
                        txnType: this.selectedType
                    })
                );

                // Wait for all promises to resolve
                const results = await Promise.all(promises);

                // Map results to wrapper data
                this.transactionsData = results
                    .filter(result => result.recordCount > 0)
                    .map(result => {
                        console.log("All Data without flatten : ", result);
                        const flattenedRecords = result.records.map(record =>
                            this.flattenRecord(record)
                        );

                        const columns = this.buildColumnsFromFieldNames(result.fieldNames);
                        return {
                            objectName: result.objectName,
                            displayLabel: result.displayLabel,
                            records: flattenedRecords,
                            recordCount: result.recordCount,
                            filteredRecords: flattenedRecords,
                            columns: columns,
                            searchTerm: '',
                            hasRecords: true
                        };
                    });

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
            this.showToast("Error", error.body?.message || "Error fetching transactions", "error");
        } finally {
            this.isLoading = false;
        }
    }

    flattenRecord(record) {
        const flat = {};

        Object.keys(record).forEach(key => {
            if (key === 'attributes') return;
            const value = record[key];

            if (typeof value === 'object' && value !== null) {
                Object.keys(value).forEach(childKey => {
                    if (childKey !== 'attributes') {
                        flat[`${key}_${childKey}`] = value[childKey];
                    }
                });
            } else {
                flat[key] = value;
            }
        });

        return flat;
    }

    buildColumnsFromFieldNames(fieldNames) {
        if (!fieldNames || fieldNames.length === 0) {
            return [];
        }

        const columns = [];

        fieldNames.forEach(fieldName => {
            // Skip attributes and Id fields
            if (fieldName === 'attributes' || fieldName === 'Id') {
                return;
            }

            // Handle relationship fields (e.g., Transaction_Currency__r.ISO_Code__c)
            let flattenedFieldName = fieldName;
            if (fieldName.includes('.')) {
                flattenedFieldName = fieldName.replace(/\./g, '_')
            }

            // Skip currency fields that don't have ISO in them
            if (flattenedFieldName.toLowerCase().includes('currency') && !flattenedFieldName.toLowerCase().includes('iso')) {
                return;
            }

            const column = {
                label: fieldName,
                fieldName: flattenedFieldName,
                type: 'text',
                sortable: true
            };

            if (flattenedFieldName.toLowerCase().includes('date')) {
                column.label = 'Date';
                column.type = 'date';
                column.typeAttributes = {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric'
                };
            } else if (flattenedFieldName === 'Name') {
                column.label = 'Name';
                column.type = 'text';
                column.wrapText = false;
            } else if (flattenedFieldName.toLowerCase().includes('reference')) {
                column.label = 'Customer Reference';
            } else if (flattenedFieldName.toLowerCase().includes('status')) {
                column.label = 'Status';
            } else if (flattenedFieldName.toLowerCase().includes('currency') && flattenedFieldName.toLowerCase().includes('iso')) {
                column.label = 'Currency';
            } else if (flattenedFieldName.toLowerCase().includes('nature') && flattenedFieldName.toLowerCase().includes('transaction')) {
                column.label = 'Type';
            }

            columns.push(column);
        });

        return columns;
    }

    handleSearch(event) {
        const searchTerm = event.target.value.toLowerCase();
        const objectName = event.target.dataset.object;

        console.log(`Searching ${objectName} for: ${searchTerm}`);

        this.transactionsData = this.transactionsData.map(transactionObj => {
            if (transactionObj.objectName === objectName) {
                const filteredRecords = transactionObj.records.filter(record => {
                    return Object.keys(record).some(key => {
                        if (key === 'attributes' && key === 'Id') return false;

                        const value = record[key];
                        if (value === null || value === undefined) return false;

                        return String(value).toLowerCase().includes(searchTerm);
                    });
                });

                console.log(`Found ${filteredRecords.length} records matching "${searchTerm}"`);

                return {
                    ...transactionObj,
                    searchTerm: searchTerm,
                    filteredRecords: filteredRecords,
                    hasRecords: filteredRecords.length > 0
                };
            }
            return transactionObj;
        });
    }

    get hasTransactionData() {
        return this.transactionsData && this.transactionsData.length > 0;
    }

    get showTransactionStatus() {
        return (this.selectedType === '' || this.selectedType === 'All')
    }

    handleDone() {
        // Close the quick action modal
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            }),
        )
    }
}
