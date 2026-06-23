@IsTest
public class LeadGlobalSearchControllerTest {

    @testSetup
    static void setupData() {

        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'testuser' + System.currentTimeMillis() + '@test.com'
        );
        insert u;

        // Create Lead
        Lead ld = new Lead(
            LastName = 'Search Lead',
            Company = 'Test Company',
            Phone__c = '9999999999',
            Secondary_Phone__c = '8888888888',
            Email = 'lead@test.com',
            Lead_Status__c = 'Open',
            Allocated_Project__c = 'Trifecta Vanto',
            Source_Type__c ='Website',
            Status = 'Open'
        );
        insert ld;

        // Create Related Source
        Related_Source__c rs = new Related_Source__c(
            SLead__c = ld.Id,
            Phone__c = '7777777777',
            Secondary_Phone__c = '6666666666'
        );
        insert rs;
    }

    @IsTest
    static void testSearchByName() {

        Test.startTest();
        List<LeadGlobalSearchController.LeadSearchWrapper> results =
            LeadGlobalSearchController.searchLead('Search');
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('Search Lead', results[0].name);
    }

    @IsTest
    static void testSearchByPhone() {

        Test.startTest();
        List<LeadGlobalSearchController.LeadSearchWrapper> results =
            LeadGlobalSearchController.searchLead('9999999999');
        Test.stopTest();

    }

    @IsTest
    static void testSearchByRelatedSourcePhone() {

        Test.startTest();
        List<LeadGlobalSearchController.LeadSearchWrapper> results =
            LeadGlobalSearchController.searchLead('7777777777');
        Test.stopTest();

   
    }

    @IsTest
    static void testBlankSearchText() {

        Test.startTest();
        List<LeadGlobalSearchController.LeadSearchWrapper> results =
            LeadGlobalSearchController.searchLead('');
        Test.stopTest();

     
    }

    @IsTest
    static void testShowOpenLeadAccess() {

        Lead ld = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        List<LeadGlobalSearchController.LeadSearchWrapper> results =
            LeadGlobalSearchController.searchLead('Search');
        Test.stopTest();

    }
}