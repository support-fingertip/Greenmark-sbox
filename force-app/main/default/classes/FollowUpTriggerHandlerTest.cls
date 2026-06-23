@IsTest
public class FollowUpTriggerHandlerTest {

    @testSetup
    static void setupData() {

        // Create Lead
        Lead ld = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Status = 'Open',
            Source_Type__c ='Website'
        );
        insert ld;

        // Create Follow-up record
        Follow_up__c flp = new Follow_up__c(
            SLead__c = ld.Id,
            Status__c = 'scheduled',
            Comments__c = 'Initial follow-up comment',
            Subject__c = 'Test',
            Scheduled_Date__c = System.now().addMinutes(5)
        );
        insert flp;
    }

    @IsTest
    static void testBeforeInsertLogic() {

        Lead ld = [SELECT Id FROM Lead LIMIT 1];

        Follow_up__c flp = new Follow_up__c(
            SLead__c = ld.Id,
            Status__c = 'scheduled',
            Comments__c = 'Before insert test',
            Subject__c = 'Test',
            Scheduled_Date__c = System.now().addMinutes(5)
        );

        Test.startTest();
        insert flp;
        Test.stopTest();

        Follow_up__c insertedFlp = [
            SELECT Project_Name1__c, Lead_Stage__c
            FROM Follow_up__c
            WHERE Id = :flp.Id
        ];

    }

    @IsTest
    static void testAfterUpdateCompletedStatus() {

        Follow_up__c flp = [
            SELECT Id, SLead__c, Status__c
            FROM Follow_up__c
            LIMIT 1
        ];

        Test.startTest();
        flp.Status__c = 'Completed';
        flp.Comments__c = 'Site visit completed successfully';
        update flp;
        Test.stopTest();

        Lead updatedLead = [
            SELECT Last_Note__c
            FROM Lead
            WHERE Id = :flp.SLead__c
        ];
    }

    @IsTest
    static void testMultipleFollowUpsSameLead() {

        Lead ld = [SELECT Id FROM Lead LIMIT 1];

        List<Follow_up__c> followUps = new List<Follow_up__c>();

        for (Integer i = 0; i < 2; i++) {
            followUps.add(new Follow_up__c(
                SLead__c = ld.Id,
                Status__c = 'scheduled',
                Comments__c = 'Follow-up ' + i,
                Subject__c = 'Test',
                Scheduled_Date__c = System.now().addMinutes(5)
            ));
        }

        insert followUps;

        Test.startTest();
        for (Follow_up__c flp : followUps) {
            flp.Status__c = 'Completed';
        }
        update followUps;
        Test.stopTest();

        Lead updatedLead = [
            SELECT Last_Note__c
            FROM Lead
            WHERE Id = :ld.Id
        ];

    }
}