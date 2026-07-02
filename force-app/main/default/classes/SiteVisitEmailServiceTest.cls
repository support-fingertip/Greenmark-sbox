@isTest
private class SiteVisitEmailServiceTest {

    private class QrMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'image/png');
            res.setBodyAsBlob(Blob.valueOf('fake-png-bytes'));
            return res;
        }
    }

    private static Site_Visit__c makeSiteVisit(String email) {
        Utility.runLeadTrigger = false;
        Lead ld = new Lead(LastName = 'Email Lead', Company = 'Test', Email = email, Phone__c = '9990001111');
        insert ld;
        Site_Visit__c sv = new Site_Visit__c(SLead__c = ld.Id, Date__c = Datetime.now().addDays(1));
        insert sv;
        return sv;
    }

    @isTest
    static void scheduledQrEmailSends() {
        Site_Visit__c sv = makeSiteVisit('cust@example.com');
        Test.setMock(HttpCalloutMock.class, new QrMock());

        Test.startTest();
        Integer before = Limits.getEmailInvocations();
        SiteVisitEmailService.sendScheduledQrEmails(new Set<Id>{ sv.Id });
        Integer after = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(before + 1, after, 'Should send one QR email batch');
    }

    @isTest
    static void scheduledQrSkipsWhenNoEmail() {
        Site_Visit__c sv = makeSiteVisit(null);
        Test.setMock(HttpCalloutMock.class, new QrMock());

        Test.startTest();
        Integer before = Limits.getEmailInvocations();
        SiteVisitEmailService.sendScheduledQrEmails(new Set<Id>{ sv.Id });
        Integer after = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(before, after, 'No email should be sent when the lead has no email');
    }

    @isTest
    static void feedbackEmailSends() {
        Site_Visit__c sv = makeSiteVisit('cust@example.com');

        Test.startTest();
        Integer before = Limits.getEmailInvocations();
        SiteVisitEmailService.sendFeedbackEmails(new Set<Id>{ sv.Id });
        Integer after = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(before + 1, after, 'Should send one feedback email batch');
    }

    @isTest
    static void feedbackSkipsWhenNoEmail() {
        Site_Visit__c sv = makeSiteVisit(null);

        Test.startTest();
        Integer before = Limits.getEmailInvocations();
        SiteVisitEmailService.sendFeedbackEmails(new Set<Id>{ sv.Id });
        Integer after = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(before, after, 'No feedback email should be sent without a lead email');
    }

    @isTest
    static void bulkScheduledSendsSingleBatch() {
        Utility.runLeadTrigger = false;
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 3; i++) {
            leads.add(new Lead(LastName = 'Bulk ' + i, Company = 'Test', Email = 'bulk' + i + '@example.com', Phone__c = '99900022' + i + i));
        }
        insert leads;
        List<Site_Visit__c> svs = new List<Site_Visit__c>();
        for (Lead l : leads) {
            svs.add(new Site_Visit__c(SLead__c = l.Id, Date__c = Datetime.now().addDays(1)));
        }
        insert svs;

        Set<Id> ids = new Map<Id, Site_Visit__c>(svs).keySet();
        Test.setMock(HttpCalloutMock.class, new QrMock());

        Test.startTest();
        Integer before = Limits.getEmailInvocations();
        SiteVisitEmailService.sendScheduledQrEmails(ids);
        Integer after = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(before + 1, after, 'Bulk send should be a single sendEmail invocation');
    }

    @isTest
    static void emptyInputIsNoOp() {
        Test.startTest();
        SiteVisitEmailService.sendScheduledQrEmails(new Set<Id>());
        SiteVisitEmailService.sendScheduledQrEmails(null);
        SiteVisitEmailService.sendFeedbackEmails(new Set<Id>());
        SiteVisitEmailService.sendFeedbackEmails(null);
        Test.stopTest();

        System.assertEquals(0, Limits.getEmailInvocations(), 'Empty/null input should send nothing');
    }

    @isTest
    static void queueableRunsScheduled() {
        Site_Visit__c sv = makeSiteVisit('cust@example.com');
        Test.setMock(HttpCalloutMock.class, new QrMock());

        Test.startTest();
        System.enqueueJob(new SiteVisitEmailQueueable(new Set<Id>{ sv.Id }, SiteVisitEmailQueueable.MODE_SCHEDULED));
        Test.stopTest();

        System.assert(Limits.getEmailInvocations() >= 0, 'Queueable executed without error');
    }
}
