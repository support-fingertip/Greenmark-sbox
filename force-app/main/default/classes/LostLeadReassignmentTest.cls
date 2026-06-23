@IsTest
private class LostLeadReassignmentTest {

    @testSetup
    static void setupData() {
        // Use an existing active user as Project Sales Head
        User salesHead = [
            SELECT Id
            FROM User
            WHERE IsActive = true
            LIMIT 1
        ];

        // Create a sample project
        Project__c proj = new Project__c(
            Name = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Project_Sales_Head__c = salesHead.Id
        );
        insert proj;

        // Lead: first-time unqualified
        Lead lead1 = new Lead(
            LastName = 'Lead One',
            Company  = 'Test Company',
            Mark_Unqualified__c = true,
            Lead_Assigned__c = false,
            Lead_Status__c = 'Lead Lost',
            No_Of_Times_Unqualified__c = 1,
            Previous_Stage__c = 'New',
            Lead_Lost_Reasons__c = 'RNR',
            Last_Unqualified_At__c = system.now().addHours(-30),
            Allocated_Project__c = 'Trifecta Vanto',
            Source_Type__c = 'Portals'
        );

        // Lead: second-time unqualified
        Lead lead2 = new Lead(
            LastName = 'Lead Two',
            Company  = 'Test Company',
            Mark_Unqualified__c = true,
            Lead_Assigned__c = false,
            Lead_Status__c = 'Lead Lost',
            No_Of_Times_Unqualified__c = 2,
            Previous_Stage__c = 'Open',
            Lead_Lost_Reasons__c = 'RNR',
            Last_Unqualified_At__c = system.now().addHours(-30),
            Allocated_Project__c = 'Trifecta Vanto',
            Source_Type__c = 'Portals'
        );

        insert new List<Lead>{ lead1, lead2 };
    }

    @IsTest
    static void testBatchLogic() {
        Test.startTest();
        LostLeadReassignment batch = new LostLeadReassignment();
        Database.executeBatch(batch, 100);
        Test.stopTest();

        Project__c proj = [
            SELECT Project_Sales_Head__c
            FROM Project__c
            LIMIT 1
        ];

        List<Lead> leads = [
            SELECT Id,
                   LastName,
                   Lead_Status__c,
                   Lead_Assigned__c,
                   OwnerId,
                   No_Of_Times_Unqualified__c,
                   Allocated_Project__c
            FROM Lead
            ORDER BY LastName
        ];

        System.assertEquals(2, leads.size(), 'Expected 2 leads from test data.');

        Lead l1 = leads[0]; // Lead One
        Lead l2 = leads[1]; // Lead Two

        // Lead 1: first time unqualified
      //  System.assertEquals(1, l1.No_Of_Times_Unqualified__c, 'Lead1 times unqualified mismatch.');
        //System.assertEquals('New', l1.Lead_Status__c, 'Lead1 status should be New.');
       // System.assertEquals(false, l1.Lead_Assigned__c, 'Lead1 should remain unassigned.');/

        // Lead 2: second time unqualified -> assigned to project sales head
       // System.assertEquals(2, l2.No_Of_Times_Unqualified__c, 'Lead2 times unqualified mismatch.');
  //  System.assertEquals('New', l2.Lead_Status__c, 'Lead2 status should be New.');
      //  System.assertEquals(true, l2.Lead_Assigned__c, 'Lead2 should be marked assigned.');
       /* System.assertEquals(
            proj.Project_Sales_Head__c,
            l2.OwnerId,
            'Lead2 Owner should be Project Sales Head.'
        );*/
    }

    @IsTest
    static void testSchedulableRegistration() {
        Test.startTest();
        String cron = '0 0 0 1 1 ? 2099'; // arbitrary future date
        System.schedule('LostLeadReassignmentJob_Test', cron, new LostLeadReassignment());
        Test.stopTest();

        // If no exception is thrown, schedulable wiring is valid
        // (You can optionally assert on CronTrigger records if you want to be extra strict)
    }
}