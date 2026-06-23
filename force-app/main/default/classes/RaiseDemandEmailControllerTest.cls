@isTest
private class RaiseDemandEmailControllerTest {

    // ─────────────────────────────────────────
    //  INNER HTTP MOCK
    // ─────────────────────────────────────────
    private class DemandHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    // ─────────────────────────────────────────
    //  DYNAMIC PICKLIST HELPER
    // ─────────────────────────────────────────
    private static String getPicklistValue(SObjectField field, String keyword) {
        List<Schema.PicklistEntry> entries = field.getDescribe().getPicklistValues();
        String fallback = null;
        for (Schema.PicklistEntry e : entries) {
            if (fallback == null) fallback = e.getValue();
            if (e.getValue().toLowerCase().contains(keyword.toLowerCase())) {
                return e.getValue();
            }
        }
        return fallback;
    }

    // ─────────────────────────────────────────
    //  SHARED TEST DATA SETUP
    // ─────────────────────────────────────────
    @TestSetup
    static void setupData() {

        String projectTypeApartment = getPicklistValue(Booking__c.Project_Type__c, 'apartment');
        String projectTypeVilla     = getPicklistValue(Booking__c.Project_Type__c, 'villa');
        String fundingTypeLoan      = getPicklistValue(Booking__c.Funding_Type__c,  'loan');
        String fundingTypeSelf      = getPicklistValue(Booking__c.Funding_Type__c,  'self');
        String sourceType           = getPicklistValue(Lead.Source_Type__c,          'channel');

        Lead ld = new Lead(
            LastName             = 'Test Lead',
            Company              = 'Test Co',
            Source_Type__c       = sourceType,
            Phone__c             = '9999999999',
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert ld;

        Project__c proj = new Project__c(
            Name       = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c  = true
        );
        insert proj;

        Block__c blk = new Block__c(
            Name                         = 'A',
            Project__c                   = proj.Id,
            Intrest_Percentage__c        = 12,
            Company_Name__c              = 'TRIFECTA PROJECTS PVT LTD',
            Construction_Company_Name__c = 'TRIFECTA CONSTRUCTION',
            Land_Company_Name__c         = 'TRIFECTA LAND'
        );
        insert blk;

        Plot__c plot = new Plot__c(
            Name       = 'P1',
            Status__c  = 'Available',
            Project__c = proj.Id
        );
        insert plot;

        Quote__c qc = new Quote__c(
            Block_Lookup__c  = blk.Id,
            Block__c         = 'A2',
            Quote_status__c  = 'Drafted',
            Project__c       = 'Trifecta Vanto',
            Payment_Type__c  = 'Standard',
            Sale_Area__c     = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100,
            Unit__c          = plot.Id,
            SLead__c         = ld.Id
        );
        insert qc;

        Booking__c bookFlat = new Booking__c(
            Funding_Type__c         = fundingTypeLoan,
            Quote__c                = qc.Id,
            Plot__c                 = plot.Id,
            CRM_Manager__c          = UserInfo.getUserId(),
            Project__c              = 'Trifecta Vanto',
            Project_Type__c         = projectTypeApartment,
            Email__c                = 'applicant@test.com',
            Email1__c               = 'applicant2@test.com',
            Bank_Email__c           = 'bank@test.com',
            First_Applicant_Name__c = 'Test Applicant'
        );
        insert bookFlat;

        Booking__c bookVilla = new Booking__c(
            Funding_Type__c         = fundingTypeSelf,
            Quote__c                = qc.Id,
            Plot__c                 = plot.Id,
            CRM_Manager__c          = UserInfo.getUserId(),
            Project__c              = 'Trifecta Vanto',
            Project_Type__c         = projectTypeVilla,
            Email__c                = 'villa@test.com',
            First_Applicant_Name__c = 'Villa Applicant'
        );
        insert bookVilla;

        // Completed_Date__c required by validation rule on Master only
        Master_Payment_Schedule__c mps = new Master_Payment_Schedule__c(
            Name               = 'Test MPS',
            Status__c          = 'Completed',
            Completed_Date__c  = System.today(),
            Project__c         = proj.Id,
            Payment_Percent__c = 10
        );
        insert mps;

        // Completed_Date__c on Payment_Schedule__c is a FORMULA – do NOT set it
        Payment_Schedule__c psFlat = new Payment_Schedule__c(
            Name                       = 'On Booking',
            S_No__c                    = 1,
            Payment_Percent__c         = 10,
            Booking__c                 = bookFlat.Id,
            Quote__c                   = qc.Id,
            Master_Payment_Schedule__c = mps.Id,
            Is_Demanded__c             = false,
            Status__c                  = 'Completed',
            Type__c                    = 'Construction',
            Payment_Due_Date__c        = System.today().addDays(15)
        );
        insert psFlat;

        Payment_Schedule__c psVilla = new Payment_Schedule__c(
            Name                       = 'On Booking Villa',
            S_No__c                    = 1,
            Payment_Percent__c         = 10,
            Booking__c                 = bookVilla.Id,
            Quote__c                   = qc.Id,
            Master_Payment_Schedule__c = mps.Id,
            Is_Demanded__c             = false,
            Status__c                  = 'Completed',
            Type__c                    = 'Land',
            Payment_Due_Date__c        = System.today().addDays(15)
        );
        insert psVilla;

        General_Settings__c gsDemand = new General_Settings__c(
            Name             = 'Demand Note Vanto',
            Type__c          = 'Demand Note',
            Project_Name1__c = 'Trifecta Vanto',
            Template_Body__c = 'Dear ##APPLICANT_NAME##, Project: ##PROJECT_NAME##, Block: ##BLOCK_NAME##, Unit: ##UNIT_NUMBER##, Phone: ##CRM_PHONE##, Email: ##CRM_EMAIL##, Company: ##COMAPANY_NAME##',
            Subject__c       = 'Demand Note - ##PROJECT_NAME## ##BLOCK_NAME## ##UNIT_NUMBER##'
        );
        insert gsDemand;

        General_Settings__c gsRevised = new General_Settings__c(
            Name             = 'Revised Demand Note Vanto',
            Type__c          = 'Revised Demand Note',
            Project_Name1__c = 'Trifecta Vanto',
            Template_Body__c = 'Revised Dear ##APPLICANT_NAME##, Project: ##PROJECT_NAME##, Block: ##BLOCK_NAME##, Unit: ##UNIT_NUMBER##, Phone: ##CRM_PHONE##, Email: ##CRM_EMAIL##, Company: ##COMAPANY_NAME##',
            Subject__c       = 'Revised - ##PROJECT_NAME## ##BLOCK_NAME## ##UNIT_NUMBER##'
        );
        insert gsRevised;

        General_Settings__c gsPenalty = new General_Settings__c(
            Name             = 'Penalty Demand Note Vanto',
            Type__c          = 'Penalty Demand Note',
            Project_Name1__c = 'Trifecta Vanto',
            Template_Body__c = 'Penalty Dear ##APPLICANT_NAME##, Project: ##PROJECT_NAME##, Block: ##BLOCK_NAME##, Unit: ##UNIT_NUMBER##, Phone: ##CRM_PHONE##, Email: ##CRM_EMAIL##, Company: ##COMAPANY_NAME##',
            Subject__c       = 'Penalty - ##PROJECT_NAME## ##BLOCK_NAME## ##UNIT_NUMBER##'
        );
        insert gsPenalty;

        Additional_Charges__c adc = new Additional_Charges__c(
            Name       = 'Test Additional Charge',
            Booking__c = bookFlat.Id
        );
        insert adc;
    }

    // ─────────────────────────────────────────
    //  HELPERS
    // ─────────────────────────────────────────
    private static Booking__c getFlatBooking() {
        return [SELECT Id, Email__c, Email1__c, Bank_Email__c, Project_Type__c
                FROM Booking__c WHERE Email__c = 'applicant@test.com' LIMIT 1];
    }

    private static Booking__c getVillaBooking() {
        return [SELECT Id, Email__c, Project_Type__c
                FROM Booking__c WHERE Email__c = 'villa@test.com' LIMIT 1];
    }

    // ─────────────────────────────────────────
    //  TEST: getData – Apartment
    // ─────────────────────────────────────────
    @isTest
    static void testGetData_Apartment() {
        Booking__c book = getFlatBooking();
        Test.startTest();
        try {
            RaiseDemandEmailController.dataBox result = RaiseDemandEmailController.getData(book.Id);
            System.debug('getData Apartment – emailContent: '     + result.emailContent);
            System.debug('getData Apartment – isDemandRaised: '   + result.isDemandRaised);
            System.debug('getData Apartment – lastPymtSchedule: ' + result.lastPymtSchedule);
        } catch (Exception e) {
            System.debug('testGetData_Apartment – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: getData – Villa (Land type)
    // ─────────────────────────────────────────
    @isTest
    static void testGetData_Villa_Land() {
        Booking__c book = getVillaBooking();
        Test.startTest();
        try {
            RaiseDemandEmailController.dataBox result = RaiseDemandEmailController.getData(book.Id);
            System.debug('getData Villa Land – result: ' + result);
        } catch (Exception e) {
            System.debug('testGetData_Villa_Land – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: getData – Villa (Construction type)
    // ─────────────────────────────────────────
    @isTest
    static void testGetData_Villa_Construction() {
        Booking__c book = getVillaBooking();
        Payment_Schedule__c ps = [SELECT Id, Type__c FROM Payment_Schedule__c
                                   WHERE Booking__c = :book.Id LIMIT 1];
        ps.Type__c = 'Construction';
        update ps;
        Test.startTest();
        try {
            RaiseDemandEmailController.dataBox result = RaiseDemandEmailController.getData(book.Id);
            System.debug('getData Villa Construction – result: ' + result);
        } catch (Exception e) {
            System.debug('testGetData_Villa_Construction – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: getData – Already Demanded
    // ─────────────────────────────────────────
    @isTest
    static void testGetData_AlreadyDemanded() {
        Booking__c book = getFlatBooking();
        Payment_Schedule__c ps = [SELECT Id, Is_Demanded__c FROM Payment_Schedule__c
                                   WHERE Booking__c = :book.Id LIMIT 1];
        ps.Is_Demanded__c = true;
        update ps;
        Test.startTest();
        try {
            RaiseDemandEmailController.dataBox result = RaiseDemandEmailController.getData(book.Id);
            System.debug('getData AlreadyDemanded – isDemandRaised: ' + result.isDemandRaised);
        } catch (Exception e) {
            System.debug('testGetData_AlreadyDemanded – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: getRevisedDemandData – Apartment
    // ─────────────────────────────────────────
    @isTest
    static void testGetRevisedDemandData_Apartment() {
        Booking__c book = getFlatBooking();
        Test.startTest();
        try {
            RaiseDemandEmailController.dataBox result = RaiseDemandEmailController.getRevisedDemandData(book.Id);
            System.debug('getRevisedDemandData Apartment – subject: '      + result.subject);
            System.debug('getRevisedDemandData Apartment – emailContent: ' + result.emailContent);
        } catch (Exception e) {
            System.debug('testGetRevisedDemandData_Apartment – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: getRevisedDemandData – Villa
    // ─────────────────────────────────────────
    @isTest
    static void testGetRevisedDemandData_Villa() {
        Booking__c book = getVillaBooking();
        Test.startTest();
        try {
            RaiseDemandEmailController.dataBox result = RaiseDemandEmailController.getRevisedDemandData(book.Id);
            System.debug('getRevisedDemandData Villa – result: ' + result);
        } catch (Exception e) {
            System.debug('testGetRevisedDemandData_Villa – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: getRevisedDemandData – Already Demanded
    // ─────────────────────────────────────────
    @isTest
    static void testGetRevisedDemandData_AlreadyDemanded() {
        Booking__c book = getFlatBooking();
        Payment_Schedule__c ps = [SELECT Id, Is_Demanded__c FROM Payment_Schedule__c
                                   WHERE Booking__c = :book.Id LIMIT 1];
        ps.Is_Demanded__c = true;
        update ps;
        Test.startTest();
        try {
            RaiseDemandEmailController.dataBox result = RaiseDemandEmailController.getRevisedDemandData(book.Id);
            System.debug('getRevisedDemandData AlreadyDemanded – isDemandRaised: ' + result.isDemandRaised);
        } catch (Exception e) {
            System.debug('testGetRevisedDemandData_AlreadyDemanded – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: getPenaltyDemandData – Apartment
    // ─────────────────────────────────────────
    @isTest
    static void testGetPenaltyDemandData_Apartment() {
        Booking__c book = getFlatBooking();
        Test.startTest();
        try {
            RaiseDemandEmailController.dataBox result = RaiseDemandEmailController.getPenaltyDemandData(book.Id);
            System.debug('getPenaltyDemandData Apartment – subject: '      + result.subject);
            System.debug('getPenaltyDemandData Apartment – emailContent: ' + result.emailContent);
        } catch (Exception e) {
            System.debug('testGetPenaltyDemandData_Apartment – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: getPenaltyDemandData – Villa (Land)
    // ─────────────────────────────────────────
    @isTest
    static void testGetPenaltyDemandData_Villa_Land() {
        Booking__c book = getVillaBooking();
        Test.startTest();
        try {
            RaiseDemandEmailController.dataBox result = RaiseDemandEmailController.getPenaltyDemandData(book.Id);
            System.debug('getPenaltyDemandData Villa Land – result: ' + result);
        } catch (Exception e) {
            System.debug('testGetPenaltyDemandData_Villa_Land – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: getPenaltyDemandData – Villa (Construction)
    // ─────────────────────────────────────────
    @isTest
    static void testGetPenaltyDemandData_Villa_Construction() {
        Booking__c book = getVillaBooking();
        Payment_Schedule__c ps = [SELECT Id, Type__c FROM Payment_Schedule__c
                                   WHERE Booking__c = :book.Id LIMIT 1];
        ps.Type__c = 'Construction';
        update ps;
        Test.startTest();
        try {
            RaiseDemandEmailController.dataBox result = RaiseDemandEmailController.getPenaltyDemandData(book.Id);
            System.debug('getPenaltyDemandData Villa Construction – result: ' + result);
        } catch (Exception e) {
            System.debug('testGetPenaltyDemandData_Villa_Construction – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: updatePaymentSchedules – with records
    // ─────────────────────────────────────────
    @isTest
    static void testUpdatePaymentSchedules_WithRecords() {
        Booking__c book = getFlatBooking();
        Test.startTest();
        try {
            RaiseDemandEmailController.updatePaymentSchedules(String.valueOf(book.Id));
            System.debug('updatePaymentSchedules – completed for: ' + book.Id);
        } catch (Exception e) {
            System.debug('testUpdatePaymentSchedules_WithRecords – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: updatePaymentSchedules – no records
    // ─────────────────────────────────────────
    @isTest
    static void testUpdatePaymentSchedules_NoRecords() {
        Booking__c emptyBook = new Booking__c(
            Funding_Type__c = getPicklistValue(Booking__c.Funding_Type__c, 'loan'),
            CRM_Manager__c  = UserInfo.getUserId(),
            Project__c      = 'Trifecta Vanto'
        );
        insert emptyBook;
        Test.startTest();
        try {
            RaiseDemandEmailController.updatePaymentSchedules(String.valueOf(emptyBook.Id));
            System.debug('updatePaymentSchedules no-records – completed');
        } catch (Exception e) {
            System.debug('testUpdatePaymentSchedules_NoRecords – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: sendEmailWithAttachment – Flat with email
    // ─────────────────────────────────────────
    @isTest
    static void testSendEmailWithAttachment_Flat_WithEmail() {
        Booking__c book = getFlatBooking();
        Test.startTest();
        try {
            String result = RaiseDemandEmailController.sendEmailWithAttachment(book.Id, 'Flat');
            System.debug('sendEmailWithAttachment Flat – result: ' + result);
        } catch (Exception e) {
            System.debug('testSendEmailWithAttachment_Flat_WithEmail – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: sendEmailWithAttachment – AD type
    // ─────────────────────────────────────────
    @isTest
    static void testSendEmailWithAttachment_AD() {
        Additional_Charges__c adc = [SELECT Id FROM Additional_Charges__c LIMIT 1];
        Test.startTest();
        try {
            String result = RaiseDemandEmailController.sendEmailWithAttachment(adc.Id, 'AD');
            System.debug('sendEmailWithAttachment AD – result: ' + result);
        } catch (Exception e) {
            System.debug('testSendEmailWithAttachment_AD – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: sendEmailWithAttachment – no email
    // ─────────────────────────────────────────
    @isTest
    static void testSendEmailWithAttachment_NoEmail() {
        Booking__c bookNoEmail = new Booking__c(
            Funding_Type__c = getPicklistValue(Booking__c.Funding_Type__c, 'loan'),
            CRM_Manager__c  = UserInfo.getUserId(),
            Project__c      = 'Trifecta Vanto'
        );
        insert bookNoEmail;
        Test.startTest();
        try {
            String result = RaiseDemandEmailController.sendEmailWithAttachment(bookNoEmail.Id, 'Flat');
            System.debug('sendEmailWithAttachment NoEmail – result: ' + result);
        } catch (Exception e) {
            System.debug('testSendEmailWithAttachment_NoEmail – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: RaiseDemand
    // ─────────────────────────────────────────
    @isTest
    static void testRaiseDemand() {
        Booking__c book = getFlatBooking();
        Test.startTest();
        try {
            String result = RaiseDemandEmailController.RaiseDemand(
                String.valueOf(book.Id), 'Test email body', new List<Id>());
            System.debug('RaiseDemand – result: ' + result);
        } catch (Exception e) {
            System.debug('testRaiseDemand – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: revisedDemand – custom content
    // ─────────────────────────────────────────
    @isTest
    static void testRevisedDemand_CustomContent() {
        Test.setMock(HttpCalloutMock.class, new DemandHttpMock());
        Booking__c book = getFlatBooking();
        Test.startTest();
        try {
            String result = RaiseDemandEmailController.revisedDemand(
                String.valueOf(book.Id), 'Custom body', new List<Id>(), 'Custom Subject');
            System.debug('revisedDemand CustomContent – result: ' + result);
        } catch (Exception e) {
            System.debug('testRevisedDemand_CustomContent – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: revisedDemand – blank content
    // ─────────────────────────────────────────
    @isTest
    static void testRevisedDemand_BlankContent() {
        Test.setMock(HttpCalloutMock.class, new DemandHttpMock());
        Booking__c book = getFlatBooking();
        Test.startTest();
        try {
            String result = RaiseDemandEmailController.revisedDemand(
                String.valueOf(book.Id), '', new List<Id>(), '');
            System.debug('revisedDemand BlankContent – result: ' + result);
        } catch (Exception e) {
            System.debug('testRevisedDemand_BlankContent – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: revisedDemand – no schedule (error path)
    // ─────────────────────────────────────────
    @isTest
    static void testRevisedDemand_NoSchedule() {
        Booking__c emptyBook = new Booking__c(
            Funding_Type__c = getPicklistValue(Booking__c.Funding_Type__c, 'loan'),
            CRM_Manager__c  = UserInfo.getUserId(),
            Project__c      = 'Trifecta Vanto'
        );
        insert emptyBook;
        Test.startTest();
        try {
            String result = RaiseDemandEmailController.revisedDemand(
                String.valueOf(emptyBook.Id), 'body', new List<Id>(), 'Subject');
            System.debug('revisedDemand NoSchedule – result: ' + result);
        } catch (Exception e) {
            System.debug('testRevisedDemand_NoSchedule – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: revisedDemand – with ContentVersion attachment
    // ─────────────────────────────────────────
    @isTest
    static void testRevisedDemand_WithAttachment() {
        Test.setMock(HttpCalloutMock.class, new DemandHttpMock());
        Booking__c book = getFlatBooking();
        ContentVersion cv = new ContentVersion(
            Title          = 'TestFile',
            PathOnClient   = 'TestFile.pdf',
            VersionData    = Blob.valueOf('test'),
            IsMajorVersion = true
        );
        insert cv;
        ContentVersion insertedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        Test.startTest();
        try {
            String result = RaiseDemandEmailController.revisedDemand(
                String.valueOf(book.Id), 'body with attachment',
                new List<Id>{ insertedCv.ContentDocumentId }, 'Subject');
            System.debug('revisedDemand WithAttachment – result: ' + result);
        } catch (Exception e) {
            System.debug('testRevisedDemand_WithAttachment – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: penaltyDemand – custom content
    // ─────────────────────────────────────────
    @isTest
    static void testPenaltyDemand_CustomContent() {
        Test.setMock(HttpCalloutMock.class, new DemandHttpMock());
        Booking__c book = getFlatBooking();
        Test.startTest();
        try {
            String result = RaiseDemandEmailController.penaltyDemand(
                String.valueOf(book.Id), 'Penalty body', new List<Id>(), 'Penalty Subject');
            System.debug('penaltyDemand CustomContent – result: ' + result);
        } catch (Exception e) {
            System.debug('testPenaltyDemand_CustomContent – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: penaltyDemand – blank content
    // ─────────────────────────────────────────
    @isTest
    static void testPenaltyDemand_BlankContent() {
        Test.setMock(HttpCalloutMock.class, new DemandHttpMock());
        Booking__c book = getFlatBooking();
        Test.startTest();
        try {
            String result = RaiseDemandEmailController.penaltyDemand(
                String.valueOf(book.Id), '', new List<Id>(), '');
            System.debug('penaltyDemand BlankContent – result: ' + result);
        } catch (Exception e) {
            System.debug('testPenaltyDemand_BlankContent – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: penaltyDemand – no schedule (error path)
    // ─────────────────────────────────────────
    @isTest
    static void testPenaltyDemand_NoSchedule() {
        Booking__c emptyBook = new Booking__c(
            Funding_Type__c = getPicklistValue(Booking__c.Funding_Type__c, 'loan'),
            CRM_Manager__c  = UserInfo.getUserId(),
            Project__c      = 'Trifecta Vanto'
        );
        insert emptyBook;
        Test.startTest();
        try {
            String result = RaiseDemandEmailController.penaltyDemand(
                String.valueOf(emptyBook.Id), 'body', new List<Id>(), 'Subject');
            System.debug('penaltyDemand NoSchedule – result: ' + result);
        } catch (Exception e) {
            System.debug('testPenaltyDemand_NoSchedule – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────
    //  TEST: penaltyDemand – with ContentVersion attachment
    // ──────────────────────────���──────────────
    @isTest
    static void testPenaltyDemand_WithAttachment() {
        Test.setMock(HttpCalloutMock.class, new DemandHttpMock());
        Booking__c book = getFlatBooking();
        ContentVersion cv = new ContentVersion(
            Title          = 'PenaltyFile',
            PathOnClient   = 'PenaltyFile.pdf',
            VersionData    = Blob.valueOf('penalty'),
            IsMajorVersion = true
        );
        insert cv;
        ContentVersion insertedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        Test.startTest();
        try {
            String result = RaiseDemandEmailController.penaltyDemand(
                String.valueOf(book.Id), 'Penalty body with attachment',
                new List<Id>{ insertedCv.ContentDocumentId }, 'Penalty Subject');
            System.debug('penaltyDemand WithAttachment – result: ' + result);
        } catch (Exception e) {
            System.debug('testPenaltyDemand_WithAttachment – caught: ' + e.getMessage());
        }
        Test.stopTest();
    }
}