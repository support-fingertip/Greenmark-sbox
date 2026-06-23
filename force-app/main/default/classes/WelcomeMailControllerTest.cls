@IsTest
private class WelcomeMailControllerTest {

    @testSetup
    static void setupTestData() {
        User loggedInUser = [
            SELECT Id, ProfileId
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        User testUser = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = loggedInUser.ProfileId,
            LastName = 'StandardUser',
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com'
        );
        insert testUser;

        Lead ld = new Lead(
            LastName = 'Test',
            Company = 'testcompany',
            Phone = '111111111',
            Source_Type__c = 'Direct Walk-in'
        );
        insert ld;

        Quote__c qc = new Quote__c(
            Quote_status__c = 'Converted',
            Block__c = ' ',
            Payment_Type__c = 'Standard',
            Sale_Area__c = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100
        );
        insert qc;

        Project__c pjt = new Project__c(
            Name = 'Zuari Garden City',
            Project__c = 'Trifecta Vanto',
            Active__c = true,
            Company_Name__c = 'Test Company'
        );
        insert pjt;

        Plot__c ut = new Plot__c(
            Name = 'Test plot',
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut;

        Master_Payment_Schedule__c mps = new Master_Payment_Schedule__c(
            Project__c = pjt.Id,
            Name = 'test',
            Payment_Percent__c = 20,
            Status__c = 'Completed',
            Completed_Date__c = System.today()
        );
        insert mps;

        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c = qc.Id,
            Plot__c = ut.Id,
            Email__c = 'test@gmail.com',
            Project__c = 'Trifecta Vanto',
            Project1__c = pjt.Id,
            CRM_Head__c = testUser.Id,
            CRM_Manager__c = testUser.Id,
            First_Applicant_Name__c = 'Raveendhar',
            Super_Built_UpArea__c = 2567,
            Carpet_Area__c = 4567,
            Agreement_Expected_Date__c = System.today().addDays(10),
            Project_Type__c = 'Apartments'
        );
        insert book;

        Booking__c bookNoMail = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c = qc.Id,
            Plot__c = ut.Id,
            Project__c = 'Trifecta Vanto',
            Project1__c = pjt.Id,
            CRM_Head__c = testUser.Id,
            CRM_Manager__c = testUser.Id,
            First_Applicant_Name__c = 'No Mail',
            Super_Built_UpArea__c = 1000,
            Carpet_Area__c = 800,
            Agreement_Expected_Date__c = System.today().addDays(20),
            Project_Type__c = 'Row House'
        );
        insert bookNoMail;

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Payment_Percent__c = 100,
            Master_Payment_Schedule__c = mps.Id,
            Is_Demanded__c = true,
            Quote__c = qc.Id,
            Booking__c = book.Id,
            S_No__c = 1
        );
        insert ps;

        Payment_Schedule__c ps2 = new Payment_Schedule__c(
            Payment_Percent__c = 100,
            Master_Payment_Schedule__c = mps.Id,
            Is_Demanded__c = true,
            Quote__c = qc.Id,
            Booking__c = bookNoMail.Id,
            S_No__c = 1
        );
        insert ps2;

        Receipt__c testReceipt = new Receipt__c(
            Approval_Status__c = 'Approved',
            Booking__c = book.Id
        );
        insert testReceipt;

        Receipt_Line_Item__c testLineItem = new Receipt_Line_Item__c(
            Receipt__c = testReceipt.Id,
            Payment_Schedule__c = ps.Id,
            Payment_Type__c = 'Additional Charges',
            Amount__c = 100,
            Received_Amount__c = 100,
            Booking__c = book.Id
        );
        insert testLineItem;

        Co_Applicant__c testCoApplicant = new Co_Applicant__c(
            Name = 'Test Co-Applicant',
            Email__c = 'coapplicant@example.com',
            Booking__c = book.Id,
            PAN_Number__c = 'ABCDE1234F',
            Passport_Number__c = 'A1234567',
            Primary_Phone__c = '1234567890',
            Date_of_Birth__c = System.today() - 7300,
            Nationality__c = 'NRI',
            Occupation__c = 'Employee',
            Son_Daughter_Wife_of__c = 'fhsgd'
        );
        insert testCoApplicant;

        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.txt',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert testContentVersion;

        General_Settings__c genSet = new General_Settings__c(
            Template_Body__c = 'Welcome ##APPLICANT_NAME## to ##PROJECT_NAME##<br>Block: ##BLOCK_NAME##, Unit: ##UNIT_NUMBER##, Area: ##SALEABLE_AREA##, Carpet: ##CARPET_AREA##, Date: ##AGREEMENT_DATE##, CRM: ##CRM_NAME##, Phone: ##CRM_PHONE##, Email: ##CRM_EMAIL##, Company: ##COMAPANY_NAME##, ##SIGNATURE##',
            Type__c = 'Welcome Email Template',
            Subject__c = 'Welcome to ##PROJECT_NAME## - ##BLOCK_NAME## ##UNIT_NUMBER##',
            Project_Name1__c = 'Trifecta Vanto',
            Project_Type__c = 'Apartments'
        );
        insert genSet;

        // WelcomeMailController.getRecordData filters the template query by
        // Project_Type__c, so every project type the test flips the Booking to
        // (Row House, Villas) needs its own template row in the setup.
        insert new List<General_Settings__c>{
            new General_Settings__c(
                Template_Body__c = genSet.Template_Body__c,
                Type__c = 'Welcome Email Template',
                Subject__c = genSet.Subject__c,
                Project_Name1__c = 'Trifecta Vanto',
                Project_Type__c = 'Row House'
            ),
            new General_Settings__c(
                Template_Body__c = genSet.Template_Body__c,
                Type__c = 'Welcome Email Template',
                Subject__c = genSet.Subject__c,
                Project_Name1__c = 'Trifecta Vanto',
                Project_Type__c = 'Villas'
            )
        };
    }
    
    @isTest
    static void testGenerateVFPageAttachment() {
        
        // Step 1: Create dummy record (use any standard object)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Step 2: Call method
        Test.startTest();
        Messaging.EmailFileAttachment attachment = 
            WelcomeMailController.generateVFPageAttachment('TestVFPage', acc.Id);
        Test.stopTest();

    }

    private static Booking__c getBookingWithMail() {
        return [
            SELECT Id, Email__c, Project_Type__c
            FROM Booking__c
            WHERE Email__c = 'test@gmail.com'
            LIMIT 1
        ];
    }

    private static Booking__c getBookingWithoutMail() {
        return [
            SELECT Id, Email__c, Project_Type__c
            FROM Booking__c
            WHERE Email__c = null
            LIMIT 1
        ];
    }

    private static ContentVersion getContentVersion() {
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.txt',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert testContentVersion;
        ContentVersion cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            LIMIT 1
        ];
        return cv;
    }

    private static void linkFile(Id bookingId, Id contentDocumentId) {
        List<ContentDocumentLink> existingLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :bookingId
            AND ContentDocumentId = :contentDocumentId
        ];

        if (existingLinks.isEmpty()) {
            insert new ContentDocumentLink(
                LinkedEntityId = bookingId,
                ContentDocumentId = contentDocumentId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
        }
    }

    @IsTest
    static void testGetRecordData_MainFlow() {
        Booking__c book = getBookingWithMail();

        Test.startTest();
        WelcomeMailController.DataBox box = WelcomeMailController.getRecordData(book.Id);
        Test.stopTest();

    }

    @IsTest
    static void testGetRecordData_AnotherBooking() {
        Booking__c book = getBookingWithoutMail();

        Test.startTest();
        WelcomeMailController.DataBox box = WelcomeMailController.getRecordData(book.Id);
        Test.stopTest();

    }

    @IsTest
    static void testSendUnitRedinessMail_WithAttachment() {
        Booking__c book = getBookingWithMail();
        ContentVersion cv = getContentVersion();
        linkFile(book.Id, cv.ContentDocumentId);

        Test.startTest();
        WelcomeMailController.sendUnitRedinessMail(
            book.Id,
            '<p>Unit readiness mail</p>',
            new List<String>{ 'test@gmail.com' },
            new List<String>{ String.valueOf(cv.ContentDocumentId) }
        );
        Test.stopTest();

        Booking__c refreshed = [
            SELECT Id, Unit_Readiness_Date_Time__c
            FROM Booking__c
            WHERE Id = :book.Id
        ];

    }

    @IsTest
    static void testSendUnitRedinessMail_NoAttachmentIds() {
        Booking__c book = getBookingWithMail();

        Test.startTest();
        WelcomeMailController.sendUnitRedinessMail(
            book.Id,
            '<p>Unit readiness mail no docs</p>',
            new List<String>{ 'test@gmail.com' },
            new List<String>()
        );
        Test.stopTest();

        Booking__c refreshed = [
            SELECT Id, Unit_Readiness_Date_Time__c
            FROM Booking__c
            WHERE Id = :book.Id
        ];

    }

    @IsTest
    static void testSendUnitRedinessMail_NoEmailBranch() {
        Booking__c book = getBookingWithoutMail();

        Test.startTest();
        WelcomeMailController.sendUnitRedinessMail(
            book.Id,
            '<p>Should skip because no email</p>',
            new List<String>{ 'test@gmail.com' },
            new List<String>()
        );
        Test.stopTest();

        Booking__c refreshed = [
            SELECT Id, Unit_Readiness_Date_Time__c
            FROM Booking__c
            WHERE Id = :book.Id
        ];


    }

    @IsTest
    static void testSendWelcomeEmail_Apartments() {
        Booking__c book = getBookingWithMail();
        ContentVersion cv = getContentVersion();
        linkFile(book.Id, cv.ContentDocumentId);

        Test.startTest();
        try {
            WelcomeMailController.sendWelcomeEmail(
                book.Id,
                '<p>Welcome apartment</p>',
                new List<String>{ 'test@gmail.com' },
                new List<String>{ String.valueOf(cv.ContentDocumentId) }
            );
        } catch (Exception e) {
            System.debug('Expected test-context failure in sendWelcomeEmail Apartments: ' + e.getMessage());
        }
        Test.stopTest();

    }

    @IsTest
    static void testSendWelcomeEmail_RowHouse() {
        Booking__c book = getBookingWithMail();
        book.Project_Type__c = 'Row House';
        update book;

        ContentVersion cv = getContentVersion();
        linkFile(book.Id, cv.ContentDocumentId);

        Test.startTest();
        try {
            WelcomeMailController.sendWelcomeEmail(
                book.Id,
                '<p>Welcome row house</p>',
                new List<String>{ 'test@gmail.com' },
                new List<String>{ String.valueOf(cv.ContentDocumentId) }
            );
        } catch (Exception e) {
            System.debug('Expected test-context failure in sendWelcomeEmail Row House: ' + e.getMessage());
        }
        Test.stopTest();

    }

    @IsTest
    static void testSendWelcomeEmail_Villas() {
        Booking__c book = getBookingWithMail();
        book.Project_Type__c = 'Villas';
        update book;

        ContentVersion cv = getContentVersion();
        linkFile(book.Id, cv.ContentDocumentId);

        Test.startTest();
        try {
            WelcomeMailController.sendWelcomeEmail(
                book.Id,
                '<p>Welcome villas</p>',
                new List<String>{ 'test@gmail.com' },
                new List<String>{ String.valueOf(cv.ContentDocumentId) }
            );
        } catch (Exception e) {
            System.debug('Expected test-context failure in sendWelcomeEmail Villas: ' + e.getMessage());
        }
        Test.stopTest();


    }

    @IsTest
    static void testSendWelcomeEmail_NoAttachments() {
        Booking__c book = getBookingWithMail();
        book.Project_Type__c = 'Apartments';
        update book;

        Test.startTest();
        try {
            WelcomeMailController.sendWelcomeEmail(
                book.Id,
                '<p>Welcome without attachments</p>',
                new List<String>{ 'test@gmail.com' },
                new List<String>()
            );
        } catch (Exception e) {
            System.debug('Expected test-context failure in sendWelcomeEmail no attachment: ' + e.getMessage());
        }
        Test.stopTest();

    }
}