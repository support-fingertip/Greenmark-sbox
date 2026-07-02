@isTest
private class SiteVisitQRControllerTest {

    private static Site_Visit__c makeSiteVisit(Id ownerId) {
        Utility.runLeadTrigger = false;
        Lead ld = new Lead(LastName = 'QR Lead', Company = 'Test', Email = 'qrlead@example.com', Phone__c = '9990001111');
        insert ld;

        Site_Visit__c sv = new Site_Visit__c(SLead__c = ld.Id, Date__c = Datetime.now().addDays(1));
        if (ownerId != null) {
            sv.OwnerId = ownerId;
        }
        insert sv;
        return sv;
    }

    @isTest
    static void authorizedOwnerRedirects() {
        Site_Visit__c sv = makeSiteVisit(UserInfo.getUserId());

        Test.startTest();
        PageReference pg = Page.SiteVisitQR;
        pg.getParameters().put('id', sv.Id);
        Test.setCurrentPage(pg);
        SiteVisitQRController ctrl = new SiteVisitQRController();
        PageReference result = ctrl.checkAccess();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Owner should be redirected to the record');
        System.assert(result.getUrl().contains(sv.Id), 'Redirect should target the Site Visit');
    }

    @isTest
    static void unauthorizedShowsProhibited() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User other = new User(
            LastName = 'Other', Alias = 'oth',
            Email = 'other@example.com',
            Username = 'qrother' + DateTime.now().getTime() + '@example.com.invalid',
            ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'
        );
        insert other;

        Site_Visit__c sv = makeSiteVisit(other.Id);

        Test.startTest();
        PageReference pg = Page.SiteVisitQR;
        pg.getParameters().put('id', sv.Id);
        Test.setCurrentPage(pg);
        SiteVisitQRController ctrl = new SiteVisitQRController();
        PageReference result = ctrl.checkAccess();
        Test.stopTest();

        System.assertEquals(null, result, 'Non-owner/non-GRE must not be redirected');
        System.assertEquals('Access to the record is prohibited.', ctrl.message);
    }

    @isTest
    static void missingIdShowsError() {
        Test.startTest();
        PageReference pg = Page.SiteVisitQR;
        Test.setCurrentPage(pg);
        SiteVisitQRController ctrl = new SiteVisitQRController();
        PageReference result = ctrl.checkAccess();
        Test.stopTest();

        System.assertEquals(null, result);
        System.assert(ctrl.message.contains('Invalid'), 'Missing id should produce an error message');
    }
}