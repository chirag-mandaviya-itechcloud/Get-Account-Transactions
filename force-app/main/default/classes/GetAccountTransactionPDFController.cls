public class GetAccountTransactionPDFController {
	public String templateHtml { get; set; }
    public String objectNamesString { get; set; }
    public String fromDate { get; set; }
    public String toDate { get; set; }
    public String txnType { get; set; }
    public String statusesParam { get; set; }
    public List<TransactionRecord> transactionRecords { get; set; }
	public String companyLogo { get; set; }

	public Account accountDetails { get; set; }
    public String statementDate { get; set; }
    public String sentDate { get; set; }
	public Decimal totalGrossAmount { get; set; }
    public Decimal totalOutstandingAmount { get; set; }

    public class QueryResult {
        public String objectName { get; set; }
        public List<SObject> records { get; set; }
    }

	public class TransactionRecord {
        public String objectName { get; set; }
        public String transactionDate { get; set; }
        public String invoiceNumber { get; set; }
        public String accountName { get; set; }
        public String reference { get; set; }
        public String currencyName { get; set; }
        public Decimal grossAmount { get; set; }
        public Decimal outstandingAmount { get; set; }
        public String recordId { get; set; }
        public String recordName { get; set; }
    }

    public GetAccountTransactionPDFController() {
        Id contactId   = ApexPages.currentPage().getParameters().get('contactId');
        Id whatId      = ApexPages.currentPage().getParameters().get('whatId');
        String devName = ApexPages.currentPage().getParameters().get('templateDevName');
        String objectNamesString = ApexPages.currentPage().getParameters().get('objectNames');
        Date fromDate = ApexPages.currentPage().getParameters().get('fromDate') != null ? Date.valueOf(ApexPages.currentPage().getParameters().get('fromDate')) : null;
        Date toDate = ApexPages.currentPage().getParameters().get('toDate') != null ? Date.valueOf(ApexPages.currentPage().getParameters().get('toDate')) : null;
        String txnType = ApexPages.currentPage().getParameters().get('txnType');
        String statusesParam = ApexPages.currentPage().getParameters().get('statuses');

		// Set statement date and sent date
        statementDate = String.valueOf(Date.today().format());
        sentDate = String.valueOf(Date.today().format());

		// Initialize totals
        totalGrossAmount = 0;
        totalOutstandingAmount = 0;


        List<String> statuses = new List<String>();
        if (String.isNotBlank(statusesParam)) {
            statuses = (List<String>) JSON.deserialize(statusesParam, List<String>.class);
        } else {
            statuses = new List<String>{'Deleted'};
        }

        List<String> objectNames = new List<String>();
        if (String.isNotBlank(objectNamesString)) {
            objectNames = (List<String>) JSON.deserialize(objectNamesString, List<String>.class);
        }

        System.debug('Object Names ---> '+ objectNames);
        System.debug('From Date ---> '+ fromDate);
        System.debug('To Date ---> '+ toDate);
        System.debug('Transaction Type ---> '+ txnType);
        System.debug('Statuses ---> '+ statuses);

        transactionRecords = new List<TransactionRecord>();

		// Fetch Account Details
        if (String.isNotBlank(whatId)) {
            try {
                accountDetails = [SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, AccountNumber, Currency__r.Name, Company__c, Company__r.Name, Company__r.Address_Line1__c, Company__r.Address_Line2__c, Company__r.Company_Street__c, Company__r.Company_City__c, Company__r.Company_State__c, Company__r.Company_PostalCode__c, Company__r.Company_Country__c, Company__r.Company_Registration_Number__c FROM Account WHERE Id = :whatId LIMIT 1];
            } catch (Exception e) {
                System.debug('Error fetching account details: ' + e.getMessage());
            }
        }

        if (String.isNotBlank(devName)) {
            try {
                Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :devName LIMIT 1].Id;
                Messaging.SingleEmailMessage mail =
                    Messaging.renderStoredEmailTemplate(templateId, contactId, whatId);
                templateHtml = mail.getHtmlBody();
            } catch (Exception e) {
                System.debug('Error loading template: ' + e.getMessage());
                templateHtml = '<h1 style="color:red;">Error loading template: ' + e.getMessage() + '</h1>';
            }
        }

        if (!objectNames.isEmpty()) {
            for (String objName : objectNames) {
                String fieldsName = 'Id, Name';
                String query = buildDynamicQuery(fieldsName, objName, whatId, fromDate, toDate, statuses, txnType);
                System.debug('Dynamic Query for ' + objName + ': ' + query);

				try {
					List<SObject> records = Database.query(query);

					for (SObject record : records) {
						TransactionRecord tr = convertToTransactionRecord(record, objName);
						if (tr != null) {
							transactionRecords.add(tr);

							// Calculate totals
							if (tr.grossAmount != null) {
								totalGrossAmount += tr.grossAmount;
							}
							if (tr.outstandingAmount != null) {
								totalOutstandingAmount += tr.outstandingAmount;
							}
						}
					}

				} catch (Exception e) {
					System.debug('Error executing query for ' + objName + ': ' + e.getMessage());
				}
            }
            // System.debug('Query Results: ' + queryResults);
        }

		companyLogo = '/servlet/servlet.FileDownload?file=';

		Id companyId = null;
		if (accountDetails != null && accountDetails.Company__c != null) {
			companyId = accountDetails.Company__c;
		}

		if (companyId != null) {
			try {
				List<ContentDocumentLink> imageList = [
                    SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension, LinkedEntityId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :companyId
                    AND ContentDocument.Title = 'companylogo'
                    AND ContentDocument.FileExtension = 'png'
                    WITH SECURITY_ENFORCED
                ];

				if (imageList.size() > 0) {
					ContentVersion v = [
                        SELECT Id, Title
                        FROM ContentVersion
                        WHERE ContentDocumentId = :imageList[0].ContentDocumentId
                        WITH SECURITY_ENFORCED
                        LIMIT 1
                    ];

					if (v != null) {
                        companyLogo = '/sfc/servlet.shepherd/version/download/' + v.Id;
                        System.debug('Company Logo URL: ' + companyLogo);
                    }
				}
			} catch (Exception e) {
                System.debug('Error fetching company logo: ' + e.getMessage());
            }
		}
    }

	// Convert SObject to TransactionRecord wrapper
    private TransactionRecord convertToTransactionRecord(SObject record, String objectName) {
        String nameSpace = getOrgNameSpace();
        TransactionRecord tr = new TransactionRecord();

        try {
            tr.objectName = objectName;
            tr.recordId = (String) record.get('Id');
            tr.recordName = (String) record.get('Name');

            // Handle Date fields
            Date invoiceDate = (Date) getFieldValue(record, nameSpace + 'Invoice_Date__c');
            Date payDate = (Date) getFieldValue(record, nameSpace + 'Pay_Date__c');

            if (objectName == 'Journal_Lines__c') {
                SObject journal = record.getSObject('Journal__r');
                if (journal != null) {
                    invoiceDate = (Date) journal.get(nameSpace + 'Invoice_Date__c');
                }
            }

            if (invoiceDate != null) {
                tr.transactionDate = invoiceDate.format();
            } else if (payDate != null) {
                tr.transactionDate = payDate.format();
            }

            // Handle Invoice Number
            tr.invoiceNumber = (String) getFieldValue(record, nameSpace + 'Transaction_Number__c');

            if (objectName == 'Journal_Lines__c') {
                SObject journal = record.getSObject('Journal__r');
                if (journal != null) {
                    tr.invoiceNumber = (String) journal.get(nameSpace + 'Transaction_Number__c');
                }
            }

            // Handle Account Name - try different relationship names
            tr.accountName = getAccountName(record, nameSpace);

            // Handle Reference
            tr.reference = (String) getFieldValue(record, nameSpace + 'Customer_reference__c');
            if (String.isBlank(tr.reference)) {
                tr.reference = (String) getFieldValue(record, nameSpace + 'Payment_Reference__c');
            }

            // Handle Currency
            tr.currencyName = getCurrencyCode(record, objectName, nameSpace);

            // Handle Amounts
            tr.grossAmount = (Decimal) getFieldValue(record, nameSpace + 'Gross_Amount__c');
            tr.outstandingAmount = (Decimal) getFieldValue(record, nameSpace + 'Outstanding_Amount__c');

            if (tr.outstandingAmount == null) {
                tr.outstandingAmount = (Decimal) getFieldValue(record, nameSpace + 'Amount__c');
            }

            return tr;
        } catch (Exception e) {
            System.debug('Error converting record: ' + e.getMessage());
            return null;
        }
    }

    // Safe field value getter
    private Object getFieldValue(SObject record, String fieldName) {
        try {
            Map<String, Object> populatedFields = record.getPopulatedFieldsAsMap();
            if (populatedFields.containsKey(fieldName)) {
                return record.get(fieldName);
            }
        } catch (Exception e) {
            System.debug('Field ' + fieldName + ' not found: ' + e.getMessage());
        }
        return null;
    }

    // Get account name from different possible relationship fields
    private String getAccountName(SObject record, String nameSpace) {
        try {
            // Try Account__r first
            SObject accountRel = record.getSObject(nameSpace + 'Account__r');
            if (accountRel != null) {
                return (String) accountRel.get('Name');
            }
        } catch (Exception e) {
            System.debug('Account__r not found: ' + e.getMessage());
        }

        try {
            // Try To_Account__r
            SObject toAccountRel = record.getSObject(nameSpace + 'To_Account__r');
            if (toAccountRel != null) {
                return (String) toAccountRel.get('Name');
            }
        } catch (Exception e) {
            System.debug('To_Account__r not found: ' + e.getMessage());
        }

        return null;
    }

    // Get currency code
    private String getCurrencyCode(SObject record, String objectName, String nameSpace) {
        try {
            if (objectName == 'Journal_Lines__c') {
                SObject journal = record.getSObject('Journal__r');
                if (journal != null) {
                    SObject currencyObj = journal.getSObject(nameSpace + 'Transaction_Currency__r');
                    if (currencyObj != null) {
                        return (String) currencyObj.get('ISO_Code__c');
                    }
                }
            }

            // Try Transaction_Currency__r
            SObject transCurrency = record.getSObject(nameSpace + 'Transaction_Currency__r');
            if (transCurrency != null) {
                return (String) transCurrency.get('ISO_Code__c');
            }

            // Try Currency__r
            SObject currencyObj = record.getSObject(nameSpace + 'Currency__r');
            if (currencyObj != null) {
                return (String) currencyObj.get('ISO_Code__c');
            }
        } catch (Exception e) {
            System.debug('Currency not found: ' + e.getMessage());
        }

        return null;
    }

    private static String buildDynamicQuery(String fieldsToQuery, String objectName, String accountId, Date fromDate, Date toDate, List<String> statuses, String txnType) {
		String nameSpace = getOrgNameSpace();
		String whereClause = '';
		Boolean hasWhereClause = false;

		// Special handling for Journal Lines object
		if (objectName == 'Journal__c') {
			String query = 'SELECT Id, Name, Journal__r.Invoice_Date__c, Journal__r.Transaction_Currency__r.ISO_Code__c, Journal__r.Transaction_Number__c, Account__r.Name FROM Journal_Lines__c WHERE Account__c = \'' + accountId + '\' Order By Name desc';
			return query;
		}

		// Add Invoice Number field in query
		if (doesFieldExist(nameSpace+objectName, nameSpace+'Transaction_Number__c')) {
			fieldsToQuery += ', Transaction_Number__c';
		}

		// Add Gross Amount field in query
		if (doesFieldExist(nameSpace+objectName, nameSpace+'Gross_Amount__c')) {
			fieldsToQuery += ', Gross_Amount__c';
		}


		// Add Customer reference field in query
		if (doesFieldExist(nameSpace+objectName, nameSpace+'Customer_reference__c')) {
			fieldsToQuery += ', Customer_reference__c';
		} else if (doesFieldExist(nameSpace+objectName, nameSpace+'Payment_Reference__c')) {
			fieldsToQuery += ', Payment_Reference__c';
		}

		// Add Status field in query
		// if (doesFieldExist(nameSpace+objectName, nameSpace+'Posting_Status__c')) {
		// 	fieldsToQuery += ', Posting_Status__c';
		// }

		// Add Currency field in query
		if (doesFieldExist(nameSpace+objectName, nameSpace+'Transaction_Currency__c')) {
			fieldsToQuery += ', Transaction_Currency__r.ISO_Code__c';
		} else if (doesFieldExist(nameSpace+objectName, nameSpace+'Currency__c')) {
			fieldsToQuery += ', Currency__r.ISO_Code__c';
		}

		// Add Type field in the query
		// if (doesFieldExist(nameSpace+objectName, nameSpace+'Nature_of_Transaction__c')) {
		// 	fieldsToQuery += ', Nature_of_Transaction__c';
		// }

		// Add outstanding field in the query
		if (doesFieldExist(nameSpace+objectName, nameSpace+'Outstanding_Amount__c')) {
			fieldsToQuery += ', Outstanding_Amount__c';
		} else if (doesFieldExist(nameSpace+objectName, nameSpace+'Amount__c')) {
			fieldsToQuery += ', Amount__c';
		}

		// Add account filter in query
		if (doesFieldExist(nameSpace+objectName, nameSpace+'To_Account__c')) {
			fieldsToQuery += ', To_Account__r.Name';
			whereClause += ' WHERE To_Account__c = \'' + accountId + '\'';
			hasWhereClause = true;
		} else if (doesFieldExist(nameSpace+objectName, nameSpace+'Account__c')) {
			fieldsToQuery += ', Account__r.Name';
			whereClause += ' WHERE Account__c = \'' + accountId + '\'';
			hasWhereClause = true;
		}

		// Add date filter in query
		if (fromDate != null && toDate != null) {
			if (doesFieldExist(namespace+objectName, nameSpace+'Invoice_Date__c')) {
				fieldsToQuery += ', ' + 'Invoice_Date__c';
				if (hasWhereClause) {
					whereClause += ' AND Invoice_Date__c >= '+ String.valueOf(fromDate) + ' AND Invoice_Date__c <= ' + String.valueOf(toDate);
				} else {
					whereClause += ' WHERE Invoice_Date__c >= '+ String.valueOf(fromDate) + ' AND Invoice_Date__c <= ' + String.valueOf(toDate);
					hasWhereClause = true;
				}
			} else if (doesFieldExist(namespace+objectName, nameSpace+'Pay_Date__c')) {
				fieldsToQuery += ', ' + 'Pay_Date__c';
				if (hasWhereClause) {
					whereClause += ' AND Pay_Date__c >= '+ String.valueOf(fromDate) + ' AND Pay_Date__c <= ' + String.valueOf(toDate);
				} else {
					whereClause += ' WHERE Pay_Date__c >= '+ String.valueOf(fromDate) + ' AND Pay_Date__c <= ' + String.valueOf(toDate);
					hasWhereClause = true;
				}
			}
		}

		// Add status filter in query
		if (statuses != null && !statuses.isEmpty()) {
			if (doesFieldExist(namespace+objectName, nameSpace+'Posting_Status__c')) {
				String statusFilter = ' Posting_Status__c IN (';
				for (Integer i = 0; i < statuses.size(); i++) {
					statusFilter += '\'' + statuses[i] + '\'';
					if (i < statuses.size() - 1) {
						statusFilter += ',';
					}
				}
				statusFilter += ')';
				if (hasWhereClause) {
					whereClause += ' AND ' + statusFilter;
				} else {
					whereClause += ' WHERE ' + statusFilter;
					hasWhereClause = true;
				}
			}
		} else {
			if (txnType == 'All') {
				if (doesFieldExist(namespace+objectName, nameSpace+'Posting_Status__c')) {
					if (hasWhereClause) {
						whereClause += ' AND Posting_Status__c != \'Draft\' AND Posting_Status__c != \'Posted\' AND Posting_Status__c != \'Deleted\'';
					} else {
						whereClause += ' WHERE Posting_Status__c != \'Draft\' AND Posting_Status__c != \'Posted\' AND Posting_Status__c != \'Deleted\'';
						hasWhereClause = true;
					}
				}
			}
		}

		// Add filters for outstanding data
		if (txnType == 'Outstanding') {
			if (doesFieldExist(namespace+objectName, nameSpace+'Posting_Status__c')) {
				if (hasWhereClause) {
					whereClause += ' AND Posting_Status__c = \'Posted\'';
				} else {
					whereClause += ' WHERE Posting_Status__c = \'Posted\'';
					hasWhereClause = true;
				}
			}
			if (doesFieldExist(namespace+objectName, nameSpace+'Outstanding_Amount__c')) {
				if (hasWhereClause) {
					whereClause += ' AND Outstanding_Amount__c != 0';
				} else {
					whereClause += ' WHERE Outstanding_Amount__c != 0';
					hasWhereClause = true;
				}
			}
		}

		// Add filters for overdue data
		if (txnType == 'Overdue') {
			if (doesFieldExist(namespace+objectName, nameSpace+'Due_On__c')) {
				// add Due On field in query
				fieldsToQuery += ', Due_On__c';
				if (hasWhereClause) {
					whereClause += ' AND Due_On__c < TODAY';
				} else {
					whereClause += ' WHERE Due_On__c < TODAY';
					hasWhereClause = true;
				}
			}
			if (doesFieldExist(namespace+objectName, nameSpace+'Outstanding_Amount__c')) {
				if (hasWhereClause) {
					whereClause += ' AND Outstanding_Amount__c != 0';
				} else {
					whereClause += ' WHERE Outstanding_Amount__c != 0';
					hasWhereClause = true;
				}
			}
		}

		// Add filters for paid invoice data
		if (txnType == 'Paid Invoice') {
			if (doesFieldExist(namespace+objectName, nameSpace+'Outstanding_Amount__c')) {
				if (hasWhereClause) {
					whereClause += ' AND Outstanding_Amount__c = 0';
				} else {
					whereClause += ' WHERE Outstanding_Amount__c = 0';
					hasWhereClause = true;
				}
			}
		}

		if (txnType == 'Credit Notes') {
			if (doesFieldExist(nameSpace+objectName, nameSpace+'Posting_Status__c')) {
				if (hasWhereClause) {
					whereClause += ' AND Posting_Status__c IN (\'Posted\', \'Draft\')';
				} else {
					whereClause += ' WHERE Posting_Status__c IN (\'Posted\', \'Draft\')';
					hasWhereClause = true;
				}
			}
		}

		String query = 'SELECT ' + fieldsToQuery + ' FROM ' + objectName + whereClause + ' Order By Name desc';
		return query;
	}

    private static String getOrgNameSpace(){
		return UtilsController.getNameSpace();
	}

    private static Boolean doesFieldExist(String objectApiName, String fieldApiName) {
		Map<String, Schema.SObjectType> objects = Schema.getGlobalDescribe();

		if (!objects.containsKey(objectApiName)) {
			return false; // Object doesn't exist
		}

		Schema.DescribeSObjectResult objDescribe =
			objects.get(objectApiName).getDescribe();

		return objDescribe.fields.getMap().containsKey(fieldApiName);
	}
}
