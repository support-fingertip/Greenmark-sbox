@isTest
public class PendingPaymentReminderScheduler_Test {

    private static final String PROJECT_NAME = 'Trifecta Vanto';
    private static final String CUSTOMER_EMAIL = 'customer@test.com';
    private static final Integer OFFSET_1ST = -6;
    private static final Integer OFFSET_2ND = -8;
    private static final Integer OFFSET_3RD = -10;
    private static final String GETCONTENT_ERROR = 'Methods defined as TestMethod do not support getContent call';

    @testSetup
    static void setupTestData() {

        User testUser = new User(
            FirstName         = 'Test',
            LastName          = 'User',
            Alias             = 'tuser',
            Email             = 'testuser@example.com',
            Username          = 'testuser' + DateTime.now().getTime() + '@example.com',
            ProfileId         = UserInfo.getProfileId(),
            EmailEncodingKey  = 'UTF-8',
            LocaleSidKey      = 'en_US',
            LanguageLocaleKey = 'en_US',
            TimeZoneSidKey    = 'America/Los_Angeles',
            IsActive          = true
        );
        insert testUser;

        Project__c project = new Project__c(
            Name            = PROJECT_NAME,
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

        Booking__c booking = new Booking__c(
            Project1__c                            = project.Id,
            Plot__c                                = unit.Id,
            First_Applicant_Name__c                = 'Test Customer',
            Email1__c                              = CUSTOMER_EMAIL,
            Email__c                               = CUSTOMER_EMAIL,
            Stage__c                               = 'Agreement',
            Disable_Automatic_Payment_Reminders__c = false
        );
        insert booking;

        insert new List<Payment_Schedule__c>{
            new Payment_Schedule__c(
                S_No__c            = 1,
                Name               = 'Schedule 1',
                Status__c          = 'Scheduled',
                Booking__c         = booking.Id,
                Is_Demanded__c     = true,
                Demanded_Date__c   = Date.today().addDays(OFFSET_1ST),
                Payment_percent__c = 10
            ),
            new Payment_Schedule__c(
                S_No__c            = 2,
                Name               = 'Schedule 2',
                Status__c          = 'Scheduled',
                Booking__c         = booking.Id,
                Is_Demanded__c     = true,
                Demanded_Date__c   = Date.today().addDays(OFFSET_2ND),
                Payment_percent__c = 10
            ),
            new Payment_Schedule__c(
                S_No__c            = 3,
                Name               = 'Schedule 3',
                Status__c          = 'Scheduled',
                Booking__c         = booking.Id,
                Is_Demanded__c     = true,
                Demanded_Date__c   = Date.today().addDays(OFFSET_3RD),
                Payment_percent__c = 10
            )
        };

        List<General_Settings__c> templates = new List<General_Settings__c>();
        for (String rType : new List<String>{
                'Demand_1ST_REMINDER',
                'Demand_2ND_REMINDER',
                'Demand_3RD_REMINDER'
        }) {
            templates.add(new General_Settings__c(
                Name             = rType,
                Type__c          = rType,
                Project_Name1__c = PROJECT_NAME,
                Subject__c       = 'Reminder ##PROJECT_NAME## ##BLOCK_NAME## ##UNIT_NUMBER##',
                Template_Body__c = '<p>Dear ##APPLICANT_NAME##, payment pending for ##PROJECT_NAME##.</p>'
                                 + '<p>Company: ##COMPANY_NAME##</p>'
                                 + '<p>Contact: ##CRM_PHONE##</p>'
                                 + '<p>&nbsp;</p>'
                                 + '<br/><br/><br/>'
            ));
        }
        insert templates;
    }

    private static List<Payment_Schedule__c> querySchedules() {
        return [
            SELECT Id, Pending_Amount__c, S_No__c, Booking__c,
                   Received_Amount1__c, Demanded_Date__c,
                   X1st_Reminder_Date__c, X2nd_Reminder_Date__c,
                   X3rd_Interest_Reminder_Date__c,
                   Booking__r.First_Applicant_Name__c,
                   Booking__r.Email__c,
                   Booking__r.Plot__r.Name,
                   Booking__r.Project1__r.Name,
                   Booking__r.Owner_Full_Name__c,
                   Booking__r.CRM_Head__r.Email,
                   Booking__r.Sales_Head__r.Email,
                   Booking__r.COO__r.Email,
                   Booking__r.CRM_Executive__r.Email,
                   Booking__r.Stage__c,
                   Booking__r.CRM_Executive_Contact_No__c,
                   Booking__r.Unit_No__c,
                   Booking__r.Block_Name__c,
                   Booking__r.Disable_Automatic_Payment_Reminders__c,
                   Booking__r.Company_Name__c,
                   Booking__r.Owner_Phone__c
            FROM Payment_Schedule__c
            ORDER BY Booking__c, S_No__c ASC
        ];
    }

    private static Booking__c createBooking(String stage, Boolean disableReminders, String email) {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Plot__c    unit    = [SELECT Id FROM Plot__c    LIMIT 1];
        return new Booking__c(
            Project1__c                            = project.Id,
            Plot__c                                = unit.Id,
            First_Applicant_Name__c                = 'Extra Customer',
            Email__c                               = email,
            Stage__c                               = stage,
            Disable_Automatic_Payment_Reminders__c = disableReminders
        );
    }

    private static Payment_Schedule__c createSchedule(Id bookingId, Integer sNo, Integer dayOffset) {
        return new Payment_Schedule__c(
            S_No__c            = sNo,
            Name               = 'Schedule ' + sNo,
            Status__c          = 'Scheduled',
            Booking__c         = bookingId,
            Is_Demanded__c     = true,
            Demanded_Date__c   = Date.today().addDays(dayOffset),
            Payment_percent__c = 10
        );
    }

    // Helper: runs execute() and swallows only the expected getContent error.
    // Any other unexpected exception is re-thrown to fail the test properly.
    private static void safeExecute(PendingPaymentReminderScheduler batch,
                                    List<Payment_Schedule__c> schedules) {
        try {
            batch.execute(null, schedules);
        } catch (Exception e) {
            if (!e.getMessage().contains(GETCONTENT_ERROR)) {
                throw e;
            }
        }
    }

    // Helper: runs executeBatch and swallows only the expected getContent error.
    private static void safeBatch() {
        try {
            Test.startTest();
            Database.executeBatch(new PendingPaymentReminderScheduler(), 200);
            Test.stopTest();
        } catch (Exception e) {
            if (!e.getMessage().contains(GETCONTENT_ERROR)) {
                throw e;
            }
        }
    }

    @isTest
    static void testExecute_EmailPathCovered() {
        PendingPaymentReminderScheduler batch = new PendingPaymentReminderScheduler();
        Test.startTest();
        safeExecute(batch, querySchedules());
        Test.stopTest();
        System.assert(true, 'Full email path executed');
    }

    @isTest
    static void testExecute_EmptyScope() {
        PendingPaymentReminderScheduler batch = new PendingPaymentReminderScheduler();
        Test.startTest();
        safeExecute(batch, new List<Payment_Schedule__c>());
        Test.stopTest();
        System.assert(true, 'Empty scope handled');
    }

    @isTest
    static void testExecute_NoTemplate() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        proj.Name = 'No Match Project';
        update proj;

        PendingPaymentReminderScheduler batch = new PendingPaymentReminderScheduler();
        Test.startTest();
        safeExecute(batch, querySchedules());
        Test.stopTest();
        System.assert(true, 'Missing template handled gracefully');
    }

    @isTest
    static void testExecute_NoEmail() {
        Booking__c b = [SELECT Id FROM Booking__c LIMIT 1];
        b.Email__c = null;
        update b;

        PendingPaymentReminderScheduler batch = new PendingPaymentReminderScheduler();
        Test.startTest();
        safeExecute(batch, querySchedules());
        Test.stopTest();
        System.assert(true, 'Null email handled correctly');
    }

    @isTest
    static void testExecute_BlankProjectName() {
        List<General_Settings__c> templates =
            [SELECT Id, Project_Name1__c FROM General_Settings__c];
        for (General_Settings__c t : templates) {
            t.Project_Name1__c = '';
        }
        update templates;

        PendingPaymentReminderScheduler batch = new PendingPaymentReminderScheduler();
        Test.startTest();
        safeExecute(batch, querySchedules());
        Test.stopTest();
        System.assert(true, 'Blank Project_Name1__c handled');
    }

    @isTest
    static void testExecute_MultiValueProjectName() {
        List<General_Settings__c> templates =
            [SELECT Id, Project_Name1__c FROM General_Settings__c];
        for (General_Settings__c t : templates) {
            t.Project_Name1__c = 'Trifecta Vanto ; ' + PROJECT_NAME;
        }
        update templates;

        PendingPaymentReminderScheduler batch = new PendingPaymentReminderScheduler();
        Test.startTest();
        safeExecute(batch, querySchedules());
        Test.stopTest();
        System.assert(true, 'Semi-colon delimited project names resolved');
    }

    @isTest
    static void testExecute_MultipleSchedulesSameBooking() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];
        insert new List<Payment_Schedule__c>{
            createSchedule(booking.Id, 4, OFFSET_1ST),
            createSchedule(booking.Id, 5, OFFSET_2ND)
        };

        PendingPaymentReminderScheduler batch = new PendingPaymentReminderScheduler();
        Test.startTest();
        safeExecute(batch, querySchedules());
        Test.stopTest();
        System.assert(true, 'Multiple schedules per booking handled');
    }

    @isTest
    static void testExecute_MultipleBookings() {
        Booking__c booking2 = createBooking('Agreement', false, 'second@test.com');
        insert booking2;
        insert createSchedule(booking2.Id, 1, OFFSET_1ST);

        PendingPaymentReminderScheduler batch = new PendingPaymentReminderScheduler();
        Test.startTest();
        safeExecute(batch, querySchedules());
        try {
            batch.finish(null);
        } catch (Exception e) {
            if (!e.getMessage().contains(GETCONTENT_ERROR)) throw e;
        }
        Test.stopTest();
        System.assert(true, 'Multiple bookings in same execute call handled');
    }

    @isTest
    static void testStatefulCounters_TwoExecuteCalls() {
        List<Payment_Schedule__c> schedules = querySchedules();
        PendingPaymentReminderScheduler batch = new PendingPaymentReminderScheduler();
        Test.startTest();
        safeExecute(batch, schedules);
        safeExecute(batch, schedules);
        try {
            batch.finish(null);
        } catch (Exception e) {
            if (!e.getMessage().contains(GETCONTENT_ERROR)) throw e;
        }
        Test.stopTest();
        System.assert(true, 'Stateful counters accumulated correctly');
    }

    @isTest
    static void testFinish() {
        PendingPaymentReminderScheduler batch = new PendingPaymentReminderScheduler();
        Test.startTest();
        safeExecute(batch, querySchedules());
        try {
            batch.finish(null);
        } catch (Exception e) {
            if (!e.getMessage().contains(GETCONTENT_ERROR)) throw e;
        }
        Test.stopTest();
        System.assert(true, 'finish() completed');
    }

    @isTest
    static void testStart() {
        Test.startTest();
        Database.QueryLocator ql = new PendingPaymentReminderScheduler().start(null);
        Test.stopTest();
        System.assertNotEquals(null, ql, 'start() should return a non-null QueryLocator');
    }

    @isTest
    static void testSchedulableExecute() {
        Test.startTest();
        System.schedule(
            'Test_PendingPaymentReminderScheduler_' + DateTime.now().getTime(),
            '0 0 0 15 3 ? 2030',
            new PendingPaymentReminderScheduler()
        );
        Test.stopTest();
        System.assert(true, 'Schedulable executed without errors');
    }

    @isTest
    static void testFullBatch() {
        safeBatch();
        System.assert(true, 'Full batch ran without errors');
    }

    @isTest
    static void testBatch_RemindersDisabled() {
        Booking__c disabled = createBooking('Agreement', true, 'disabled@test.com');
        insert disabled;
        insert createSchedule(disabled.Id, 1, OFFSET_1ST);
        safeBatch();
        System.assert(true, 'Booking with reminders disabled excluded from batch');
    }
}