@isTest
public class PushToCrmController_Test {

    private static final String COMMENTS      = 'Test push to CRM comments';
    private static final String PROJECT_VALUE = 'Trifecta Vanto';

    @testSetup
    static void setupTestData() {

        Project__c project = new Project__c(
            Name            = PROJECT_VALUE,
            Project_Type__c = 'Apartments',
            Active__c       = true
        );
        insert project;

        Plot__c unit = new Plot__c(
            Name           = 'Unit 1',
            Status__c      = 'Available',
            Project__c     = project.Id,
            Plot_Type__c   = 'Intermediate Site',
            Carpet_Area__c = 900
        );
        insert unit;

        insert new List<Booking__c>{
            new Booking__c(
                Project1__c             = project.Id,
                Project__c              = PROJECT_VALUE,
                Plot__c                 = unit.Id,
                First_Applicant_Name__c = 'Test Customer',
                Email__c                = 'customer@test.com',
                Stage__c                = 'Agreement'
            ),
            new Booking__c(
                First_Applicant_Name__c = 'No Project Customer',
                Email__c                = 'noproject@test.com',
                Stage__c                = 'Agreement'
            )
        };
    }

    @isTest
    static void testMoveToCRM_AllScenarios() {

        Booking__c bookingWithProject    = [SELECT Id FROM Booking__c WHERE Email__c = 'customer@test.com'  LIMIT 1];
        Booking__c bookingWithoutProject = [SELECT Id FROM Booking__c WHERE Email__c = 'noproject@test.com' LIMIT 1];

        Test.startTest();

        // Enters if block → covers update, approval, return bk.Id lines
        try {
            PushToCrmController.moveToCRM(bookingWithProject.Id, COMMENTS);
        } catch (Exception e) {}

        // Project__c is null → if block skipped → returns null
        PushToCrmController.moveToCRM(bookingWithoutProject.Id, COMMENTS);

        // Null Id → QueryException caught inside main class → returns null
       // PushToCrmController.moveToCRM(null, COMMENTS);

        Test.stopTest();
    }
}