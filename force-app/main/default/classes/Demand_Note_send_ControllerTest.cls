@isTest
public class Demand_Note_send_ControllerTest {

    @isTest
    static void testDemandNoteSendController() {

        // Setup Project
        Project__c pjt = new Project__c(
            Name               = 'Test Project',
            Project__c         = 'Trifecta Vanto',
            Active__c          = true,
            Company_Address__c = 'Test Company Address'
        );
        insert pjt;

        // Setup Block
        Block__c bc = new Block__c(
            Name                  = 'B',
            Intrest_Percentage__c = 10,
            Project__c            = pjt.Id,
            Email__c              = 'test@test.com',
            Project_Address__c    = 'Test Project Address',
            Bank_Name__c          = 'Test Bank',
            Account_Number__c     = '1234567890',
            IFSC_Code__c          = 'TEST0001234',
            Type_of_Account__c    = 'Current',
            Branch__c             = 'Test Branch'
        );
        insert bc;

        // Setup Lead
        Lead ld = new Lead(
            LastName             = 'Test',
            Company              = 'Test Company',
            Phone__c             = '8778987789',
            Source_Type__c       = 'Google',
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert ld;

        // Setup Plot
        Plot__c plt = new Plot__c(
            Status__c       = 'Available',
            Project__c      = pjt.Id,
            Block_Lookup__c = bc.Id
        );
        insert plt;

        // Setup Booking
        Booking__c book = new Booking__c(
            Plot__c                 = plt.Id,
            Notes_and_Comments__c   = 'Sample Note',
            Project1__c             = pjt.Id,
            SLead__c                = ld.Id,
            First_Applicant_Name__c = 'Test Applicant'
        );
        insert book;

        // Setup Co-Applicant
        Co_Applicant__c ca1 = new Co_Applicant__c(
            Name             = 'Co Applicant One',
            Primary_Phone__c = '9876543211',
            Booking__c       = book.Id
        );
        insert ca1;

        // Setup Demand Raised
        Demand_Raised__c demand = new Demand_Raised__c(
            Booking__c                             = book.Id,
            Demanded_Date__c                       = Datetime.now(),
            Due_Date__c                            = Datetime.now().addDays(30),
            Pending_Dues_excluding_TDS__c          = 50000,
            Pending_Payment_TDS_1__c               = 500,
            Current_Milestone_Excluding_the_TDS__c = 100000,
            Current_Milestone_TDS_1__c             = 1000,
            Grand_Total_in_Words__c                = 'One Lakh Fifty One Thousand Five Hundred',
            Grand_Total__c                         = 151500,
            Interest_Till_Now__c                   = 200,
            Demand_Name__c                         = 'Milestone 1'
        );
        insert demand;

        // Setup Page with demand Id
        PageReference pageRef = Page.Demand_Note_send;
        pageRef.getParameters().put('Id', demand.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();

        // 1. Controller with full data - block, co-applicants, all fields populated
        ApexPages.StandardController sc = new ApexPages.StandardController(demand);
        Demand_Note_send_Controller ctrl = new Demand_Note_send_Controller(sc);

        Test.stopTest();
    }

}