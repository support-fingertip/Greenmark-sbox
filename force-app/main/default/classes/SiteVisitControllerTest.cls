@isTest
public class SiteVisitControllerTest {
@isTest
    public static void testmethodst(){
        Lead ld = new Lead(
            LastName = 'Test',
            Company = 'testcompany',
            Phone__c = '8778987789',
            Source_Type__c = 'Google',
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert ld;
        List<Site_Visit__c> sv = New List<Site_Visit__c>();
        
          Site_Visit__c sv1 = new Site_Visit__c(
            Slead__c = ld.Id,
            OTP__c = '0000'
        );
        insert sv1;
        sv.add(sv1);
        SiteVisitController.checkSiteVisitForRoundRobin(sv);

    }
}