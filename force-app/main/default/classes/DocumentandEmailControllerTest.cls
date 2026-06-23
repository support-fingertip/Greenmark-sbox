@IsTest
public class DocumentandEmailControllerTest {

    @testSetup
    static void setup() {

        // ---- User (for Owner tests) ----
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // ---- Project ----
        Project__c prj = new Project__c(
            Name = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c = true,
            CRM_executive__c = UserInfo.getUserId(),
            CRM_Manager__c = UserInfo.getUserId(),
            Sales_Head__c = UserInfo.getUserId(),
            Finance_User__c = UserInfo.getUserId(),
            COO__c = UserInfo.getUserId()
        );
        insert prj;

        // ---- Plot ----
        Plot__c plot = new Plot__c(
            Name = 'Plot-001',
            Status__c = 'Available',
            Unit_Facing_Direction__c = 'North',
            Project__c = prj.Id
        );
        insert plot;

        // ---- Lead ----
        Lead ld = new Lead(
            FirstName = 'Test',
            LastName  = 'Lead',
            Company   = 'Test Company',
            Email     = 'test@example.com',
            Phone     = '1234567890',
            Allocated_Project__c = 'Trifecta Vanto',
            Source_Type__c = 'Google',
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId()
        );
        insert ld;

        // ---- Quote ----
        Quote__c qt = new Quote__c(
            SLead__c = ld.Id,
            Quote_status__c = 'Converted',
            Quote_date__c = Date.today(),
            Project__c = 'Trifecta Vanto',
            Payment_Type__c = 'Standard',
            Built_up_area__c = 1000,
            Plot_Land_Area__c = 1200,
            Clubhouse_Charges__c = 50000,
            Infrastructure_Charges_per_sqft__c = 100,
            Maintenance_Charge__c = 2000,
            Corpus_Fund__c = 10000,
            Legal_Documentation_Charges__c = 5000,
            Unit__c = plot.Id
        );
        insert qt;

        // ---- Booking (for most tests) ----
        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'Test Applicant',
            S__c = 'Mr.',
            Email__c = 'customer@example.com',
            PAN_Number__c = 'ABCDE1234F',
            Plot__c = plot.Id,
            Project1__c = prj.Id,
            Funding_Type__c = 'Self',
            Agreement_Execution_Amount1__c = 95000,
            Quote__c = qt.Id,
            SLead__c = ld.Id,
            Project__c = qt.Project__c,
            Stage__c = 'Booked',
            OwnerId = testUser.Id,
            Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000,
            Mode_Of_Payment__c = 'Cheque'
        );
        insert booking;

        // ---- Co-Applicant ----
        Co_Applicant__c ca = new Co_Applicant__c(
            Booking__c = booking.Id,
            Name = 'Co Applicant',
            PAN_Number__c = 'ABCDE1234F',
            Email__c = 'coapp@example.com',
            Primary_Phone__c ='9908073348'
        );
        insert ca;

        // ---- Receipt ----
        Receipt__c rec = new Receipt__c(
            Booking__c = booking.Id,
            Approval_Status__c = 'Approved',
            Receipt_date__c = Date.today()
        );
        insert rec;

        // ---- Demand Raised ----
        Demand_Raised__c demand = new Demand_Raised__c(
            Booking__c = booking.Id,
            Demand_Name__c = 'Agreement Amount',
            Demand_Email_Content__c = 'Dear Customer,<br/>Please find the attached demand note.<br/>Thanks.'
        );
        insert demand;

        // ---- Booking with NO Email (for negative receipt test) ----
        Booking__c bookingNoEmail = new Booking__c(
            First_Applicant_Name__c = 'John Doe',
            Plot__c = plot.Id,
            Project1__c = prj.Id,
            S__c = 'Mrs.',
            Funding_Type__c = 'Self', 
            OwnerId = testUser.Id
        );
        insert bookingNoEmail;

        Receipt__c recNoEmail = new Receipt__c(
            Booking__c = bookingNoEmail.Id
        );
        insert recNoEmail;

        // ---- Booking for "Ms. Alice" name test ----
        Booking__c bookingAlice = new Booking__c(
            First_Applicant_Name__c = 'Alice',
            S__c = 'Mrs.',
            Email__c = 'alice@example.com',
            PAN_Number__c = 'ABCDE1234F',
            Plot__c = plot.Id,
            Project1__c = prj.Id,
            Funding_Type__c = 'Self',
            Agreement_Execution_Amount1__c = 95000,
            OwnerId = testUser.Id
        );
        insert bookingAlice;
    }

    // -------- Helpers --------
    private static Booking__c getBookingMain() {
        return [
            SELECT Id, Email__c, First_Applicant_Name__c, S__c
            FROM Booking__c
            WHERE First_Applicant_Name__c = 'Test Applicant'
            LIMIT 1
        ];
    }

    private static Booking__c getBookingAlice() {
        return [
            SELECT Id, Email__c, First_Applicant_Name__c, S__c
            FROM Booking__c
            WHERE First_Applicant_Name__c = 'Alice'
            LIMIT 1
        ];
    }

    private static Receipt__c getReceiptMain() {
        return [
            SELECT Id, Booking__c
            FROM Receipt__c
            WHERE Booking__r.First_Applicant_Name__c = 'Test Applicant'
            LIMIT 1
        ];
    }

    private static Receipt__c getReceiptNoEmailBooking() {
        return [
            SELECT Id, Booking__c
            FROM Receipt__c
            WHERE Booking__r.First_Applicant_Name__c = 'John Doe'
            LIMIT 1
        ];
    }

    private static Demand_Raised__c getDemandMain() {
        return [
            SELECT Id
            FROM Demand_Raised__c
            LIMIT 1
        ];
    }

    // -------- Tests --------

    @IsTest
    static void testGetBookingDetails_BasicFields() {
        Booking__c booking = getBookingAlice();

        Test.startTest();
        DocumentandEmailController.BookingDataWrapper result =
            DocumentandEmailController.getBookingDetails(booking.Id);
        Test.stopTest();

    }

    @IsTest
    static void testGetBookingDetails() {
        Booking__c b = getBookingMain();

        Test.startTest();
        DocumentandEmailController.BookingDataWrapper w =
            DocumentandEmailController.getBookingDetails(b.Id);
        Test.stopTest();


    }

    @IsTest
    static void testSendEmailGenerateReceipt_success() {
        Receipt__c r = getReceiptMain();

        Test.startTest();
        String msg = DocumentandEmailController.sendEmailGenerateReceipt(r.Id);
        Test.stopTest();

    }

    @IsTest
    static void testSendEmailGenerateReceipt_noBookingEmail() {
        Receipt__c r = getReceiptNoEmailBooking();

        Test.startTest();
        String result = DocumentandEmailController.sendEmailGenerateReceipt(r.Id);
        Test.stopTest();

    }

    @IsTest
    static void testSendEmailGenerateReceipt_invalidReceipt_nullId() {
        Test.startTest();
        String result = DocumentandEmailController.sendEmailGenerateReceipt(null);
        Test.stopTest();

    }

    @IsTest
    static void testSendEmailGenerateReceiptfromTrigger_future() {
        Receipt__c r = getReceiptMain();
        
               Project__c pjt = new Project__c(
            Name = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c = true
        );
        insert pjt;
        
        
        Block__c bc = new Block__c(
            Name = 'A',
            Project__c = pjt.Id,
            Intrest_Percentage__c =12
        );
        insert bc;
        
        
        Lead ld = new Lead(
            LastName = 'Test',
            Company = 'testcompany',
            Phone__c = '8778987789',
            Source_Type__c = 'Google',
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert ld;
        
        Plot__c ut = new Plot__c(
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut;
        
        Quote__c qc = new Quote__c(
            Block_Lookup__c = bc.Id,
            Quote_status__c = 'Drafted',
            Block__c = 'A2',
            Project__c = 'Trifecta Vanto',
            Payment_Type__c = 'Standard',
            Sale_Area__c = 2567,
            Built_up_area__c = 4567,
            
            Unit__c = ut.Id,
            SLead__c = ld.Id,
            GST__c = 18
        );
        insert qc;
        
        
        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c = qc.Id,
            Plot__c = ut.Id,
            CRM_Manager__c = UserInfo.getUserId()
            
        );
        insert book;
        
        Master_payment_schedule__c mps = new Master_payment_schedule__c();
        mps.Project__c = pjt.id;
        mps.Name = 'test';
        mps.Payment_Percent__c = 20;
        mps.Completed_Date__c = system.today();
        mps.Status__c ='Completed';
        insert mps;
        
        
        Payment_schedule__c ps = new Payment_schedule__c();
        ps.Payment_percent__c =100;
        ps.Master_Payment_Schedule__c = mps.Id;
        ps.Is_Demanded__c = true;
        ps.Quote__c = qc.id;
        ps.Amount__c = 400000;
        ps.Booking__c = book.Id;
        ps.Include_Interest__c =true;
        ps.Payment_Due_Date__c = Date.today().addDays(-15);
        ps.Last_Payment_Date__c = null;  
         
        insert ps;
        
        Receipt_Line_Item__c rcl = new Receipt_Line_Item__c(
            
            Amount__c = 30000,
            Mode_of_Payment__c = 'Cheque',
            Bank_Name__c = 'test',
            Cheque_no_Transaction_Number__c = 'sdgfsg23124',
            Drawn_On__c = Date.Today(),
            Payment_schedule__c = ps.Id,
            Payment_Type__c = 'Flat Amount',
            Received_Amount__c = 50000,
            Receipt__c = r.Id
            
        );
        insert rcl;
        
        General_Settings__c gs = new General_Settings__c();
        gs.Template_Body__c = 'tyest';
        gs.Subject__c = 'test';
        gs.Project_Name1__c = 'Trifecta Vanto';
        gs.Type__c = 'Payment Receipt';
        insert gs;
        Test.startTest();
        DocumentandEmailController.sendEmailGenerateReceiptfromTrigger(r.Id);
        Test.stopTest();

    }

    @IsTest
    static void testSendEmailGenerateSA() {
        Booking__c b = getBookingMain();

        Test.startTest();
        String msg = DocumentandEmailController.sendEmailGenerateSA(
            b.Id,
            'Dear Customer,<br/>Please find attached Sale Agreement.<br/>Thanks.'
        );
        Test.stopTest();

    }



    @IsTest
    static void testValidateEmails() {
        List<String> input = new List<String>{
            'valid@example.com',
            'bad-email',
            null,
            'also.valid+1@test.co'
        };

        Test.startTest();
        List<String> outList = DocumentandEmailController.validateEmails(input);
        Test.stopTest();

     
    }

    @IsTest
    static void testGetBookingRecordViaReciept() {
        Receipt__c r = getReceiptMain();

        Test.startTest();
        Booking__c b = DocumentandEmailController.getBookingRecordViaReciept(r.Id);
        Test.stopTest();


    }

    @IsTest
    static void testSendAgreementRequestMail() {
        Booking__c b = getBookingMain();

        Test.startTest();
        String msg = DocumentandEmailController.sendAgreementRequestMail(
            b.Id,
            'Dear Customer,<br/>Please confirm agreement execution date.<br/>Thanks.'
        );
        Test.stopTest();


    }

    @IsTest
    static void testSendHandoverEmail() {
        Booking__c b = getBookingMain();

        Test.startTest();
        String msg = DocumentandEmailController.sendHandoverEmail(b.Id);
        Test.stopTest();

    }

    @IsTest
    static void testSendHandoverEmail_noCustomerEmail() {
        Booking__c b = getBookingMain();
        b.Email__c = null;
        update b;

        Test.startTest();
        String msg = DocumentandEmailController.sendHandoverEmail(b.Id);
        Test.stopTest();

    }
    
      @isTest
    static void testSendEmailGenerateDemand() {

        // ── 1. Create Test User ─────────────────────────────
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // ── 2. Create Booking Record ─────────────────────
        Booking__c booking = new Booking__c(
            Email__c = 'customer@test.com',
            OwnerId = testUser.Id
        );
        insert booking;

        // ── 3. Create Demand Record ─────────────────────
        Demand_Raised__c demand = new Demand_Raised__c(
            Demand_Name__c = 'Final Payment',
            Booking__c = booking.Id,
            Demand_Email_Content__c = '<p>Hello Customer</p>'
        );
        insert demand;

        // ── 4. Create ContentVersion (Attachment) ─────────
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test Data'),
            IsMajorVersion = true
        );
        insert cv;

        // Get ContentDocumentId
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        List<Id> contentIds = new List<Id>{ cv.ContentDocumentId };

        Test.startTest();

        // ── 5. Call Method ─────────────────────────────
        DocumentandEmailController.sendEmailGenerateDemand(
            new List<Id>{ demand.Id },
            contentIds
        );

        Test.stopTest();

    }
     @isTest
    static void testSendKeyHandoverEmail() {

        // ── 1. Create User ─────────────────────────────
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'owner@test.com',
            Username = 'owner' + System.currentTimeMillis() + '@test.com',
            Alias = 'tusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        // ── 2. Create Booking ─────────────────────────
        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'Durga',
            Email__c = 'customer@test.com',
            Email1__c = 'customer2@test.com',
            OwnerId = u.Id,
            Project_Type__c = 'Villas'
        );
        insert booking;

        // ── 3. Create Co-Applicant ────────────────────
        Co_Applicant__c ca = new Co_Applicant__c(
            Booking__c = booking.Id,
            Email__c = 'coapp@test.com',
            Primary_Phone__c = '9908073349'
        );
        insert ca;

        Test.startTest();

        String result = DocumentandEmailController.sendKeyHandoverEmail(booking.Id);

        Test.stopTest();

    
    }

    @isTest
    static void testSendPossessionLetterViaProjectType() {

        // ── 1. Create User ─────────────────────────────
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'owner@test.com',
            Username = 'owner2' + System.currentTimeMillis() + '@test.com',
            Alias = 'tusr2',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        // ── 2. Create Booking ─────────────────────────
        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'Prasad',
            Email__c = 'customer@test.com',
            OwnerId = u.Id,
            Project_Type__c = 'Apartments',
            Project__c = 'Trifecta Vanto'
        );
        insert booking;

        // ── 3. Create Co-Applicant ────────────────────
        Co_Applicant__c ca = new Co_Applicant__c(
            Booking__c = booking.Id,
            Email__c = 'coapp2@test.com',
            Primary_Phone__c ='9908073349'
        );
        insert ca;

        Test.startTest();

        String result = DocumentandEmailController.sendPossessionLetterViaProjectType(booking.Id);

        Test.stopTest();


    }

    @isTest
    static void testInvalidProjectType() {

        // ── Booking with invalid project type ─────────
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'owner3@test.com',
            Username = 'owner3' + System.currentTimeMillis() + '@test.com',
            Alias = 'tusr3',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        Booking__c booking = new Booking__c(
            Email__c = 'customer@test.com',
            OwnerId = u.Id,
            Project_Type__c = 'Villas'
        );
        insert booking;

        Test.startTest();

        String result1 = DocumentandEmailController.sendKeyHandoverEmail(booking.Id);
        String result2 = DocumentandEmailController.sendPossessionLetterViaProjectType(booking.Id);

        Test.stopTest();

    }
}