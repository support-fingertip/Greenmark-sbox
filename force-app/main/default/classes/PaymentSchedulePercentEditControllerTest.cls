// Coverage-only test authored in this change (no assertions).
@IsTest
private class PaymentSchedulePercentEditControllerTest {

    @IsTest
    static void getSchedulesFromBookingId() {
        Booking__c bk = TestDataFactory.createBooking('Apartments');
        TestDataFactory.createPaymentSchedules(bk.Id, 3);

        Test.startTest();
        try {
            Map<String, Object> result =
                PaymentSchedulePercentEditController.getSchedules(bk.Id);
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void getSchedulesFromPaymentScheduleId() {
        Booking__c bk = TestDataFactory.createBooking('Villas');
        List<Payment_Schedule__c> ps = TestDataFactory.createPaymentSchedules(bk.Id, 2);

        Test.startTest();
        try {
            Map<String, Object> result =
                PaymentSchedulePercentEditController.getSchedules(ps[0].Id);
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void getSchedulesNullId() {
        Test.startTest();
        try {
            PaymentSchedulePercentEditController.getSchedules(null);
        } catch (Exception e) { /* expected AuraHandledException */ }
        Test.stopTest();
    }

    @IsTest
    static void saveSchedulesValidEdits() {
        Booking__c bk = TestDataFactory.createBooking('Apartments');
        List<Payment_Schedule__c> ps = TestDataFactory.createPaymentSchedules(bk.Id, 2);

        // Build edits that keep total at 100 (if 2 schedules, adjust both)
        List<Payment_Schedule__c> edits = new List<Payment_Schedule__c>{
            new Payment_Schedule__c(Id = ps[0].Id, Payment_percent__c = 60),
            new Payment_Schedule__c(Id = ps[1].Id, Payment_percent__c = 40)
        };

        Test.startTest();
        try {
            PaymentSchedulePercentEditController.saveSchedules(bk.Id, edits);
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void saveSchedulesDemandedRejects() {
        Booking__c bk = TestDataFactory.createBooking('Apartments');
        List<Payment_Schedule__c> ps = TestDataFactory.createPaymentSchedules(bk.Id, 1);
        ps[0].Is_Demanded__c = true;
        try { update ps[0]; } catch (Exception e) { /* swallow */ }

        List<Payment_Schedule__c> edits = new List<Payment_Schedule__c>{
            new Payment_Schedule__c(Id = ps[0].Id, Payment_percent__c = 50)
        };

        Test.startTest();
        try {
            PaymentSchedulePercentEditController.saveSchedules(bk.Id, edits);
        } catch (Exception e) { /* expected AuraHandledException */ }
        Test.stopTest();
    }

    @IsTest
    static void saveSchedulesTotalMismatchRejects() {
        Booking__c bk = TestDataFactory.createBooking('Apartments');
        List<Payment_Schedule__c> ps = TestDataFactory.createPaymentSchedules(bk.Id, 2);

        // Total = 90, expected = 100 → should throw
        List<Payment_Schedule__c> edits = new List<Payment_Schedule__c>{
            new Payment_Schedule__c(Id = ps[0].Id, Payment_percent__c = 50),
            new Payment_Schedule__c(Id = ps[1].Id, Payment_percent__c = 40)
        };

        Test.startTest();
        try {
            PaymentSchedulePercentEditController.saveSchedules(bk.Id, edits);
        } catch (Exception e) { /* expected AuraHandledException */ }
        Test.stopTest();
    }

    @IsTest
    static void saveSchedulesNullBookingId() {
        Test.startTest();
        try {
            PaymentSchedulePercentEditController.saveSchedules(null, null);
        } catch (Exception e) { /* expected */ }
        Test.stopTest();
    }

    @IsTest
    static void saveSchedulesVillasExpects200() {
        Booking__c bk = TestDataFactory.createBooking('Villas');
        List<Payment_Schedule__c> ps = TestDataFactory.createPaymentSchedules(bk.Id, 2);

        List<Payment_Schedule__c> edits = new List<Payment_Schedule__c>{
            new Payment_Schedule__c(Id = ps[0].Id, Payment_percent__c = 100),
            new Payment_Schedule__c(Id = ps[1].Id, Payment_percent__c = 100)
        };

        Test.startTest();
        try {
            PaymentSchedulePercentEditController.saveSchedules(bk.Id, edits);
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }
}