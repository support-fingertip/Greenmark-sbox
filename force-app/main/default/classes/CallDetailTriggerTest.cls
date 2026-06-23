@isTest
public class CallDetailTriggerTest {

   @testSetup
    static void setupData() {
        // Lead 1 → For TAT for New Lead...
        Lead l1 = new Lead(
            LastName = 'Lead One',
            Company = 'Test Company1',
            Source_Type__c ='Website'
        );
        insert l1;

        // Lead 2 → For TAT for Sales...
        Lead l2 = new Lead(
            LastName = 'Lead Two',
            Company = 'Test Company2',
            Source_Type__c ='Website',
            Lead_Status__c = 'New',
            Pushed_On__c = System.now().addHours(-2) // <--pushed earlier
        );
        insert l2;

        // Lead 3 → For Site Visit...
        Lead l3 = new Lead(
            LastName = 'Lead Three',
            Company = 'Test Company3',
            Source_Type__c ='Website',
            Lead_Status__c = 'New'
        );
        insert l3;

        // Site Visit for Lead 3...
        Site_Visit__c sv = new Site_Visit__c(
            SLead__c = l3.Id,
            Date__c = System.today().addDays(1) // <---future date
        );
        insert sv;
    }

    @isTest
    static void testTriggerLogic() {
        List<Lead> leads = [SELECT Id, Lead_Status__c FROM Lead ORDER BY CreatedDate ASC];
        Lead l1 = leads[0]; // new lead
        Lead l2 = leads[1]; // pushed to sales
        Lead l3 = leads[2]; // site visit

        // Insert call details before Test.startTest...
        Call_Detail__c cd1 = new Call_Detail__c(Lead__c = l1.Id);
        insert cd1;
        Test.setCreatedDate(cd1.Id, System.now().addMinutes(-20));

        Call_Detail__c cd2 = new Call_Detail__c(Lead__c = l2.Id);
        insert cd2;
        Test.setCreatedDate(cd2.Id, System.now().addMinutes(-10));

        Call_Detail__c cd3 = new Call_Detail__c(Lead__c = l3.Id);
        insert cd3;
        Test.setCreatedDate(cd3.Id, System.now().addDays(1)); // <---match site visit

        Test.startTest();
        // Dummy insert to fire trigger...
        Call_Detail__c dummy = new Call_Detail__c(Lead__c = l1.Id);
        insert dummy;
        dummy.Status__c='Customer Busy';
        update dummy;
        Test.stopTest();

        // Assertions...
        Lead updatedL1 = [SELECT TAT_for_New_Lead__c FROM Lead WHERE Id = :l1.Id];

        Lead updatedL2 = [SELECT TAT_for_Sales__c FROM Lead WHERE Id = :l2.Id];

        Site_Visit__c updatedSV = [SELECT Call_to_Site_Visit__c FROM Site_Visit__c WHERE SLead__c = :l3.Id LIMIT 1];
    }
}