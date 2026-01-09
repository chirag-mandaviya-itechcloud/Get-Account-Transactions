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
	public static List<String> getOutstandingTransactionMasterObject(){
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

	private static String buildDynamicQuery(String fieldsToQuery, String objectName, String accountId, Date fromDate, Date toDate, List<String> statuses, String txnType) {
		String nameSpace = getOrgNameSpace();
		String whereClause = '';
		Boolean hasWhereClause = false;

		// Add Customer reference field in query
		if (doesFieldExist(nameSpace+objectName, nameSpace+'Customer_Reference__c')) {
			fieldsToQuery += ', Customer_Reference__c';
		} else if (doesFieldExist(nameSpace+objectName, nameSpace+'Payment_Reference__c')) {
			fieldsToQuery += ', Payment_Reference__c';
		}

		// Add Status field in query
		if (doesFieldExist(nameSpace+objectName, nameSpace+'posting_status__c')) {
			fieldsToQuery += ', posting_status__c';
		}

		// Add Currency field in query
		if (doesFieldExist(nameSpace+objectName, nameSpace+'Transaction_Currency__c')) {
			fieldsToQuery += ', Transaction_Currency__r.ISO_Code__c';
		} else if (doesFieldExist(nameSpace+objectName, nameSpace+'Currency__c')) {
			fieldsToQuery += ', Currency__r.ISO_Code__c';
		}

		// Add Type field in the query
		if (doesFieldExist(nameSpace+objectName, nameSpace+'Nature_of_Transaction__c')) {
			fieldsToQuery += ', Nature_of_Transaction__c';
		}

		// Add account filter in query
		if (doesFieldExist(nameSpace+objectName, nameSpace+'To_Account__c')) {
			whereClause += ' WHERE To_Account__c = \'' + accountId + '\'';
			hasWhereClause = true;
		} else if (doesFieldExist(nameSpace+objectName, nameSpace+'Account__c')) {
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
                return emptyWrapper;
			}

			String fieldsToQuery = 'Id, Name';
			String query = buildDynamicQuery(fieldsToQuery, objectName, accountId, fromDate, toDate, statuses, txnType);

			System.debug('Query: '+ query);

			List<SObject> records = Database.query(query);

			// Create wrapper
			TransactionDataWrapper wrapper = new TransactionDataWrapper();
			wrapper.objectName = objectName;
			wrapper.displayLabel = getObjectLabel(fullObjectName);
			wrapper.records = records;
			wrapper.recordCount = records.size();

			return wrapper;

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
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
