@isTest
public class LeadDedupBatchTest {
    
    @testSetup
    static void setupData() {
        List<Lead> leadsToInsert = new List<Lead>();
        
        // Duplicates for Phone__c = '111'
        leadsToInsert.add(new Lead(
            LastName='Lead1', 
            Company='TestCo', 
            Phone__c='111',
            Allocated_Project__c='Trifecta Vanto', 
            Lead_source__c='Website', 
            Tertiary_Source__c='Sub1', 
            Source_Type__c = 'Google'
        ));
        leadsToInsert.add(new Lead(
            LastName='Lead2', 
            Company='TestCo', 
            Phone__c='111',
            Allocated_Project__c='Trifecta Vanto', 
            Lead_source__c='Website', 
            Tertiary_Source__c='Sub2', 
            Source_Type__c = 'Google'
        ));
        leadsToInsert.add(new Lead(
            LastName='Lead3', 
            Company='TestCo', 
            Phone__c='111',
            Allocated_Project__c='Trifecta Vanto', 
            Lead_source__c='Website', 
            Tertiary_Source__c='Sub3', 
            Source_Type__c = 'Google'
        ));
        
        // Unique Lead
        leadsToInsert.add(new Lead(
            LastName='Lead4', 
            Company='TestCo', 
            Phone__c='222',
            Allocated_Project__c='Trifecta Vanto', 
            Lead_source__c='Website', 
            Tertiary_Source__c='Sub4', 
            Source_Type__c = 'Google'
        ));
        
        insert leadsToInsert;
    }
    
    @isTest
    static void testDedupBatch() {
        // Set a mock for HTTP callouts, just in case triggers or future methods fire one
        Test.setMock(HttpCalloutMock.class, new RestMock());
        
        Test.startTest();
        
        // Execute the batch
        LeadDedupBatch batch = new LeadDedupBatch();
        Database.executeBatch(batch, 50);
        
        Test.stopTest();
        
        // Verify surviving Lead for phone 111
        List<Lead> leads111 = [SELECT Id, Phone__c FROM Lead WHERE Phone__c = '111'];
        System.assertEquals(1, leads111.size(), 'Only one lead with Phone__c=111 should remain');
        
        // Verify unique lead untouched
        List<Lead> leads222 = [SELECT Id, Phone__c FROM Lead WHERE Phone__c = '222'];
        System.assertEquals(1, leads222.size(), 'Lead with Phone__c=222 should remain untouched');
        
        // Verify Related_Source__c records
        List<Related_Source__c> sources = [SELECT Id, SLead__c, Phone__c, Allocated_Project__c, Source__c, Sub_Source__c
                                           FROM Related_Source__c
                                           WHERE SLead__c = :leads111[0].Id];
       // System.assertEquals(3, sources.size(), 'Related_Source__c should be created for main and duplicate leads');
        
        // Confirm duplicates were deleted
        List<Lead> deletedLeads = [SELECT Id FROM Lead WHERE Phone__c = '111' AND Id != :leads111[0].Id];
        System.assertEquals(0, deletedLeads.size(), 'All duplicate leads should be deleted');
    }
    
    // Simple mock for HTTP callouts
    private class RestMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }
}