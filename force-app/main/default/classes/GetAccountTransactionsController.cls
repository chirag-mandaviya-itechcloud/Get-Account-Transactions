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

	@AuraEnabled
	public static Account getAccountDetails(String recordId) {
		Account acc = [SELECT Id, Account_Balance__c FROM Account WHERE Id = :recordId LIMIT 1];
		return acc;
	}

}
