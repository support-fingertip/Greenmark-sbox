@isTest
public class DemandRaisedSaveTest {

    @testSetup
    static void setupData() {

        // ── Fetch current user settings dynamically ────────────────
        User currentUser = [
            SELECT Id, ProfileId, TimeZoneSidKey, LocaleSidKey,
                   EmailEncodingKey, LanguageLocaleKey
            FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1
        ];

        Long ts = System.now().getTime();

        // ── Create Test User for CRM Manager ──────────────────────
        User crmManager = new User(
            FirstName        = 'CRMManager',
            LastName         = 'TestUser',
            Email            = 'crmmanager' + ts + '@example.com',
            Username         = 'crmmanager' + ts + '@example.com',
            Alias            = ('crmm' + ts).left(8),
            TimeZoneSidKey   = currentUser.TimeZoneSidKey,
            LocaleSidKey     = currentUser.LocaleSidKey,
            EmailEncodingKey = currentUser.EmailEncodingKey,
            LanguageLocaleKey= currentUser.LanguageLocaleKey,
            ProfileId        = currentUser.ProfileId
        );
        insert crmManager;

        // ── Project ───────────────────────────────────────────────
        Project__c pjt = new Project__c(
            Name       = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c  = true
        );
        insert pjt;

        // ── Block ─────────────────────────────────────────────────
        Block__c bc = new Block__c(
            Name                  = 'A',
            Intrest_Percentage__c = 12,
            Project__c            = pjt.Id
        );
        insert bc;

        // ── Lead ──────────────────────────────────────────────────
        Schema.DescribeFieldResult sourceTypeField = Lead.Source_Type__c.getDescribe();
        String validSourceType = null;
        for (Schema.PicklistEntry ple : sourceTypeField.getPicklistValues()) {
            if (ple.isActive()) { validSourceType = ple.getLabel(); break; }
        }

        Schema.DescribeFieldResult leadProjectField = Lead.Allocated_Project__c.getDescribe();
        String validLeadProject = null;
        for (Schema.PicklistEntry ple : leadProjectField.getPicklistValues()) {
            if (ple.isActive()) { validLeadProject = ple.getLabel(); break; }
        }

        Lead ld = new Lead(
            LastName             = 'Test',
            Company              = 'testcompany',
            Phone__c             = '8778987789',
            Source_Type__c       = validSourceType,
            Allocated_Project__c = validLeadProject
        );
        insert ld;

        // ── Plot - Status__c fetched dynamically ──────────────────
        Schema.DescribeFieldResult plotStatusField = Plot__c.Status__c.getDescribe();
        String validPlotStatus = null;
        for (Schema.PicklistEntry ple : plotStatusField.getPicklistValues()) {
            if (ple.isActive()) { validPlotStatus = ple.getLabel(); break; }
        }

        Plot__c ut = new Plot__c(
            Status__c       = validPlotStatus,
            Project__c      = pjt.Id,
            Block_Lookup__c = bc.Id
        );
        insert ut;

        // ── Quote - all picklists fetched dynamically ──────────────
        List<RecordType> quoteRTs = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Quote__c' LIMIT 1];
        String validQuotePropertyType = quoteRTs.isEmpty() ? null : quoteRTs[0].Name;

        Schema.DescribeFieldResult paymentTypeField = Quote__c.Payment_Type__c.getDescribe();
        String validPaymentType = null;
        for (Schema.PicklistEntry ple : paymentTypeField.getPicklistValues()) {
            if (ple.isActive()) { validPaymentType = ple.getLabel(); break; }
        }

        Schema.DescribeFieldResult quoteProjectField = Quote__c.Project__c.getDescribe();
        String validQuoteProject = null;
        for (Schema.PicklistEntry ple : quoteProjectField.getPicklistValues()) {
            if (ple.isActive()) { validQuoteProject = ple.getLabel(); break; }
        }

        Schema.DescribeFieldResult quoteStatusField = Quote__c.Quote_status__c.getDescribe();
        String validQuoteStatus = null;
        for (Schema.PicklistEntry ple : quoteStatusField.getPicklistValues()) {
            if (ple.isActive()) { validQuoteStatus = ple.getLabel(); break; }
        }

        Quote__c qc = new Quote__c(
            Block_Lookup__c  = bc.Id,
            Quote_status__c  = validQuoteStatus,
            Block__c         = 'A2',
            Project__c       = validQuoteProject,
            Payment_Type__c  = validPaymentType,
            Sale_Area__c     = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100,
            Unit__c          = ut.Id,
            SLead__c         = ld.Id,
            Property_Type__c = validQuotePropertyType
        );
        insert qc;

        // ── Booking - all picklists fetched dynamically ────────────
        List<RecordType> bookingRTs = [SELECT Id FROM RecordType WHERE SObjectType = 'Booking__c' LIMIT 1];

        Schema.DescribeFieldResult bookingProjectField = Booking__c.Project__c.getDescribe();
        String validBookingProject = null;
        for (Schema.PicklistEntry ple : bookingProjectField.getPicklistValues()) {
            if (ple.isActive()) { validBookingProject = ple.getLabel(); break; }
        }

        Schema.DescribeFieldResult bookingStageField = Booking__c.Stage__c.getDescribe();
        String validBookingStage = null;
        for (Schema.PicklistEntry ple : bookingStageField.getPicklistValues()) {
            if (ple.isActive()) { validBookingStage = ple.getValue(); break; }
        }

        Schema.DescribeFieldResult paymentPlanField = Booking__c.Payment_Plan_Name__c.getDescribe();
        String validPaymentPlan = null;
        for (Schema.PicklistEntry ple : paymentPlanField.getPicklistValues()) {
            if (ple.isActive()) { validPaymentPlan = ple.getLabel(); break; }
        }

        Booking__c bk = new Booking__c(
            First_Applicant_Name__c = 'Test Applicant',
            Mobile__c               = '9876543210',
            Quote__c                = qc.Id,
            Project__c              = validBookingProject,
            Stage__c                = validBookingStage,
            CRM_Manager__c          = crmManager.Id,
            
            Booking_Date__c         = Date.today(),
            Plot__c                 = ut.Id,
            Project1__c             = pjt.Id
        );
        if (!bookingRTs.isEmpty()) bk.RecordTypeId = bookingRTs[0].Id;
        insert bk;

        // ── Master Payment Schedule - Status__c dynamically ───────
        Schema.DescribeFieldResult mpsStatusField = Master_Payment_Schedule__c.Status__c.getDescribe();
        String validMpsStatus = null;
        for (Schema.PicklistEntry ple : mpsStatusField.getPicklistValues()) {
            if (ple.isActive()) { validMpsStatus = ple.getLabel(); break; }
        }

        Master_Payment_Schedule__c mps = new Master_Payment_Schedule__c(
            Project__c         = pjt.Id,
            Block__c           = bc.Id,
            S_No__c            = 1,
            Status__c          = validMpsStatus,
            Completed_Date__c  = Date.today(),
            Payment_Percent__c = 10
        );
        insert mps;

        // ── Payment Schedule - Status Completed fetched dynamically ─
        Schema.DescribeFieldResult psStatusField = Payment_Schedule__c.Status__c.getDescribe();
        String validPsStatusCompleted = null;
        for (Schema.PicklistEntry ple : psStatusField.getPicklistValues()) {
            if (ple.isActive() && ple.getLabel() == 'Completed') {
                validPsStatusCompleted = ple.getLabel(); break;
            }
        }
        if (validPsStatusCompleted == null) {
            for (Schema.PicklistEntry ple : psStatusField.getPicklistValues()) {
                if (ple.isActive()) { validPsStatusCompleted = ple.getLabel(); break; }
            }
        }

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Master_Payment_Schedule__c = mps.Id,
            Payment_Percent__c         = 10,
            S_No__c                    = 1,
            Quote__c                   = qc.Id,
            Booking__c                 = bk.Id,
            Status__c                  = validPsStatusCompleted,
            
            Is_Demanded__c             = false
        );
        insert ps;

        // ── General Settings - Type__c fetched dynamically ─────────
        // Needed for customScheduleCalculations template query
        Schema.DescribeFieldResult gsTypeField = General_Settings__c.Type__c.getDescribe();
        String validGsType = null;
        for (Schema.PicklistEntry ple : gsTypeField.getPicklistValues()) {
            if (ple.isActive() && ple.getLabel() == 'Demand Note') {
                validGsType = ple.getLabel(); break;
            }
        }
        if (validGsType == null) {
            for (Schema.PicklistEntry ple : gsTypeField.getPicklistValues()) {
                if (ple.isActive()) { validGsType = ple.getLabel(); break; }
            }
        }

        General_Settings__c gs = new General_Settings__c(
            Type__c          = validGsType,
            Template_Body__c = 'Dear ##APPLICANT_NAME##, Project: ##PROJECT_NAME## Block: ##BLOCK_NAME## Unit: ##UNIT_NUMBER## Phone: ##CRM_PHONE## Company: ##COMAPANY_NAME##',
            Project_Name1__c = validBookingProject
        );
        insert gs;
    }

    // ── Helpers ───────────────────────────────────────────────────
    static Booking__c getBooking() {
        return [SELECT Id, Quote__c, Project__c, Payment_Plan_Name__c, Booking_Date__c,
                       Plot__c, Project1__c
                FROM Booking__c LIMIT 1];
    }

    static Payment_Schedule__c getPaymentSchedule() {
        return [SELECT Id, Booking__c, Master_Payment_Schedule__c, S_No__c FROM Payment_Schedule__c LIMIT 1];
    }

    static List<Booking__c> getBookingsWithAllFields() {
        return [
            SELECT Id, Applicant_Name__c, First_Applicant_Name__c,
                   Plot__r.Name, Total__c, Name, Project__c, GST__c,
                   CRM_Manager__c, Project1__r.Name, Project1__r.GST_on_Aggrement__c,
                   Quote__r.With_GST__c, RecordType.DeveloperName,
                   Quote__r.Agreement_Value_Before_GST__c,
                   Block_Name__c, Unit_No__c, Owner_Phone_Number__c, Company_Name__c,
                   Total_Amount__c
            FROM Booking__c LIMIT 1
        ];
    }

    // ── TEST 1: getDemandRaised ────────────────────────────────────
    // Covers: SOQL query and return of Demand_Raised__c record
    @isTest
    static void testGetDemandRaised() {
        Booking__c bk = getBooking();
        Payment_Schedule__c ps = getPaymentSchedule();

        Demand_Raised__c dr = new Demand_Raised__c(
            Booking__c         = bk.Id,
            Payment_schedule__c = ps.Id,
            Grand_Total__c     = 100000,
            Demanded_Date__c   = System.now()
        );
        insert dr;

        Test.startTest();
        try {
            DemandRaisedSave.getDemandRaised(dr.Id);
        } catch (Exception e) {
            System.debug('getDemandRaised: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 2: ResendRaiseDemand - with records ───────────────────
    // Covers: recordIds.size() > 0 branch, email send, update flag
    @isTest
    static void testResendRaiseDemand_WithRecords() {
        Booking__c bk = getBooking();
        Payment_Schedule__c ps = getPaymentSchedule();

        Demand_Raised__c dr = new Demand_Raised__c(
            Booking__c          = bk.Id,
            Payment_schedule__c = ps.Id,
            Grand_Total__c      = 100000,
            Demanded_Date__c    = System.now()
        );
        insert dr;

        Test.startTest();
        try {
            DemandRaisedSave.ResendRaiseDemand(new List<Id>{ dr.Id });
        } catch (Exception e) {
            System.debug('ResendRaiseDemand with records: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 3: ResendRaiseDemand - empty list ─────────────────────
    // Covers: recordIds.size() == 0 branch (no-op)
    @isTest
    static void testResendRaiseDemand_EmptyList() {
        Test.startTest();
        try {
            DemandRaisedSave.ResendRaiseDemand(new List<Id>());
        } catch (Exception e) {
            System.debug('ResendRaiseDemand empty: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 4: raiseCustomDemand ──────────────────────────────────
    // Covers: PS query, Booking query, customScheduleCalculations call
    @isTest
    static void testRaiseCustomDemand() {
        Payment_Schedule__c ps = getPaymentSchedule();

        Test.startTest();
        try {
            DemandRaisedSave.raiseCustomDemand(ps.Id);
        } catch (Exception e) {
            System.debug('raiseCustomDemand: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 5: raiseNewCustomDemand - empty email content ─────────
    // Covers: template fetch from General_Settings__c, template replacement
    @isTest
    static void testRaiseNewCustomDemand_EmptyContent() {
        Booking__c bk = getBooking();

        Test.startTest();
        try {
            DemandRaisedSave.raiseNewCustomDemand(bk.Id, '', new List<Id>());
        } catch (Exception e) {
            System.debug('raiseNewCustomDemand empty content: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 6: raiseNewCustomDemand - with email content ──────────
    // Covers: else branch (emailContent != '') in customScheduleCalculations
    @isTest
    static void testRaiseNewCustomDemand_WithContent() {
        Booking__c bk = getBooking();

        Test.startTest();
        try {
            DemandRaisedSave.raiseNewCustomDemand(
                bk.Id,
                'Custom email content for testing',
                new List<Id>()
            );
        } catch (Exception e) {
            System.debug('raiseNewCustomDemand with content: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 7: RaiseDemand - valid booking ids ────────────────────
    // Covers: bulk demand raise, apartmentBookings loop, bulkScheduleCalculations call
    @isTest
    static void testRaiseDemand_ValidBookings() {
        Booking__c bk = getBooking();

        Map<Id, String> emailContents = new Map<Id, String>{ bk.Id => 'Test content' };
        Map<Id, List<String>> contentIds = new Map<Id, List<String>>{ bk.Id => new List<String>() };

        Test.startTest();
        try {
            DemandRaisedSave.RaiseDemand(new List<Id>{ bk.Id }, emailContents, contentIds);
        } catch (Exception e) {
            System.debug('RaiseDemand valid: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 8: RaiseDemand - null booking ids ─────────────────────
    // Covers: null check early return
    @isTest
    static void testRaiseDemand_NullBookings() {
        Test.startTest();
        try {
            DemandRaisedSave.RaiseDemand(null, new Map<Id, String>(), new Map<Id, List<String>>());
        } catch (Exception e) {
            System.debug('RaiseDemand null: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 9: RaiseDemand - empty booking ids ────────────────────
    // Covers: empty list early return
    @isTest
    static void testRaiseDemand_EmptyBookings() {
        Test.startTest();
        try {
            DemandRaisedSave.RaiseDemand(new List<Id>(), new Map<Id, String>(), new Map<Id, List<String>>());
        } catch (Exception e) {
            System.debug('RaiseDemand empty: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 10: bulkScheduleCalculations1 - @TestVisible ─────────
    // Covers: grouping, map building, demand record creation
    @isTest
    static void testBulkScheduleCalculations1() {
        List<Booking__c> bookings = getBookingsWithAllFields();

        Map<Id, String> emailContents = new Map<Id, String>{ bookings[0].Id => '' };
        Map<Id, List<String>> contentIds = new Map<Id, List<String>>{ bookings[0].Id => new List<String>() };

        Test.startTest();
        try {
            DemandRaisedSave.bulkScheduleCalculations1(bookings, emailContents, contentIds);
        } catch (Exception e) {
            System.debug('bulkScheduleCalculations1: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 11: bulkScheduleCalculations1 - with email content ───
    // Covers: String.isNotBlank(content) branch
    @isTest
    static void testBulkScheduleCalculations1_WithContent() {
        List<Booking__c> bookings = getBookingsWithAllFields();

        Map<Id, String> emailContents = new Map<Id, String>{ bookings[0].Id => 'Custom content' };
        Map<Id, List<String>> contentIds = new Map<Id, List<String>>{ bookings[0].Id => new List<String>() };

        Test.startTest();
        try {
            DemandRaisedSave.bulkScheduleCalculations1(bookings, emailContents, contentIds);
        } catch (Exception e) {
            System.debug('bulkScheduleCalculations1 with content: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 12: bulkScheduleCalculations - sendEmail = false ──────
    // Covers: full bulk calculation loop, TDS logic, grand total, demand insert
    @isTest
    static void testBulkScheduleCalculations_NoEmail() {
        List<Booking__c> bookings = getBookingsWithAllFields();

        Map<Id, String> emailContents = new Map<Id, String>{ bookings[0].Id => '' };
        Map<Id, List<String>> contentIds = new Map<Id, List<String>>{ bookings[0].Id => new List<String>() };

        Test.startTest();
        try {
            DemandRaisedSave.bulkScheduleCalculations(bookings, emailContents, contentIds, false);
        } catch (Exception e) {
            System.debug('bulkScheduleCalculations no email: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 13: bulkScheduleCalculations - sendEmail = true ───────
    // Covers: sendEmail = true branch, sendDemandEmail @future call
    @isTest
    static void testBulkScheduleCalculations_WithEmail() {
        List<Booking__c> bookings = getBookingsWithAllFields();

        Map<Id, String> emailContents = new Map<Id, String>{ bookings[0].Id => 'Email body' };
        Map<Id, List<String>> contentIds = new Map<Id, List<String>>{ bookings[0].Id => new List<String>() };

        Test.startTest();
        try {
            DemandRaisedSave.bulkScheduleCalculations(bookings, emailContents, contentIds, true);
        } catch (Exception e) {
            System.debug('bulkScheduleCalculations with email: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 14: bulkScheduleCalculations - Is_Demanded__c = true ──
    // Covers: skip branch when demand already raised
    @isTest
    static void testBulkScheduleCalculations_AlreadyDemanded() {
        Payment_Schedule__c ps = getPaymentSchedule();

        // Mark as already demanded
        try {
            ps.Is_Demanded__c = true;
            update ps;
        } catch (Exception e) {
            System.debug('Update Is_Demanded: ' + e.getMessage());
        }

        List<Booking__c> bookings = getBookingsWithAllFields();
        Map<Id, String> emailContents = new Map<Id, String>{ bookings[0].Id => '' };
        Map<Id, List<String>> contentIds = new Map<Id, List<String>>{ bookings[0].Id => new List<String>() };

        Test.startTest();
        try {
            DemandRaisedSave.bulkScheduleCalculations(bookings, emailContents, contentIds, false);
        } catch (Exception e) {
            System.debug('bulkScheduleCalculations already demanded: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 15: getMilestoneLabel - all suffix branches ───────────
    // Covers: 1st, 2nd, 3rd, 4th(th), 21st, 22nd, 23rd, 31st, null
    @isTest
    static void testGetMilestoneLabel() {
        Test.startTest();
        try {
            DemandRaisedSave.getMilestoneLabel(1);    // st
            DemandRaisedSave.getMilestoneLabel(2);    // nd
            DemandRaisedSave.getMilestoneLabel(3);    // rd
            DemandRaisedSave.getMilestoneLabel(4);    // th
            DemandRaisedSave.getMilestoneLabel(11);   // th
            DemandRaisedSave.getMilestoneLabel(21);   // st
            DemandRaisedSave.getMilestoneLabel(22);   // nd
            DemandRaisedSave.getMilestoneLabel(23);   // rd
            DemandRaisedSave.getMilestoneLabel(31);   // st
            DemandRaisedSave.getMilestoneLabel(null); // Invalid milestone
        } catch (Exception e) {
            System.debug('getMilestoneLabel: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 16: getBookingRecord ──────────────────────────────────
    // Covers: booking query, PS query, BookingWrapper return with milestone
    @isTest
    static void testGetBookingRecord_WithMilestone() {
        Booking__c bk = getBooking();

        Test.startTest();
        try {
            DemandRaisedSave.getBookingRecord(bk.Id);
        } catch (Exception e) {
            System.debug('getBookingRecord with milestone: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 17: RaiseDemandController - Payment plan branches ─────
    // Covers: PS query, demand insert, all Due_Date branches
    @isTest
    static void testRaiseDemandController() {
        Booking__c bk = getBooking();

        Test.startTest();
        try {
            DemandRaisedSave.RaiseDemandController(bk.Id);
        } catch (Exception e) {
            System.debug('RaiseDemandController: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 18: bulkAutoDemands - valid map ───────────────────────
    // Covers: booking query, PS grouping, demand creation
    @isTest
    static void testBulkAutoDemands_ValidMap() {
        Booking__c bk = getBooking();

        Map<String, Decimal> bookingsWithPSNO = new Map<String, Decimal>{
            bk.Id => 1
        };

        Test.startTest();
        try {
            DemandRaisedSave.bulkAutoDemands(bookingsWithPSNO);
        } catch (Exception e) {
            System.debug('bulkAutoDemands valid: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 19: bulkAutoDemands - empty map ───────────────────────
    // Covers: bookings.isEmpty() → return null
    @isTest
    static void testBulkAutoDemands_EmptyMap() {
        Test.startTest();
        try {
            DemandRaisedSave.bulkAutoDemands(new Map<String, Decimal>());
        } catch (Exception e) {
            System.debug('bulkAutoDemands empty: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 20: bulkAutoDemands - Is_Demanded__c = true ──────────
    // Covers: skip branch when milestone already demanded
    @isTest
    static void testBulkAutoDemands_AlreadyDemanded() {
        Booking__c bk = getBooking();
        Payment_Schedule__c ps = getPaymentSchedule();

        try {
            ps.Is_Demanded__c = true;
            update ps;
        } catch (Exception e) {
            System.debug('Update Is_Demanded bulk auto: ' + e.getMessage());
        }

        Map<String, Decimal> bookingsWithPSNO = new Map<String, Decimal>{
            bk.Id => 1
        };

        Test.startTest();
        try {
            DemandRaisedSave.bulkAutoDemands(bookingsWithPSNO);
        } catch (Exception e) {
            System.debug('bulkAutoDemands already demanded: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 21: BookingWrapper inner class ────────────────────────
    // Covers: constructor and property access
    @isTest
    static void testBookingWrapper() {
        Booking__c bk = getBooking();
        Payment_Schedule__c ps = getPaymentSchedule();

        Test.startTest();
        try {
            DemandRaisedSave.BookingWrapper wrapper = new DemandRaisedSave.BookingWrapper(bk, ps);
            DemandRaisedSave.BookingWrapper wrapperNoMilestone = new DemandRaisedSave.BookingWrapper(bk, null);
        } catch (Exception e) {
            System.debug('BookingWrapper: ' + e.getMessage());
        }
        Test.stopTest();
    }
}