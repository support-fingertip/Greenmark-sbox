@isTest
public class TATCalculationHelperTest {

    @testSetup
    static void setupData() {
        // Project with TAT thresholds: 1hr pre-sales, 1hr sales call, 2hr follow-up.
        Project__c proj = new Project__c(
            Name = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c = true,
            Pre_Sales_TAT_Hours__c = 1,
            Sales_TAT_Hours__c = 1,
            Sales_Followup_TAT_Hours__c = 2
        );
        insert proj;

        Id preSalesRt = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
        Id salesRt    = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();

        // Lead breached on call: assigned 3 hours ago (threshold 1hr).
        Lead breached = new Lead(
            LastName = 'Breached Lead',
            Company = 'Test Co',
            Source_Type__c = 'Website',
            RecordTypeId = preSalesRt,
            Allocated_Project__c = 'Trifecta Vanto',
            Lead_Assigned_Time__c = System.now().addHours(-3)
        );
        // Lead within TAT: assigned 10 minutes ago.
        Lead withinTat = new Lead(
            LastName = 'Within Lead',
            Company = 'Test Co',
            Source_Type__c = 'Website',
            RecordTypeId = salesRt,
            Allocated_Project__c = 'Trifecta Vanto',
            Lead_Assigned_Time__c = System.now().addMinutes(-10)
        );
        insert new List<Lead>{ breached, withinTat };
    }

    @isTest
    static void testCallTAT_breachAndWithin() {
        Lead breached = [SELECT Id FROM Lead WHERE LastName = 'Breached Lead' LIMIT 1];
        Lead within   = [SELECT Id FROM Lead WHERE LastName = 'Within Lead' LIMIT 1];

        Test.startTest();
        Call_Detail__c cdBreach = new Call_Detail__c(Lead__c = breached.Id);
        insert cdBreach;
        Call_Detail__c cdWithin = new Call_Detail__c(Lead__c = within.Id);
        insert cdWithin;
        Test.stopTest();

        Lead b = [SELECT Call_TAT_Breached__c, Actual_Call_TAT_Hours__c FROM Lead WHERE Id = :breached.Id];
        Lead w = [SELECT Call_TAT_Breached__c, Actual_Call_TAT_Hours__c FROM Lead WHERE Id = :within.Id];

        System.assertEquals(true, b.Call_TAT_Breached__c, 'Lead assigned 3h ago should breach a 1h TAT');
        System.assert(b.Actual_Call_TAT_Hours__c >= 2.5, 'Actual hours should be ~3');
        System.assertEquals(false, w.Call_TAT_Breached__c, 'Lead called within 10m should not breach a 1h TAT');
    }

    @isTest
    static void testFollowupTAT_breach() {
        Lead breached = [SELECT Id FROM Lead WHERE LastName = 'Breached Lead' LIMIT 1];

        Test.startTest();
        Follow_up__c fu = new Follow_up__c(SLead__c = breached.Id);
        insert fu;
        // A second follow-up should not overwrite the first-followup capture.
        Follow_up__c fu2 = new Follow_up__c(SLead__c = breached.Id);
        insert fu2;
        Test.stopTest();

        Lead b = [SELECT First_Followup_Time__c, Followup_TAT_Breached__c, Actual_Followup_TAT_Hours__c
                  FROM Lead WHERE Id = :breached.Id];

        System.assertNotEquals(null, b.First_Followup_Time__c, 'First follow-up time should be captured');
        System.assertEquals(true, b.Followup_TAT_Breached__c, 'Lead assigned 3h ago should breach a 2h follow-up TAT');
    }

    @isTest
    static void testNoThreshold_noBreach() {
        // Project without TAT values -> no breach should be flagged.
        Project__c proj2 = new Project__c(
            Name = 'No TAT Project',
            Project__c = 'No TAT Project',
            Active__c = true
        );
        insert proj2;

        Id salesRt = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Lead ld = new Lead(
            LastName = 'No TAT Lead',
            Company = 'Test Co',
            Source_Type__c = 'Website',
            RecordTypeId = salesRt,
            Allocated_Project__c = 'No TAT Project',
            Lead_Assigned_Time__c = System.now().addHours(-5)
        );
        insert ld;

        Test.startTest();
        insert new Call_Detail__c(Lead__c = ld.Id);
        Test.stopTest();

        Lead result = [SELECT Call_TAT_Breached__c FROM Lead WHERE Id = :ld.Id];
        System.assertEquals(false, result.Call_TAT_Breached__c, 'No threshold configured -> no breach');
    }
}
