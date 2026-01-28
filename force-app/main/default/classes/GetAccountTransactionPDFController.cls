public class GetAccountTransactionPDFController {
	public String templateHtml { get; set; }
    public String queriesString { get; set; } 
    
    public GetAccountTransactionPDFController() {
        Id contactId   = ApexPages.currentPage().getParameters().get('contactId');
        Id whatId      = ApexPages.currentPage().getParameters().get('whatId');
        String devName = ApexPages.currentPage().getParameters().get('templateDevName');
        String queries = ApexPages.currentPage().getParameters().get('queries');
        
        System.debug('Queries ---> '+ queries);
        queriesString = queries;

        if (String.isNotBlank(devName)) {
            Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :devName LIMIT 1].Id;
            Messaging.SingleEmailMessage mail =
                Messaging.renderStoredEmailTemplate(templateId, contactId, whatId);
            templateHtml = mail.getHtmlBody();
        }
    }
}