@isTest
private class WebsiteAPIControllerTest {
    
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
        WebsiteAPIController.leadWrapper testLead = new WebsiteAPIController.leadWrapper();
        testLead.firstName = 'Test';
        testLead.lastName  = 'User';
        testLead.source     = 'Website';
        testLead.subSource  = 'Search Ads';
        testLead.mobile     = '9876543210';
        testLead.email      = 'testuser@example.com';
        testLead.project    = 'Trifecta Vanto';

        // Use campaignName (controller will use this branch)
        testLead.campaignName = 'Summer Campaign';

        // Serialize to JSON
        String jsonBody = JSON.serialize(testLead);
        
        // Mock REST context
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/WebsiteLead/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Execute method
        Test.startTest();
        WebsiteAPIController.createLead();
        Test.stopTest();
        
        // Validate Lead created
        Lead insertedLead = [
            SELECT Id, LastName, Phone__c, Lead_source__c, Campaign__c 
            FROM Lead 
            WHERE LastName = 'User'
            LIMIT 1
        ];

        System.assertNotEquals(null, insertedLead.Id);
        System.assertEquals('9876543210', insertedLead.Phone__c);
        System.assertEquals('Search Ads', insertedLead.Lead_source__c);
        System.assertEquals('Summer Campaign', insertedLead.Campaign__c);

        // Validate log entry
        Apex_Log__c log = [
            SELECT Status__c, Request_Type__c 
            FROM Apex_Log__c 
            ORDER BY CreatedDate DESC LIMIT 1
        ];
        System.assertEquals('SUCCESS', log.Status__c);
        System.assert(log.Request_Type__c.contains('WebsiteLead'));
    }
}