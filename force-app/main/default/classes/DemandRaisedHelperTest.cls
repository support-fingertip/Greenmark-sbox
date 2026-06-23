@isTest
public class DemandRaisedHelperTest {

    @isTest
    static void testAllDemandRaisedHelperMethods() {

        // Get running user to populate CRM_Head__c lookup
        // This ensures CRM_Head_Manager_Email__c formula resolves to a valid email
        User runningUser = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId()];

        // Setup Project
        Project__c pjt = new Project__c(
            Name       = 'Test Project',
            Project__c = 'Trifecta Vanto',
            Active__c  = true
        );
        insert pjt;

        // Setup Block
        Block__c bc = new Block__c(
            Name                  = 'B',
            Intrest_Percentage__c = 10,
            Project__c            = pjt.Id
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

        // Setup Booking - set CRM_Head__c so formula CRM_Head_Manager_Email__c resolves correctly
        Booking__c book = new Booking__c(
            Plot__c                 = plt.Id,
            Notes_and_Comments__c   = 'Sample Note',
            Project1__c             = pjt.Id,
            SLead__c                = ld.Id,
            First_Applicant_Name__c = 'Test Applicant',
            Email__c                = 'testcustomer@test.com',
            CRM_Head__c             = runningUser.Id
        );
        insert book;

        // Setup Payment Schedule
        Payment_Schedule__c ps = new Payment_Schedule__c(
            Booking__c     = book.Id,
            Is_Demanded__c = false,
            status__c      = 'Scheduled'
        );
        insert ps;

        // Setup Demand Raised with Payment Schedule
        Demand_Raised__c demand = new Demand_Raised__c(
            Booking__c                             = book.Id,
            Payment_Schedule__c                    = ps.Id,
            Demanded_Date__c                       = Datetime.now(),
            Due_Date__c                            = Datetime.now().addDays(30),
            Pending_Dues_excluding_TDS__c          = 50000,
            Pending_Payment_TDS_1__c               = 500,
            Current_Milestone_Excluding_the_TDS__c = 100000,
            Current_Milestone_TDS_1__c             = 1000,
            Grand_Total__c                         = 151500,
            Interest_Till_Now__c                   = 200,
            Current_Demand_amount__c               = 100000,
            Demand_Email_Content__c                = '<p>Test Email Content</p>',
            Demand_Name__c                         = 'Milestone 1'
        );
        insert demand;

        // Setup Plot 2 for Booking without Email
        Plot__c plt2 = new Plot__c(
            Status__c  = 'Available',
            Project__c = pjt.Id
        );
        insert plt2;

        // Setup Booking WITHOUT Email - hits blank email continue branch
        Booking__c bookNoEmail = new Booking__c(
            Plot__c                 = plt2.Id,
            Notes_and_Comments__c   = 'Sample Note 2',
            Project1__c             = pjt.Id,
            SLead__c                = ld.Id,
            First_Applicant_Name__c = 'Test Applicant 2'
        );
        insert bookNoEmail;

        // Setup Demand WITHOUT Payment Schedule - hits paymentScheduleIds.isEmpty() return
        Demand_Raised__c demandNoPS = new Demand_Raised__c(
            Booking__c               = bookNoEmail.Id,
            Demanded_Date__c         = Datetime.now(),
            Due_Date__c              = Datetime.now().addDays(30),
            Current_Demand_amount__c = 50000,
            Demand_Email_Content__c  = '<p>No Email Content</p>',
            Demand_Name__c           = 'Milestone 2'
        );
        insert demandNoPS;

        Test.startTest();

        // 1. updatePaymentScheduleFields - valid demand with payment schedule
        DemandRaisedHelper.updatePaymentScheduleFields(new List<Id>{ demand.Id });

        // 2. updatePaymentScheduleFields - demand without payment schedule (hits isEmpty return)
        DemandRaisedHelper.updatePaymentScheduleFields(new List<Id>{ demandNoPS.Id });

        // 3. updatePaymentScheduleFields - null list
        DemandRaisedHelper.updatePaymentScheduleFields(null);

        // 4. updatePaymentScheduleFields - empty list
        DemandRaisedHelper.updatePaymentScheduleFields(new List<Id>());

        // 5. sendDemandEmailToCustomer - valid email (full path + PDF catch + ContentVersion)
        DemandRaisedHelper.sendDemandEmailToCustomer(new List<Id>{ demand.Id });

        // 6. sendDemandEmailToCustomer - blank email (hits continue branch)
        DemandRaisedHelper.sendDemandEmailToCustomer(new List<Id>{ demandNoPS.Id });

        // 7. sendDemandEmailToCustomer - null list
        DemandRaisedHelper.sendDemandEmailToCustomer(null);

        // 8. sendDemandEmailToCustomer - empty list
        DemandRaisedHelper.sendDemandEmailToCustomer(new List<Id>());

        // 9. sendDemandEmailLogic - valid email (full path + PDF catch + ContentVersion)
        DemandRaisedHelper.sendDemandEmailLogic(new List<Id>{ demand.Id });

        // 10. sendDemandEmailLogic - blank email (hits continue branch)
        DemandRaisedHelper.sendDemandEmailLogic(new List<Id>{ demandNoPS.Id });

        // 11. sendDemandEmailLogic - null list
        DemandRaisedHelper.sendDemandEmailLogic(null);

        // 12. sendDemandEmailLogic - empty list
        DemandRaisedHelper.sendDemandEmailLogic(new List<Id>());

        Test.stopTest();
    }
}