import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccountDetails from '@salesforce/apex/GetAccountTransactionsController.getAccountDetails';
import getAllTransactionMasterObject from '@salesforce/apex/GetAccountTransactionsController.getAllTransactionMasterObject';
import getTransactionMasterObjectData from '@salesforce/apex/GetAccountTransactionsController.getTransactionMasterObjectData';
import getTransactionMasterObject from '@salesforce/apex/GetAccountTransactionsController.getTransactionMasterObject';
import getCreditTransactionMasterObject from '@salesforce/apex/GetAccountTransactionsController.getCreditTransactionMasterObject';
import getRAPTransactionMasterObject from '@salesforce/apex/GetAccountTransactionsController.getRAPTransactionMasterObject';
import getJournalTransactionMasterObject from '@salesforce/apex/GetAccountTransactionsController.getJournalTransactionMasterObject';

export default class GetAccountTransactions extends LightningElement {
    recordId;
    balanceOutstanding = '0';
    fromDate = '2024-01-01';
    toDate = '';
    selectedType = '';
    selectedStatuses = [];
    isLoading = false;
    homePage = true;
    transactionsPage = false;
    pdfPage = false;
    transactionObjectNames = [];
    transactionsData = [];
    templateName = 'Account_Transaction_Template';

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

    statusOptions = [
        { label: 'Draft', value: 'Draft' },
        { label: 'Posted', value: 'Posted' }
    ];

    connectedCallback() {
        const today = new Date();
        this.toDate = today.toISOString().split('T')[0];
    }

    renderedCallback() {
        console.log('Modal renderedCallback called');
        const STYLE = document.createElement("style");
        STYLE.innerText = `.uiModal--medium .modal-container{
            width: 100% !important;
            max-width: 1200px !important;
            min-width: 600px !important;
        }`;
        // this.template.querySelector('lightning-quick-action-panel').appendChild(STYLE);
        this.template.querySelector('.override-css').appendChild(STYLE);
    }

    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (pageRef) {
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
                this.balanceOutstanding = result.s2p3__Account_Balance__c || '0';
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching balance:', error);
                this.balanceOutstanding = '0'; // Fallback value
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
        if (this.selectedType !== 'All') {
            this.selectedStatuses = [];
        }
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
                const result = await getTransactionMasterObject();
                console.log("Outstanding Transaction objects : ", result);
                this.transactionObjectNames = result;
            } else if (this.selectedType == 'Overdue') {
                const result = await getTransactionMasterObject();
                console.log("Overdue Transaction objects : ", result);
                this.transactionObjectNames = result;
            } else if (this.selectedType == 'Paid Invoice') {
                const result = await getTransactionMasterObject();
                console.log("Paid Invoice Transaction objects : ", result);
                this.transactionObjectNames = result;
            } else if (this.selectedType == 'Credit Notes') {
                const result = await getCreditTransactionMasterObject();
                console.log("Credit Notes Transaction objects : ", result);
                this.transactionObjectNames = result;
            } else if (this.selectedType == 'Receipt & Payment') {
                const result = await getRAPTransactionMasterObject();
                console.log("Receipt & Payment Transaction objects : ", result);
                this.transactionObjectNames = result;
            } else if (this.selectedType == 'Journals') {
                const result = await getJournalTransactionMasterObject();
                console.log("Journals Transaction objects : ", result);
                this.transactionObjectNames = result;
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

                    const lowercaseFieldNames = result.fieldNames.map(fieldName =>
                        fieldName.toLowerCase()
                    );

                    const columns = this.buildColumnsFromFieldNames(lowercaseFieldNames);
                    return {
                        objectName: result.objectName,
                        displayLabel: result.displayLabel,
                        records: flattenedRecords,
                        recordCount: result.recordCount,
                        filteredRecords: flattenedRecords,
                        query: result.query,
                        columns: columns,
                        searchTerm: '',
                        hasRecords: true
                    };
                });
            console.log("All Data: ", this.transactionsData);
        } catch (error) {
            console.error("Error fetching all transactions objects data : ", error);
            this.showToast("Error", error.body?.message || "Error fetching transactions", "error");
        } finally {
            this.isLoading = false;
        }
    }

    flattenRecord(record, prefix = '') {
        const flat = {};

        Object.keys(record).forEach(key => {
            if (key === 'attributes') return;

            const value = record[key];
            const newKey = prefix ? `${prefix}_${key}` : key;

            if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
                // Recursively flatten nested objects
                const nestedFlat = this.flattenRecord(value, newKey);
                Object.assign(flat, nestedFlat);
            } else {
                flat[newKey.toLowerCase()] = value;
            }
        });

        return flat;
    }

    buildColumnsFromFieldNames(fieldNames) {
        if (!fieldNames || fieldNames.length === 0) {
            return [];
        }

        const columnOrder = [
            'name',
            'date',
            'due',
            'txnnumber',
            'account',
            'currency',
            'reference',
            'status',
            'type',
            'gross',
            'outstanding',
            'paid',
        ];

        const columns = [];
        const columnMap = new Map();

        fieldNames.forEach(fieldName => {
            if (fieldName === 'attributes' || fieldName === 'id' || fieldName === 'name' || fieldName.includes('reference')) {
                return;
            }

            let flattenedFieldName = fieldName;
            if (fieldName.includes('.')) {
                flattenedFieldName = fieldName.replace(/\./g, '_')
            }

            if (flattenedFieldName.includes('currency') && !flattenedFieldName.includes('iso')) {
                return;
            }

            if (flattenedFieldName.includes('account') && !flattenedFieldName.includes('name')) {
                return;
            }

            const column = {
                label: fieldName,
                fieldName: flattenedFieldName.toLowerCase(),
                type: 'text',
                sortable: true,
                orderKey: 'other'
            };

            if (flattenedFieldName.includes('date') || flattenedFieldName.includes('due')) {
                column.label = 'Date';
                column.type = 'date';
                column.typeAttributes = {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric'
                };
                column.orderKey = 'date';
            } else if (flattenedFieldName === 'name') {
                column.label = 'Name';
                column.type = 'text';
                column.wrapText = false;
                column.orderKey = 'name';
            } else if (flattenedFieldName.includes('reference')) {
                column.label = 'Customer Reference';
                column.orderKey = 'reference';
            } else if (flattenedFieldName.includes('status')) {
                column.label = 'Status';
                column.orderKey = 'status';
            } else if (flattenedFieldName.includes('currency') && flattenedFieldName.includes('iso')) {
                column.label = 'Currency';
                column.orderKey = 'currency';
            } else if (flattenedFieldName.includes('nature') && flattenedFieldName.includes('transaction')) {
                column.label = 'Type';
                column.orderKey = 'type';
            } else if (flattenedFieldName.includes('outstanding')) {
                column.label = 'Outstanding';
                column.orderKey = 'outstanding';
            } else if (flattenedFieldName.includes('due')) {
                column.label = 'Overdue Date';
                column.orderKey = 'due';
            } else if (flattenedFieldName.includes('paid')) {
                column.label = 'Paid Amount';
                column.orderKey = 'paid';
            } else if (flattenedFieldName.includes('gross') || flattenedFieldName.includes('amount')) {
                column.label = 'Gross Amount';
                column.orderKey = 'gross';
            } else if (flattenedFieldName.includes('account')) {
                column.label = 'Account';
                column.orderKey = 'account';
            } else if (flattenedFieldName.includes('transaction') && flattenedFieldName.includes('number')) {
                column.label = 'Invoice Number';
                column.orderKey = 'txnnumber';
            }

            if (!columnMap.has(column.orderKey)) {
                columnMap.set(column.orderKey, []);
            }
            columnMap.get(column.orderKey).push(column);
            // columns.push(column);
        });

        // Build ordered columns array based on columnOrder
        columnOrder.forEach(orderKey => {
            if (columnMap.has(orderKey)) {
                columns.push(...columnMap.get(orderKey));
                columnMap.delete(orderKey);
            }
        });

        // Add any remaining columns that were not in the predefined order
        columnMap.forEach(cols => {
            columns.push(...cols);
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
                        if (key === 'attributes' && key === 'id') return false;

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

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleGetPDF() {
        this.transactionsPage = false;
        this.pdfPage = true;
    }

    get iframeUrl() {
        if (!this.recordId || !this.templateName) {
            return '';
        }

        return `/apex/TransactionPDF?templateDevName=${this.templateName}&whatId=${this.recordId}`;
    }

    get showIframe() {
        console.log('iframeUrl:', this.iframeUrl);
        return !this.isLoading && this.iframeUrl;
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
