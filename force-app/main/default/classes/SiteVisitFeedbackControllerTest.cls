@isTest
private class SiteVisitFeedbackControllerTest {

    private static Site_Visit__c makeSiteVisit() {
        Utility.runLeadTrigger = false;
        Lead ld = new Lead(LastName = 'Feedback Lead', Company = 'Test', Email = 'fb@example.com', Phone__c = '9990003333');
        insert ld;
        Site_Visit__c sv = new Site_Visit__c(SLead__c = ld.Id, Date__c = Datetime.now().addDays(1));
        insert sv;
        return sv;
    }

    @isTest
    static void validSubmitSavesRatingAndFeedback() {
        Site_Visit__c sv = makeSiteVisit();
        Test.setCurrentPage(Page.SiteVisitFeedback);
        ApexPages.currentPage().getParameters().put('id', sv.Id);

        Test.startTest();
        SiteVisitFeedbackController ctrl = new SiteVisitFeedbackController();
        System.assert(ctrl.recordFound, 'Record should load');
        ctrl.siteVisit.Customer_Rating__c = 4;
        ctrl.siteVisit.Customer_Feedback__c = 'Great experience';
        ctrl.submit();
        Test.stopTest();

        System.assert(ctrl.submitted, 'Submit should succeed');
        Site_Visit__c saved = [SELECT Customer_Rating__c, Customer_Feedback__c FROM Site_Visit__c WHERE Id = :sv.Id];
        System.assertEquals(4, saved.Customer_Rating__c, 'Rating should be saved');
        System.assertEquals('Great experience', saved.Customer_Feedback__c, 'Feedback should be saved');
    }

    @isTest
    static void missingIdShowsError() {
        Test.setCurrentPage(Page.SiteVisitFeedback);

        Test.startTest();
        SiteVisitFeedbackController ctrl = new SiteVisitFeedbackController();
        ctrl.submit();
        Test.stopTest();

        System.assert(!ctrl.recordFound, 'No record should load without an id');
        System.assert(!ctrl.submitted, 'Submit should not succeed');
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'An error message should be shown');
    }

    @isTest
    static void invalidIdShowsError() {
        Test.setCurrentPage(Page.SiteVisitFeedback);
        // A syntactically valid Id of the wrong SObject type (Account key prefix).
        ApexPages.currentPage().getParameters().put('id', '001000000000000AAA');

        Test.startTest();
        SiteVisitFeedbackController ctrl = new SiteVisitFeedbackController();
        Test.stopTest();

        System.assert(!ctrl.recordFound, 'Wrong object type should not load');
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'An error message should be shown');
    }

    @isTest
    static void outOfRangeRatingRejected() {
        Site_Visit__c sv = makeSiteVisit();
        Test.setCurrentPage(Page.SiteVisitFeedback);
        ApexPages.currentPage().getParameters().put('id', sv.Id);

        Test.startTest();
        SiteVisitFeedbackController ctrl = new SiteVisitFeedbackController();
        ctrl.siteVisit.Customer_Rating__c = 6; // out of 1-5
        ctrl.submit();
        System.assert(!ctrl.submitted, 'Rating above 5 should be rejected');

        ctrl.siteVisit.Customer_Rating__c = null; // missing
        ctrl.submit();
        Test.stopTest();

        System.assert(!ctrl.submitted, 'Missing rating should be rejected');
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'An error message should be shown');
    }
}

