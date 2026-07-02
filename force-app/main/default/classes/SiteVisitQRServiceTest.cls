@isTest
private class SiteVisitQRServiceTest {

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
        Lead ld = new Lead(LastName = 'QR Lead', Company = 'Test', Email = email, Phone__c = '9990002222');
        insert ld;
        Site_Visit__c sv = new Site_Visit__c(SLead__c = ld.Id, Date__c = Datetime.now().addDays(1));
        insert sv;
        return sv;
    }

    @isTest
    static void qrImageUrlBuilt() {
        Site_Visit__c sv = makeSiteVisit('cust@example.com');
        Test.startTest();
        String url = SiteVisitQRService.getQrImageUrl(sv.Id);
        Test.stopTest();
        System.assert(url.startsWith('https://api.qrserver.com/'), 'Should use the QR service');
        System.assert(url.contains('data='), 'Should encode the redirect URL as data');
    }

    @isTest
    static void sendEmailSucceeds() {
        Site_Visit__c sv = makeSiteVisit('cust@example.com');
        Test.setMock(HttpCalloutMock.class, new QrMock());

        Test.startTest();
        String sentTo = SiteVisitQRService.sendQrCodeEmail(sv.Id);
        Test.stopTest();

        System.assertEquals('cust@example.com', sentTo, 'Should email the lead email');
    }

    @isTest
    static void sendEmailFailsWithoutEmail() {
        Site_Visit__c sv = makeSiteVisit(null);
        Boolean threw = false;
        Test.startTest();
        try {
            SiteVisitQRService.sendQrCodeEmail(sv.Id);
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();
        System.assert(threw, 'Missing lead email should throw');
    }
}