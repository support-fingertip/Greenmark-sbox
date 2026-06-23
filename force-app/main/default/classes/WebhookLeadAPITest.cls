@isTest
public class WebhookLeadAPITest {
   @isTest
    static void testCreateLead() {
        
        // Create a valid campaign that your controller expects
        Campaign cmp = new Campaign(
            Name = 'Summer Campaign',
            IsActive = true,
            Source__c = 'Google',
            Sub_Source__c = 'Search Ads',
            Project_Name__c = 'Trifecta Vanto'   
        );
        insert cmp;

        // Prepare wrapper data
        WebhookLeadAPI.leadWrapper testLead = new WebhookLeadAPI.leadWrapper();
        testLead.f_name = 'Test';
        testLead.source     = 'Website';
        testLead.subSource  = 'Website Lead Form';
        testLead.phonefax     = '7755222256';
        testLead.email      = 'testuser7755222256@example.com';
        testLead.project    = 'Trifecta Vanto';

       
        // Serialize to JSON
        String jsonBody = JSON.serialize(testLead);
        
        // Mock REST context
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/WebhookLead/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Execute method
        Test.startTest();
        WebhookLeadAPI.createLead();
        Test.stopTest();
        
        // Validate Lead created
        Lead insertedLead = [
            SELECT Id, LastName, Phone__c, Lead_source__c, Campaign__c 
            FROM Lead 
            WHERE LastName = 'Test'
            LIMIT 1
        ];

        System.assertNotEquals(null, insertedLead.Id);
        System.assertEquals('7755222256', insertedLead.Phone__c);
        System.assertEquals('Website Lead Form', insertedLead.Lead_source__c);

        // Validate log entry
        Apex_Log__c log = [
            SELECT Status__c, Request_Type__c 
            FROM Apex_Log__c 
            ORDER BY CreatedDate DESC LIMIT 1
        ];
        System.assertEquals('SUCCESS', log.Status__c);
        System.assert(log.Request_Type__c.contains('WebhookLead'));
    }
}