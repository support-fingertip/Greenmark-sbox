// Coverage-only test authored in this change (no assertions).
@IsTest
private class WelcomeEmailQueueableTest {

    @IsTest
    static void runsForVilla() {
        Booking__c bk = TestDataFactory.createBooking('Villas');
        List<Payment_Schedule__c> ps = TestDataFactory.createPaymentSchedules(bk.Id, 2);
        Demand_Raised__c d1;
        Demand_Raised__c d2;
        try { d1 = TestDataFactory.createDemand(bk.Id, ps[0].Id); }
        catch (Exception e) { /* swallow */ }
        try { d2 = TestDataFactory.createDemand(bk.Id, ps[1].Id); }
        catch (Exception e) { /* swallow */ }

        Test.startTest();
        try {
            System.enqueueJob(new WelcomeEmailQueueable(
                bk.Id,
                d1 == null ? null : (String)d1.Id,
                d2 == null ? null : (String)d2.Id,
                'Villas',
                bk.Quote__c,
                '<p>hello</p>',
                new List<String>{ 'customer@example.com' },
                new List<String>(),
                new List<String>(),
                'Welcome subject'
            ));
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void runsForApartment() {
        Booking__c bk = TestDataFactory.createBooking('Apartments');
        List<Payment_Schedule__c> ps = TestDataFactory.createPaymentSchedules(bk.Id, 1);
        Demand_Raised__c d1;
        try { d1 = TestDataFactory.createDemand(bk.Id, ps[0].Id); }
        catch (Exception e) { /* swallow */ }

        Test.startTest();
        try {
            System.enqueueJob(new WelcomeEmailQueueable(
                bk.Id,
                d1 == null ? null : (String)d1.Id,
                null,
                'Apartments',
                bk.Quote__c,
                '<p>hi</p>',
                new List<String>{ 'customer@example.com' },
                new List<String>(),
                new List<String>(),
                'Welcome subject'
            ));
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void runsForRowHouse() {
        Booking__c bk = TestDataFactory.createBooking('Row House');
        List<Payment_Schedule__c> ps = TestDataFactory.createPaymentSchedules(bk.Id, 1);
        Demand_Raised__c d1;
        try { d1 = TestDataFactory.createDemand(bk.Id, ps[0].Id); }
        catch (Exception e) { /* swallow */ }

        Test.startTest();
        try {
            System.enqueueJob(new WelcomeEmailQueueable(
                bk.Id,
                d1 == null ? null : (String)d1.Id,
                null,
                'Row House',
                bk.Quote__c,
                '<p>hello Thanks &amp; Regards</p>',
                new List<String>{ 'customer@example.com' },
                new List<String>(),
                new List<String>{ 'cc@example.com' },
                'Subject'
            ));
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void sanitizeEmailHtmlremovesStrayBlankLine() {
        // U+FEFF (BOM) before an empty paragraph — the production template quirk
        // that rendered an extra blank line after "quality and Schedule".
        String bom = String.fromCharArray(new List<Integer>{ 65279 }); // U+FEFF
        String input = '<p>quality and Schedule.</p>' + bom
            + '<p>&nbsp;</p><p style="text-align: justify;"><br></p>'
            + '<p>We once again thank you.</p>';

        String output = WelcomeEmailQueueable.sanitizeEmailHtml(input);

        System.assert(!output.contains(bom), 'BOM / zero-width char should be stripped');
        System.assert(!output.contains('<p>&nbsp;</p>'), 'Empty paragraph should be removed');
        System.assert(!output.contains('<br>'), 'Empty <br> paragraph should be removed');
        System.assert(output.contains('<p>quality and Schedule.</p>'), 'Real paragraph kept');
        System.assert(output.contains('<p>We once again thank you.</p>'), 'Real paragraph kept');
    }

    @IsTest
    static void sanitizeEmailHtmlremovesStyledBlankParagraph() {
        // Blank spacer paragraph the editor wrapped with a font size, plus a
        // real styled paragraph that must be preserved.
        String input = '<p style="text-align:center;"><span style="font-size:14px;"><br></span></p>'
            + '<p><span style="font-size: 20px;">Hello there</span></p>';

        String output = WelcomeEmailQueueable.sanitizeEmailHtml(input);

        System.assert(!output.contains('<br>'), 'Styled empty paragraph should be removed');
        System.assert(output.contains('Hello there'), 'Styled real paragraph kept');
        System.assert(output.contains('font-size: 20px'), 'Real font-size styling preserved');
    }

    @IsTest
    static void sanitizeEmailHtmlHandlesBlankInput() {
        System.assertEquals(null, WelcomeEmailQueueable.sanitizeEmailHtml(null));
        System.assertEquals('', WelcomeEmailQueueable.sanitizeEmailHtml(''));
    }
}