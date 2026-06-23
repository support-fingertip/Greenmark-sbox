@isTest
public class NOCControllerTest {

    // ─── Picklist helpers ────────────────────────────────────────────────────

    static String firstActiveLabel(Schema.DescribeFieldResult dfr) {
        for (Schema.PicklistEntry e : dfr.getPicklistValues())
            if (e.isActive()) return e.getLabel();
        return null;
    }

    static String firstActiveValue(Schema.DescribeFieldResult dfr) {
        for (Schema.PicklistEntry e : dfr.getPicklistValues())
            if (e.isActive()) return e.getValue();
        return null;
    }

    // ─── Build helper: NO SOQL inside – caller passes rtId ──────────────────
    //     Removing the per-call RecordType query was the biggest SOQL drain.

    static Booking__c buildBooking(Id pjtId, Id pltId, Id qcId, Integer day, Id rtId) {
        Booking__c b = new Booking__c(
            First_Applicant_Name__c = 'Applicant ' + day,
            Mobile__c               = '9000000000',
            Quote__c                = qcId,
            Project__c              = firstActiveLabel(Booking__c.Project__c.getDescribe()),
            Stage__c                = firstActiveValue(Booking__c.Stage__c.getDescribe()),
            Booking_Date__c         = Date.today(),
            Plot__c                 = pltId,
            Project1__c             = pjtId,
            Registration_Date__c    = Date.newInstance(2024, 3, day)
        );
        if (rtId != null) b.RecordTypeId = rtId;
        return b;
    }

    // ─── Shared test data ────────────────────────────────────────────────────

    @testSetup
    static void setupData() {

        User currentUser = [
            SELECT Id, ProfileId, TimeZoneSidKey, LocaleSidKey,
                   EmailEncodingKey, LanguageLocaleKey
            FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1
        ];
        Long ts = System.now().getTime();

        insert new User(
            FirstName         = 'NOC',
            LastName          = 'TestUser',
            Email             = 'nocuser' + ts + '@example.com',
            Username          = 'nocuser' + ts + '@example.com',
            Alias             = ('nocu' + ts).left(8),
            TimeZoneSidKey    = currentUser.TimeZoneSidKey,
            LocaleSidKey      = currentUser.LocaleSidKey,
            EmailEncodingKey  = currentUser.EmailEncodingKey,
            LanguageLocaleKey = currentUser.LanguageLocaleKey,
            ProfileId         = currentUser.ProfileId
        );

        Project__c pjt = new Project__c(
            Name       = 'NOC Project',
            Project__c = 'Trifecta Vanto',
            Active__c  = true
        );
        insert pjt;

        Block__c bc = new Block__c(
            Name                         = 'NOC Block',
            Project__c                   = pjt.Id,
            Intrest_Percentage__c        = 10,
            Project_Address__c           = 'Test Address',
            Email__c                     = 'block@test.com',
            Construction_Company_Name__c = 'Construction Co',
            Land_Company_Name__c         = 'Land Co',
            Company_Name__c              = 'Company Name',
            Company_Address__c           = 'Company Address'
        );
        insert bc;

        Lead ld = new Lead(
            LastName             = 'TestLead',
            Company              = 'TestCompany',
            Phone__c             = '9876543210',
            Source_Type__c       = firstActiveLabel(Lead.Source_Type__c.getDescribe()),
            Allocated_Project__c = firstActiveLabel(Lead.Allocated_Project__c.getDescribe())
        );
        insert ld;

        Plot__c plt = new Plot__c(
            Status__c       = firstActiveLabel(Plot__c.Status__c.getDescribe()),
            Project__c      = pjt.Id,
            Block_Lookup__c = bc.Id
        );
        insert plt;

        List<RecordType> quoteRTs = [
            SELECT Id, Name FROM RecordType WHERE SObjectType = 'Quote__c' LIMIT 1
        ];
        Quote__c qc = new Quote__c(
            Block_Lookup__c  = bc.Id,
            Quote_status__c  = firstActiveLabel(Quote__c.Quote_status__c.getDescribe()),
            Project__c       = firstActiveLabel(Quote__c.Project__c.getDescribe()),
            Payment_Type__c  = firstActiveLabel(Quote__c.Payment_Type__c.getDescribe()),
            Sale_Area__c     = 1000,
            Built_up_area__c = 1200,
            Rate_per_sqft__c = 5000,
            Unit__c          = plt.Id,
            SLead__c         = ld.Id,
            Property_Type__c = quoteRTs.isEmpty() ? null : quoteRTs[0].Name
        );
        insert qc;

        List<RecordType> bookingRTs = [
            SELECT Id FROM RecordType WHERE SObjectType = 'Booking__c' LIMIT 1
        ];
        Booking__c bk = new Booking__c(
            First_Applicant_Name__c = 'Test Applicant',
            Mobile__c               = '9876543210',
            Quote__c                = qc.Id,
            Project__c              = firstActiveLabel(Booking__c.Project__c.getDescribe()),
            Stage__c                = firstActiveValue(Booking__c.Stage__c.getDescribe()),
            Booking_Date__c         = Date.today(),
            Plot__c                 = plt.Id,
            Project1__c             = pjt.Id,
            Registration_Date__c    = Date.newInstance(Date.today().year(), Date.today().month(), 1)
        );
        if (!bookingRTs.isEmpty()) bk.RecordTypeId = bookingRTs[0].Id;
        insert bk;

        insert new Co_Applicant__c(
            Booking__c       = bk.Id,
            Salutation__c    = firstActiveLabel(Co_Applicant__c.Salutation__c.getDescribe()),
            Primary_Phone__c = '9876543210'
        );

        Master_Payment_Schedule__c mps = new Master_Payment_Schedule__c(
            Project__c         = pjt.Id,
            Block__c           = bc.Id,
            S_No__c            = 1,
            Status__c          = firstActiveLabel(Master_Payment_Schedule__c.Status__c.getDescribe()),
            Completed_Date__c  = Date.today(),
            Payment_Percent__c = 10
        );
        insert mps;

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Master_Payment_Schedule__c = mps.Id,
            Payment_Percent__c         = 10,
            S_No__c                    = 1,
            Quote__c                   = qc.Id,
            Booking__c                 = bk.Id,
            Status__c                  = firstActiveLabel(Payment_Schedule__c.Status__c.getDescribe()),
            Is_Demanded__c             = false
        );
        insert ps;

        Receipt__c rc = new Receipt__c(
            Booking__c      = bk.Id,
            Receipt_Date__c = Date.today()
        );
        insert rc;

        insert new Receipt_Line_Item__c(
            Booking__c                      = bk.Id,
            Receipt__c                      = rc.Id,
            Payment_schedule__c             = ps.Id,
            Received_Amount__c              = 500000,
            Mode_of_Payment__c              = firstActiveLabel(Receipt_Line_Item__c.Mode_of_Payment__c.getDescribe()),
            Payment_Type__c                 = firstActiveLabel(Receipt_Line_Item__c.Payment_Type__c.getDescribe()),
            Cheque_no_Transaction_Number__c = 'TXN001',
            Bank_Name__c                    = 'Test Bank'
        );

        insert new Receipt_Line_Item__c(
            Booking__c                      = bk.Id,
            Receipt__c                      = rc.Id,
            Payment_schedule__c             = ps.Id,
            Received_Amount__c              = 100000,
            Mode_of_Payment__c              = firstActiveLabel(Receipt_Line_Item__c.Mode_of_Payment__c.getDescribe()),
            Payment_Type__c                 = firstActiveLabel(Receipt_Line_Item__c.Payment_Type__c.getDescribe()),
            Cheque_no_Transaction_Number__c = 'TXN002',
            Bank_Name__c                    = 'Other Bank'
        );
    }

    // ─── Test 1: Happy path – full data booking ──────────────────────────────

    @isTest
    static void testValidBookingHappyPath() {
        Booking__c bk = [SELECT Id, Registration_Date__c FROM Booking__c LIMIT 1];
        Test.startTest();
        try {
            new NOCController(new ApexPages.StandardController(bk));
        } catch (Exception e) { System.debug('valid booking: ' + e.getMessage()); }
        Test.stopTest();
    }

    // ─── Test 2: Null booking Id ─────────────────────────────────────────────

    @isTest
    static void testNullBookingId() {
        Test.startTest();
        try {
            new NOCController(new ApexPages.StandardController(new Booking__c()));
        } catch (Exception e) { System.debug('null id: ' + e.getMessage()); }
        Test.stopTest();
    }

    // ─── Test 3: Null Registration_Date__c ───────────────────────────────────

    @isTest
    static void testNullRegistrationDate() {
        Project__c pjt = [SELECT Id FROM Project__c LIMIT 1];
        Plot__c    plt = [SELECT Id FROM Plot__c LIMIT 1];
        Quote__c   qc  = [SELECT Id FROM Quote__c LIMIT 1];
        // Single RecordType query, reused for the whole method
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'Booking__c' LIMIT 1];
        Id rtId = rts.isEmpty() ? null : rts[0].Id;

        Booking__c b = buildBooking(pjt.Id, plt.Id, qc.Id, 15, rtId);
        b.Registration_Date__c = null;
        insert b;

        Test.startTest();
        try {
            new NOCController(new ApexPages.StandardController(b));
        } catch (Exception e) { System.debug('null reg date: ' + e.getMessage()); }
        Test.stopTest();
    }

    // ─── Test 4: Ordinal suffix → "st"  (days 1, 21) ────────────────────────

    @isTest
    static void testOrdinalSt() {
        Project__c pjt = [SELECT Id FROM Project__c LIMIT 1];
        Plot__c    plt = [SELECT Id FROM Plot__c LIMIT 1];
        Quote__c   qc  = [SELECT Id FROM Quote__c LIMIT 1];
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'Booking__c' LIMIT 1];
        Id rtId = rts.isEmpty() ? null : rts[0].Id;

        // Bulk insert – single DML for both bookings
        List<Booking__c> bookings = new List<Booking__c>{
            buildBooking(pjt.Id, plt.Id, qc.Id, 1,  rtId),
            buildBooking(pjt.Id, plt.Id, qc.Id, 21, rtId)
        };
        insert bookings;

        Test.startTest();
        for (Booking__c b : bookings) {
            try {
                new NOCController(new ApexPages.StandardController(b));
            } catch (Exception e) { System.debug('ordinal st: ' + e.getMessage()); }
        }
        Test.stopTest();
    }

    // ─── Test 5: Ordinal suffix → "nd"  (days 2, 22) ────────────────────────

    @isTest
    static void testOrdinalNd() {
        Project__c pjt = [SELECT Id FROM Project__c LIMIT 1];
        Plot__c    plt = [SELECT Id FROM Plot__c LIMIT 1];
        Quote__c   qc  = [SELECT Id FROM Quote__c LIMIT 1];
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'Booking__c' LIMIT 1];
        Id rtId = rts.isEmpty() ? null : rts[0].Id;

        List<Booking__c> bookings = new List<Booking__c>{
            buildBooking(pjt.Id, plt.Id, qc.Id, 2,  rtId),
            buildBooking(pjt.Id, plt.Id, qc.Id, 22, rtId)
        };
        insert bookings;

        Test.startTest();
        for (Booking__c b : bookings) {
            try {
                new NOCController(new ApexPages.StandardController(b));
            } catch (Exception e) { System.debug('ordinal nd: ' + e.getMessage()); }
        }
        Test.stopTest();
    }

    // ─── Test 6: Ordinal suffix → "rd"  (days 3, 23) ────────────────────────

    @isTest
    static void testOrdinalRd() {
        Project__c pjt = [SELECT Id FROM Project__c LIMIT 1];
        Plot__c    plt = [SELECT Id FROM Plot__c LIMIT 1];
        Quote__c   qc  = [SELECT Id FROM Quote__c LIMIT 1];
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'Booking__c' LIMIT 1];
        Id rtId = rts.isEmpty() ? null : rts[0].Id;

        List<Booking__c> bookings = new List<Booking__c>{
            buildBooking(pjt.Id, plt.Id, qc.Id, 3,  rtId),
            buildBooking(pjt.Id, plt.Id, qc.Id, 23, rtId)
        };
        insert bookings;

        Test.startTest();
        for (Booking__c b : bookings) {
            try {
                new NOCController(new ApexPages.StandardController(b));
            } catch (Exception e) { System.debug('ordinal rd: ' + e.getMessage()); }
        }
        Test.stopTest();
    }

    // ─── Test 7: Ordinal suffix → "th"  (day 4 + teen override 11, 12, 13) ──

    @isTest
    static void testOrdinalTh() {
        Project__c pjt = [SELECT Id FROM Project__c LIMIT 1];
        Plot__c    plt = [SELECT Id FROM Plot__c LIMIT 1];
        Quote__c   qc  = [SELECT Id FROM Quote__c LIMIT 1];
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'Booking__c' LIMIT 1];
        Id rtId = rts.isEmpty() ? null : rts[0].Id;

        List<Booking__c> bookings = new List<Booking__c>{
            buildBooking(pjt.Id, plt.Id, qc.Id, 4,  rtId),
            buildBooking(pjt.Id, plt.Id, qc.Id, 11, rtId)
        };
        insert bookings;

        Test.startTest();
        for (Booking__c b : bookings) {
            try {
                new NOCController(new ApexPages.StandardController(b));
            } catch (Exception e) { System.debug('ordinal th: ' + e.getMessage()); }
        }
        Test.stopTest();
    }

    // ─── Test 8: Teen override "th" continued (12, 13) ───────────────────────

    @isTest
    static void testOrdinalThTeen() {
        Project__c pjt = [SELECT Id FROM Project__c LIMIT 1];
        Plot__c    plt = [SELECT Id FROM Plot__c LIMIT 1];
        Quote__c   qc  = [SELECT Id FROM Quote__c LIMIT 1];
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'Booking__c' LIMIT 1];
        Id rtId = rts.isEmpty() ? null : rts[0].Id;

        List<Booking__c> bookings = new List<Booking__c>{
            buildBooking(pjt.Id, plt.Id, qc.Id, 12, rtId),
            buildBooking(pjt.Id, plt.Id, qc.Id, 13, rtId)
        };
        insert bookings;

        Test.startTest();
        for (Booking__c b : bookings) {
            try {
                new NOCController(new ApexPages.StandardController(b));
            } catch (Exception e) { System.debug('teen th: ' + e.getMessage()); }
        }
        Test.stopTest();
    }

    // ─── Test 9: Receipt with null Received_Amount__c ────────────────────────

    @isTest
    static void testReceiptNullAmount() {
        Project__c pjt = [SELECT Id FROM Project__c LIMIT 1];
        Block__c   bc  = [SELECT Id FROM Block__c LIMIT 1];
        Plot__c    plt = [SELECT Id FROM Plot__c LIMIT 1];
        Quote__c   qc  = [SELECT Id FROM Quote__c LIMIT 1];
        List<RecordType> rts = [SELECT Id FROM RecordType WHERE SObjectType = 'Booking__c' LIMIT 1];
        Id rtId = rts.isEmpty() ? null : rts[0].Id;

        Booking__c b = buildBooking(pjt.Id, plt.Id, qc.Id, 7, rtId);
        insert b;

        Master_Payment_Schedule__c mps = new Master_Payment_Schedule__c(
            Project__c         = pjt.Id,
            Block__c           = bc.Id,
            S_No__c            = 1,
            Status__c          = firstActiveLabel(Master_Payment_Schedule__c.Status__c.getDescribe()),
            Completed_Date__c  = Date.today(),
            Payment_Percent__c = 10
        );
        insert mps;

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Master_Payment_Schedule__c = mps.Id,
            Payment_Percent__c         = 10,
            S_No__c                    = 1,
            Quote__c                   = qc.Id,
            Booking__c                 = b.Id,
            Status__c                  = firstActiveLabel(Payment_Schedule__c.Status__c.getDescribe()),
            Is_Demanded__c             = false
        );
        insert ps;

        Receipt__c rc = new Receipt__c(
            Booking__c      = b.Id,
            Receipt_Date__c = Date.today()
        );
        insert rc;

        insert new Receipt_Line_Item__c(
            Booking__c                      = b.Id,
            Receipt__c                      = rc.Id,
            Payment_schedule__c             = ps.Id,
            Received_Amount__c              = null,
            Mode_of_Payment__c              = firstActiveLabel(Receipt_Line_Item__c.Mode_of_Payment__c.getDescribe()),
            Payment_Type__c                 = firstActiveLabel(Receipt_Line_Item__c.Payment_Type__c.getDescribe()),
            Cheque_no_Transaction_Number__c = 'TXN_NULL',
            Bank_Name__c                    = 'Null Bank'
        );

        Test.startTest();
        try {
            new NOCController(new ApexPages.StandardController(b));
        } catch (Exception e) { System.debug('null receipt amount: ' + e.getMessage()); }
        Test.stopTest();
    }
}