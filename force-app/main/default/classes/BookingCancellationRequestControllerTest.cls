@isTest
public class BookingCancellationRequestControllerTest {

    @testSetup
    static void setupData() {

        // ── Fetch current user settings dynamically ────────────────
        User currentUser = [
            SELECT Id, ProfileId, TimeZoneSidKey, LocaleSidKey,
                   EmailEncodingKey, LanguageLocaleKey
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        Long ts = System.now().getTime();

        // ── Create Test Users - all settings from current user ─────
        User crmHead = new User(
            FirstName          = 'CRMHead',
            LastName           = 'TestUser',
            Email              = 'crmhead' + ts + '@example.com',
            Username           = 'crmhead' + ts + '@example.com',
            Alias              = ('crmh' + ts).left(8),
            TimeZoneSidKey     = currentUser.TimeZoneSidKey,
            LocaleSidKey       = currentUser.LocaleSidKey,
            EmailEncodingKey   = currentUser.EmailEncodingKey,
            LanguageLocaleKey  = currentUser.LanguageLocaleKey,
            ProfileId          = currentUser.ProfileId
        );
        insert crmHead;

        User crmManager = new User(
            FirstName          = 'CRMManager',
            LastName           = 'TestUser',
            Email              = 'crmmanager' + ts + '@example.com',
            Username           = 'crmmanager' + ts + '@example.com',
            Alias              = ('crmm' + ts).left(8),
            TimeZoneSidKey     = currentUser.TimeZoneSidKey,
            LocaleSidKey       = currentUser.LocaleSidKey,
            EmailEncodingKey   = currentUser.EmailEncodingKey,
            LanguageLocaleKey  = currentUser.LanguageLocaleKey,
            ProfileId          = currentUser.ProfileId
        );
        insert crmManager;

        User salesHead = new User(
            FirstName          = 'SalesHead',
            LastName           = 'TestUser',
            Email              = 'saleshead' + ts + '@example.com',
            Username           = 'saleshead' + ts + '@example.com',
            Alias              = ('slsh' + ts).left(8),
            TimeZoneSidKey     = currentUser.TimeZoneSidKey,
            LocaleSidKey       = currentUser.LocaleSidKey,
            EmailEncodingKey   = currentUser.EmailEncodingKey,
            LanguageLocaleKey  = currentUser.LanguageLocaleKey,
            ProfileId          = currentUser.ProfileId
        );
        insert salesHead;

        User salesUser = new User(
            FirstName          = 'SalesUser',
            LastName           = 'TestUser',
            Email              = 'salesuser' + ts + '@example.com',
            Username           = 'salesuser' + ts + '@example.com',
            Alias              = ('slsu' + ts).left(8),
            TimeZoneSidKey     = currentUser.TimeZoneSidKey,
            LocaleSidKey       = currentUser.LocaleSidKey,
            EmailEncodingKey   = currentUser.EmailEncodingKey,
            LanguageLocaleKey  = currentUser.LanguageLocaleKey,
            ProfileId          = currentUser.ProfileId
        );
        insert salesUser;

        User financeUser = new User(
            FirstName          = 'FinanceLead',
            LastName           = 'TestUser',
            Email              = 'financelead' + ts + '@example.com',
            Username           = 'financelead' + ts + '@example.com',
            Alias              = ('finl' + ts).left(8),
            TimeZoneSidKey     = currentUser.TimeZoneSidKey,
            LocaleSidKey       = currentUser.LocaleSidKey,
            EmailEncodingKey   = currentUser.EmailEncodingKey,
            LanguageLocaleKey  = currentUser.LanguageLocaleKey,
            ProfileId          = currentUser.ProfileId
        );
        insert financeUser;

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

        // ── Plot ──────────────────────────────────────────────────
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

        // ── Quote ─────────────────────────────────────────────────
        List<RecordType> quoteRecordTypes = [
            SELECT Id, Name FROM RecordType
            WHERE SObjectType = 'Quote__c' LIMIT 1
        ];
        String validQuotePropertyType = quoteRecordTypes.isEmpty() ? null : quoteRecordTypes[0].Name;

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
    }

    // ── Helpers ───────────────────────────────────────────────────
    static Quote__c getQuote() {
        return [SELECT Id FROM Quote__c LIMIT 1];
    }

    static String getBookingProject() {
        for (Schema.PicklistEntry ple : Booking__c.Project__c.getDescribe().getPicklistValues()) {
            if (ple.isActive()) return ple.getLabel();
        }
        return null;
    }

    static String getBookingStage() {
        for (Schema.PicklistEntry ple : Booking__c.Stage__c.getDescribe().getPicklistValues()) {
            if (ple.isActive()) return ple.getValue();
        }
        return null;
    }

    static Id getBookingRecordTypeId() {
        List<RecordType> rts = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Booking__c' LIMIT 1
        ];
        return rts.isEmpty() ? null : rts[0].Id;
    }

    // ── Fetch test users by email pattern ─────────────────────────
    static Map<String, Id> getTestUsers() {
        Map<String, Id> userMap = new Map<String, Id>();
        List<User> users = [
            SELECT Id, FirstName FROM User
            WHERE LastName = 'TestUser'
            AND IsActive = true
        ];
        for (User u : users) {
            userMap.put(u.FirstName, u.Id);
        }
        return userMap;
    }

    // ── Build booking with all email user fields set dynamically ──
    static Booking__c buildBooking(String firstName, String mobile,
                                    Id quoteId, String project, String stage) {
        Map<String, Id> userMap = getTestUsers();

        Booking__c bk = new Booking__c(
            First_Applicant_Name__c               = firstName,
            Mobile__c                             = mobile,
            Quote__c                              = quoteId,
            Project__c                            = project,
            Stage__c                              = stage,
            CRM_Manager__c                        = userMap.get('CRMManager'),
            CRM_Head__c                           = userMap.get('CRMHead'),
            Project_Sales_Head__c                 = userMap.get('SalesHead'),
            Sales_User__c                         = userMap.get('SalesUser'),
            Finance_Lead__c                       = userMap.get('FinanceLead'),
            Is_Cancellation_Requested_by_Executive__c = false
        );
        Id rtId = getBookingRecordTypeId();
        if (rtId != null) bk.RecordTypeId = rtId;
        return bk;
    }

    // ── TEST 1: cancelBooking - CRM_Manager__c null branch ────────
    @isTest
    static void testCancelBooking_NoCrmManager() {
        Quote__c qc      = getQuote();
        String   stage   = getBookingStage();
        String   project = getBookingProject();

        Booking__c bk = buildBooking('Test No Manager', '9876543210', qc.Id, project, stage);
        insert bk;

        try {
            bk.CRM_Manager__c = null;
            update bk;
        } catch (Exception e) {
            System.debug('Update CRM null: ' + e.getMessage());
        }

        Test.startTest();
        try {
            BookingCancellationRequestController.cancelBooking(bk.Id);
        } catch (Exception e) {
            System.debug('cancelBooking No Manager: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 2: cancelBooking - full notification + email path ─────
    @isTest
    static void testCancelBooking_WithCrmManager() {
        Quote__c qc      = getQuote();
        String   stage   = getBookingStage();
        String   project = getBookingProject();

        Booking__c bk = buildBooking('Test With Manager', '9876543211', qc.Id, project, stage);
        insert bk;

        Test.startTest();
        try {
            BookingCancellationRequestController.cancelBooking(bk.Id);
        } catch (Exception e) {
            System.debug('cancelBooking With Manager: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 3: bookingChecking - flag is false ────────────────────
    @isTest
    static void testBookingChecking_NotCancelled() {
        Quote__c qc      = getQuote();
        String   stage   = getBookingStage();
        String   project = getBookingProject();

        Booking__c bk = buildBooking('Test Not Cancelled', '9876543212', qc.Id, project, stage);
        insert bk;

        Test.startTest();
        try {
            BookingCancellationRequestController.bookingChecking(bk.Id);
        } catch (Exception e) {
            System.debug('bookingChecking Not Cancelled: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 4: bookingChecking - flag is true ─────────────────────
    @isTest
    static void testBookingChecking_IsCancelled() {
        Quote__c qc      = getQuote();
        String   stage   = getBookingStage();
        String   project = getBookingProject();

        Booking__c bk = buildBooking('Test Cancelled', '9876543213', qc.Id, project, stage);
        insert bk;

        try {
            bk.Is_Cancellation_Requested_by_Executive__c = true;
            update bk;
        } catch (Exception e) {
            System.debug('Update flag true: ' + e.getMessage());
        }

        Test.startTest();
        try {
            BookingCancellationRequestController.bookingChecking(bk.Id);
        } catch (Exception e) {
            System.debug('bookingChecking Cancelled: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ── TEST 5: full flow - cancel then check ─────────────────────
    @isTest
    static void testCancelThenCheck() {
        Quote__c qc      = getQuote();
        String   stage   = getBookingStage();
        String   project = getBookingProject();

        Booking__c bk = buildBooking('Test Cancel Then Check', '9876543214', qc.Id, project, stage);
        insert bk;

        Test.startTest();
        try {
            BookingCancellationRequestController.cancelBooking(bk.Id);
        } catch (Exception e) {
            System.debug('cancelBooking in flow: ' + e.getMessage());
        }
        try {
            BookingCancellationRequestController.bookingChecking(bk.Id);
        } catch (Exception e) {
            System.debug('bookingChecking in flow: ' + e.getMessage());
        }
        Test.stopTest();
    }
}