 /**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : GetAccountTransactionsController
 * Author          : <YourName>
 * Created Date    : Jan 7, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Jan 7, 2026
 * Description     : This class implements for......
 *
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jan 7, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class GetAccountTransactionsController {

	public class TransactionDataWrapper {
		@AuraEnabled public String objectName { get; set; }
		@AuraEnabled public String displayLabel { get; set; }
		@AuraEnabled public List<SObject> records { get; set; }
		@AuraEnabled public Integer recordCount { get; set; }
		@AuraEnabled public List<String> fieldNames { get; set; }
		@AuraEnabled public String query { get; set; }
	}

	@AuraEnabled
	public static Account getAccountDetails(String recordId) {
		try {
			Account acc = [SELECT Id, Account_Balance__c FROM Account WHERE Id = :recordId LIMIT 1];
			return acc;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static List<String> getAllTransactionMasterObject(){
		try {
			List<Transaction_Type__c> transactionTypes = [SELECT Id, Transaction_Master_Object__c FROM Transaction_Type__c];

			Set<String> transactionObjectNames = new Set<String>();
			String nameSpace = getOrgNameSpace();
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

			for (Transaction_Type__c typ : transactionTypes) {
				if (typ.Transaction_Master_Object__c != null){
					String fullObjectName = nameSpace + typ.Transaction_Master_Object__c;
					if (globalDescribe.containsKey(fullObjectName)) {
                        transactionObjectNames.add(typ.Transaction_Master_Object__c);
					}
				}
			}
			return new List<String>(transactionObjectNames);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static List<String> getTransactionMasterObject(){
		// Used method for Outstanding and Overdue and Paid Invoice
		try {
			List<Transaction_Type__c> transactionTypes = [SELECT Id, Transaction_Master_Object__c FROM Transaction_Type__c WHERE s2p3__Transaction_Category__c = 'Primary'];

			Set<String> transactionObjectNames = new Set<String>();
			String nameSpace = getOrgNameSpace();
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

			for (Transaction_Type__c typ : transactionTypes) {
				if (typ.Transaction_Master_Object__c != null){
					String fullObjectName = nameSpace + typ.Transaction_Master_Object__c;
					if (globalDescribe.containsKey(fullObjectName)) {
                        transactionObjectNames.add(typ.Transaction_Master_Object__c);
					}
				}
			}
			return new List<String>(transactionObjectNames);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static List<String> getCreditTransactionMasterObject(){
		try {
			List<Transaction_Type__c> transactionTypes = [SELECT Id, Transaction_Master_Object__c FROM Transaction_Type__c WHERE Nature_of_Accounting__c = 'Credit' AND Transaction_Category__c = 'Primary'];

			Set<String> transactionObjectNames = new Set<String>();
			String nameSpace = getOrgNameSpace();
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

			for (Transaction_Type__c typ : transactionTypes) {
				if (typ.Transaction_Master_Object__c != null){
					String fullObjectName = nameSpace + typ.Transaction_Master_Object__c;
					if (globalDescribe.containsKey(fullObjectName)) {
                        transactionObjectNames.add(typ.Transaction_Master_Object__c);
					}
				}
			}
			return new List<String>(transactionObjectNames);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static List<String> getRAPTransactionMasterObject(){
		try {
			List<Transaction_Type__c> transactionTypes = [SELECT Id, Transaction_Master_Object__c FROM Transaction_Type__c WHERE Transaction_Category__c = 'Secondary'];

			Set<String> transactionObjectNames = new Set<String>();
			String nameSpace = getOrgNameSpace();
			Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

			for (Transaction_Type__c typ : transactionTypes) {
				if (typ.Transaction_Master_Object__c != null) {
					String fullObjectName = nameSpace + typ.Transaction_Master_Object__c;
					if (globalDescribe.containsKey(fullObjectName)) {
						transactionObjectNames.add(typ.Transaction_Master_Object__c);
					}
				}
			}
			return new List<String>(transactionObjectNames);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static List<String> getJournalTransactionMasterObject() {
		try {
			List<Transaction_Type__c> transactionTypes = [SELECT Id, Transaction_Master_Object__c FROM Transaction_Type__c WHERE Transaction_Category__c = 'Journal'];

			Set<String> transactionObjectNames = new Set<String>();
			String nameSpace = getOrgNameSpace();
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

			for (Transaction_Type__c typ : transactionTypes) {
				if (typ.Transaction_Master_Object__c != null){
					String fullObjectName = nameSpace + typ.Transaction_Master_Object__c;
					if (globalDescribe.containsKey(fullObjectName)) {
						transactionObjectNames.add(typ.Transaction_Master_Object__c);
					}
				}
			}
			return new List<String>(transactionObjectNames);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	private static String buildDynamicQuery(String fieldsToQuery, String objectName, String accountId, Date fromDate, Date toDate, List<String> statuses, String txnType) {
		String nameSpace = getOrgNameSpace();
		String whereClause = '';
		Boolean hasWhereClause = false;

		// Special handling for Journal Lines object
		if (objectName == 'Journal__c') {
			String query = 'SELECT Id, Name, Journal__r.Invoice_Date__c, Journal__r.Nature_of_Transaction__c, Journal__r.Customer_reference__c, Journal__r.Transaction_Currency__r.ISO_Code__c, Journal__r.Posting_Status__c FROM Journal_Lines__c WHERE Account__c = \'' + accountId + '\' Order By Name desc';
			return query;
		}

		// Add Invoice Number field in query
		if (doesFieldExist(nameSpace+objectName, nameSpace+'Transaction_Number__c ')) {
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
			fieldsToQuery += ', To_Account__c';
			whereClause += ' WHERE To_Account__c = \'' + accountId + '\'';
			hasWhereClause = true;
		} else if (doesFieldExist(nameSpace+objectName, nameSpace+'Account__c')) {
			fieldsToQuery += ', Account__c';
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

	@AuraEnabled
	public static TransactionDataWrapper getTransactionMasterObjectData(String objectName, String accountId, Date fromDate, Date toDate, List<String> statuses, String txnType){
		try {
			String nameSpace = getOrgNameSpace();
        	String fullObjectName = nameSpace + objectName;

			if (!objectExists(fullObjectName)) {
				System.debug('Object does not exist: ' + fullObjectName);
				TransactionDataWrapper emptyWrapper = new TransactionDataWrapper();
                emptyWrapper.objectName = objectName;
                emptyWrapper.displayLabel = objectName;
                emptyWrapper.records = new List<SObject>();
                emptyWrapper.recordCount = 0;
				emptyWrapper.fieldNames = new List<String>();
				emptyWrapper.query = '';
                return emptyWrapper;
			}

			String fieldsToQuery = 'Id, Name';
			String query = buildDynamicQuery(fieldsToQuery, objectName, accountId, fromDate, toDate, statuses, txnType);

			System.debug('Query: '+ query);

			List<SObject> records = Database.query(query);

			// Extract field names from the query
			List<String> queriedFields = extractFieldNamesFromQuery(query, fullObjectName, nameSpace);

			// Create wrapper
			TransactionDataWrapper wrapper = new TransactionDataWrapper();
			wrapper.objectName = objectName;
			wrapper.displayLabel = getObjectLabel(fullObjectName);
			wrapper.records = records;
			wrapper.recordCount = records.size();
			wrapper.fieldNames = queriedFields;
			wrapper.query = query;

			return wrapper;

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	private static List<String> extractFieldNamesFromQuery(String query, String objectName, String nameSpace) {
		List<String> fieldNames = new List<String>();

		String selectClause = query.substringBetween('SELECT ', ' FROM ');
		if (selectClause != null) {
			List<String> fields = selectClause.split(',');

			for (String field : fields) {
				field = field.trim();

				if (field.contains('.')) {
					List<String> fieldParts = field.split('\\.');
					List<String> namespacedParts = new List<String>();

					for (String part : fieldParts) {
						if (!part.startsWith(nameSpace)) {
							namespacedParts.add(nameSpace + part);
						} else {
							namespacedParts.add(part);
						}
					}

					// Join back with dot
					String namespacedField = String.join(namespacedParts, '.');
					fieldNames.add(namespacedField);
				} else {
					if (field == 'Name' || field == 'Id') {
						fieldNames.add(field);
					} else {
						fieldNames.add(nameSpace+field);
					}
				}
			}
		}
		return fieldNames;
	}

	private static Boolean objectExists(String objectApiName) {
		Map<String, Schema.SObjectType> objects = Schema.getGlobalDescribe();
		return objects.containsKey(objectApiName);
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

	private static String getOrgNameSpace(){
		return UtilsController.getNameSpace();
	}

	private static String getObjectLabel(String objectApiName) {
		try {
			Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe()
				.get(objectApiName)
				.getDescribe();
			return objDescribe.getLabel();
		} catch (Exception e) {
			return objectApiName; // Fallback to API name
		}
	}
}
