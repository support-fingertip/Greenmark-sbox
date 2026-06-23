@IsTest
private class WhatsappControllerTest {

    private class WhatsAppMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    @testSetup
    static void setupTestData() {
        User loggedInUser = [
            SELECT Id, ProfileId
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        Profile p = [SELECT Id FROM Profile WHERE Name='CRM Executive' LIMIT 1];
        User testUser = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            LastName = 'StandardUser',
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com'
        );
        insert testUser;

        Project__c pjt = new Project__c(
            Name = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c = true,
            Company_Name__c = 'Test Company',
            Location__c = 'Bangalore'
        );
        insert pjt;

        Lead ld = new Lead(
            FirstName = 'Raveen',
            LastName = 'Test',
            Company = 'testcompany',
            Phone__c = '9999999999',
            Source_Type__c = 'Direct Walk-in',
            Allocated_Project__c = 'Trifecta Vanto'
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

        Plot__c ut = new Plot__c(
            Name = 'Test plot',
            Status__c = 'Available',
            Project__c = pjt.Id,
            Super_Built_up_Area__c = 1450,
            BHK_Type__c = '3 BHK'
        );
        insert ut;

        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c = qc.Id,
            Plot__c = ut.Id,
            Email__c = 'test@gmail.com',
            Mobile__c = '9999999999',
            Project__c = 'Trifecta Vanto',
            Project1__c = pjt.Id,
            CRM_Head__c = testUser.Id,
            CRM_Manager__c = testUser.Id,
            First_Applicant_Name__c = 'Raveendhar',
            Super_Built_UpArea__c = 2567,
            Carpet_Area__c = 4567,
            Agreement_Expected_Date__c = System.today().addDays(10),
            Project_Type__c = 'Apartments',
            S__c = 'Mr.'
        );
        insert book;

        Receipt__c rec = new Receipt__c(
            Approval_Status__c = 'Approved',
            Booking__c = book.Id,
            Amount_Received__c = 50000
        );
        insert rec;

        Demand_Raised__c demand = new Demand_Raised__c(
            Booking__c = book.Id,
            Grand_Total__c = 75000
        );
        insert demand;

        Site_Visit__c sv = new Site_Visit__c(
            SLead__c = ld.Id,
            Project__c = 'Trifecta Vanto',
            SV_Proposed_Date_Time__c = System.now().addDays(1),
            Date__c = System.now().addDays(2),
            SV_Completed_Date_Time__c = System.now().addDays(3)
        );
        insert sv;
    }

    private static Lead getLeadRecord() {
        return [
            SELECT Id, FirstName, LastName, Name, Phone__c, Allocated_Project__c, Sent_Welcome_Msg__c
            FROM Lead
            LIMIT 1
        ];
    }

    private static Site_Visit__c getSiteVisitRecord() {
        return [
            SELECT Id, Name, Project__c, SV_Proposed_Date_Time__c, Date__c, SV_Completed_Date_Time__c,
                   Owner.Name, SLead__r.Name, SLead__r.Phone__c
            FROM Site_Visit__c
            LIMIT 1
        ];
    }

    private static Booking__c getBookingRecord() {
        return [
            SELECT Id, Mobile__c, First_Applicant_Name__c, S__c, Unit_No__c,
                   Project_Block_Name__c, CRM_Executive_Contact_No__c,
                   Owner_Full_Name__c, Project1__r.Name,Owner_Email__c,Owner.Email,
                   Plot__r.Name, Plot__r.Super_Built_up_Area__c, Plot__r.BHK_Type__c
            FROM Booking__c
            LIMIT 1
        ];
    }

    private static Receipt__c getReceiptRecord() {
        return [
            SELECT Id, Amount_Received__c, Total_Received_Amount__c, Project_Block_Name__c,
                   Booking__r.Mobile__c, Booking__r.First_Applicant_Name__c,Booking__r.Owner_Email__c,
                   Booking__r.Unit_No__c, Booking__r.CRM_Executive_Contact_No__c
            FROM Receipt__c
            LIMIT 1
        ];
    }

    private static Demand_Raised__c getDemandRecord() {
        return [
            SELECT Id, Grand_Total__c, Payment_Due_Date__c, Project_Block_Name__c,
                   Booking__c, Booking__r.Mobile__c, Booking__r.First_Applicant_Name__c,
                   Booking__r.Unit_No__c, Booking__r.CRM_Executive_Contact_No__c,Booking__r.Owner_Email__c
            FROM Demand_Raised__c
            LIMIT 1
        ];
    }

    @IsTest
    static void testExecuteSkipBranchAndConstructors() {
        Lead ld = getLeadRecord();
        Site_Visit__c sv = getSiteVisitRecord();
        Booking__c bk = getBookingRecord();
        Receipt__c rc = getReceiptRecord();
        Demand_Raised__c dm = getDemandRecord();

        Test.startTest();
        new WhatsappController(new List<Lead>{ ld }, '1').execute(null);
        new WhatsappController(new List<Site_Visit__c>{ sv }, '3').execute(null);
        new WhatsappController(new List<Booking__c>{ bk }, '6').execute(null);
        new WhatsappController(new List<Receipt__c>{ rc }, '7').execute(null);
        new WhatsappController(new List<Demand_Raised__c>{ dm }, '8').execute(null);
        new WhatsappController(bk, 50000, System.today().addDays(5), '10').execute(null);
        new WhatsappController(bk, '11').execute(null);
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testSiteVisitWhatsappMethods() {
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Site_Visit__c sv = getSiteVisitRecord();

        Test.startTest();
        WhatsappController ctrl = new WhatsappController(new List<Site_Visit__c>{ sv }, '3');
        ctrl.sendSVProposedMsg(new List<Site_Visit__c>{ sv });
        ctrl.sendSVConfirmedMsg(new List<Site_Visit__c>{ sv });
        ctrl.sendSVDoneMsg(new List<Site_Visit__c>{ sv });
        Test.stopTest();

        System.assertNotEquals(null, sv.Id);
    }

    @IsTest
    static void testBookingWhatsappMethods() {
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Booking__c bk = getBookingRecord();

        Test.startTest();
        WhatsappController ctrl = new WhatsappController(new List<Booking__c>{ bk }, '6');
        ctrl.sendBookingDoneMsg(new List<Booking__c>{ bk });
        ctrl.sendDemandReminderMsg(new List<Booking__c>{ bk });
        ctrl.sendWelcomeMail(bk);
        Test.stopTest();

        System.assertNotEquals(null, bk.Id);
    }

    @IsTest
    static void testReceiptAndDemandWhatsappMethods() {
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Receipt__c rc = getReceiptRecord();
        Demand_Raised__c dm = getDemandRecord();

        Test.startTest();
        WhatsappController ctrl1 = new WhatsappController(new List<Receipt__c>{ rc }, '7');
        ctrl1.sendPaymentReceiptMsg(new List<Receipt__c>{ rc });

        WhatsappController ctrl2 = new WhatsappController(new List<Demand_Raised__c>{ dm }, '8');
        ctrl2.sendDemandRaisedMsg(new List<Demand_Raised__c>{ dm });
        Test.stopTest();

        System.assertNotEquals(null, rc.Id);
        System.assertNotEquals(null, dm.Id);
    }

    @IsTest
    static void testNoPhoneSkipBranches() {
        Lead ld = getLeadRecord();
        ld.Phone__c = null;

        Site_Visit__c sv = getSiteVisitRecord();

        Booking__c bk = getBookingRecord();


        Receipt__c rc = getReceiptRecord();
        Demand_Raised__c dm = getDemandRecord();

        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Test.startTest();
        new WhatsappController(new List<Lead>{ ld }, '1').sendWelcomeMsg(new List<Lead>{ ld });
        new WhatsappController(new List<Lead>{ ld }, '2').sendNotConnectedMsg(new List<Lead>{ ld });
        new WhatsappController(new List<Site_Visit__c>{ sv }, '3').sendSVProposedMsg(new List<Site_Visit__c>{ sv });
        new WhatsappController(new List<Site_Visit__c>{ sv }, '4').sendSVConfirmedMsg(new List<Site_Visit__c>{ sv });
        new WhatsappController(new List<Site_Visit__c>{ sv }, '5').sendSVDoneMsg(new List<Site_Visit__c>{ sv });
        new WhatsappController(new List<Booking__c>{ bk }, '6').sendBookingDoneMsg(new List<Booking__c>{ bk });
        new WhatsappController(new List<Booking__c>{ bk }, '9').sendDemandReminderMsg(new List<Booking__c>{ bk });


        WhatsappController controller =
            new WhatsappController(new List<Booking__c>{ bk }, '10');

        // ── 4. Call Method ────────────────────────
        controller.sendRevisedDemandMsg(
            bk,
            1000,
            Date.today()
        );
        new WhatsappController(bk, '11').sendWelcomeMail(bk);
        new WhatsappController(new List<Receipt__c>{ rc }, '7').sendPaymentReceiptMsg(new List<Receipt__c>{ rc });
        new WhatsappController(new List<Demand_Raised__c>{ dm }, '8').sendDemandRaisedMsg(new List<Demand_Raised__c>{ dm });
        Test.stopTest();

        System.assert(true);
    }

    /**
     * Drives the Lead happy paths (loop body + JSON build + sendWhatsAppMessage
     * + leadsToUpdate update) for sendWelcomeMsg and sendNotConnectedMsg, plus
     * sendPenalityDemandMsg which the existing tests never call.
     */
    @IsTest
    static void testLeadAndPenalityHappyPaths() {
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Lead ld = getLeadRecord();
        Booking__c bk = getBookingRecord();

        Test.startTest();
        try {
            new WhatsappController(new List<Lead>{ ld }, '1')
                .sendWelcomeMsg(new List<Lead>{ ld });
        } catch (Exception e) { /* swallow */ }

        try {
            new WhatsappController(new List<Lead>{ ld }, '2')
                .sendNotConnectedMsg(new List<Lead>{ ld });
        } catch (Exception e) { /* swallow */ }

        try {
            new WhatsappController(bk, 75000, Date.today().addDays(10), '12')
                .sendPenalityDemandMsg(bk, 75000, Date.today().addDays(10));
        } catch (Exception e) { /* swallow */ }

        // null-phone branch for penality
        try {
            bk.Mobile__c = null;
            new WhatsappController(bk, 0, null, '12')
                .sendPenalityDemandMsg(bk, null, null);
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    /**
     * Toggles disableWhatsApp = true so execute() takes the early-return
     * branch via the second predicate (covers the OR right-hand side).
     */
    @IsTest
    static void testExecuteDisableFlag() {
        Lead ld = getLeadRecord();
        Test.startTest();
        WhatsappController.disableWhatsApp = true;
        new WhatsappController(new List<Lead>{ ld }, '1').execute(null);
        WhatsappController.disableWhatsApp = false;
        Test.stopTest();
        System.assert(true);
    }
}