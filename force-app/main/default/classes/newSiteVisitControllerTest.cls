@isTest
public class newSiteVisitControllerTest {
    @isTest
    public static void newSiteVisit(){
        Lead ld = new Lead(
            LastName = 'Test',
            Company = 'testcompany',
            Phone__c = '8778987789',
            Source_Type__c = 'Google',
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert ld;
        
        Site_visit__c sv = new Site_visit__c(
        Status__c = 'Scheduled',
            SLead__c = ld.Id,
            SV_Completed_Date_Time__c = Date.today()
           // Status__c ='Completed'
        
        );
        insert sv;
        
         Site_visit__c sv1 = new Site_visit__c(
        
            SLead__c = ld.Id,
            SV_Completed_Date_Time__c = Date.today(),
            Status__c ='Completed'
        
        );
        insert sv1;
         Site_visit__c sv2 = new Site_visit__c(
        
            SLead__c = ld.Id,
            SV_Completed_Date_Time__c = Date.today(),
            Status__c ='SV Proposed'
        
        );
        insert sv2;
        
        Test.setMock(HttpCalloutMock.class, new RestMock());
        
        newSiteVisitController.getLeadDetails(ld.Id);
        newSiteVisitController.saveSiteVisit(sv);
        newSiteVisitController.getPicklistValuesForField('Lead', 'LeadSource');
    }

    private class RestMock implements HttpCalloutMock {
 
        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = 'your Json Response';
 
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
}