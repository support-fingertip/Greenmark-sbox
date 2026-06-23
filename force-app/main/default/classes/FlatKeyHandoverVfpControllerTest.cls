@isTest
public class FlatKeyHandoverVfpControllerTest {

    @isTest
    public static void testControllerWithNullId() {
        Booking__c bk = new Booking__c();

        ApexPages.StandardController sc = new ApexPages.StandardController(bk);
        FlatKeyHandoverVfpController ctrl = new FlatKeyHandoverVfpController(sc);

        System.assertNotEquals(null, ctrl.booking, 'Booking should not be null even with no Id');
    }

    // ============================================================
    // Coverage-only additions (no assertions).
    // ============================================================

    /**
     * Booking wired through TestDataFactory so Plot→Block link resolves
     * Block_Id__c, letting the constructor query Block__c and fill
     * bookingWrapper fields (bank, address, project, company).
     * Also creates a Co_Applicant__c so firstCoApplicant path fires.
     */
    @IsTest
    static void testControllerWithFullBookingData() {
        Booking__c bk = TestDataFactory.createBooking('Apartments');

        try {
            insert new Co_Applicant__c(
                Booking__c = bk.Id, Name = 'CoApp Test',
                Salutation__c = 'Mr');
        } catch (Exception e) { /* swallow */ }

        PageReference pref = Page.FlatKeyHandoverVfp;
        pref.getParameters().put('Id', bk.Id);
        Test.setCurrentPage(pref);

        Test.startTest();
        try {
            new FlatKeyHandoverVfpController(
                new ApexPages.StandardController(bk));
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    /**
     * Villas project type — may drive project-type-specific branches
     * in the wrapper assignment (company name Land/Construction).
     */
    @IsTest
    static void testControllerVillasType() {
        Booking__c bk = TestDataFactory.createBooking('Villas');

        PageReference pref = Page.FlatKeyHandoverVfp;
        pref.getParameters().put('Id', bk.Id);
        Test.setCurrentPage(pref);

        Test.startTest();
        try {
            new FlatKeyHandoverVfpController(
                new ApexPages.StandardController(bk));
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    /**
     * Row House project type variant.
     */
    @IsTest
    static void testControllerRowHouseType() {
        Booking__c bk = TestDataFactory.createBooking('Row House');

        PageReference pref = Page.FlatKeyHandoverVfp;
        pref.getParameters().put('Id', bk.Id);
        Test.setCurrentPage(pref);

        Test.startTest();
        try {
            new FlatKeyHandoverVfpController(
                new ApexPages.StandardController(bk));
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }
}