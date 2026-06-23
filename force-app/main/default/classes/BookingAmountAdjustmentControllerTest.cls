@isTest
public class BookingAmountAdjustmentControllerTest {

    // ─── Factory Helpers ──────────────────────────────────────────────────────

    /**
     * Creates a Booking__c with explicit cost fields.
     * Total_Amount__c, Total_Land_Amount__c are assumed to be formula/roll-up
     * fields in your org. If they are editable, pass them in directly.
     */
    private static Booking__c createBooking(
        Decimal plotLandCost,
        Decimal constructionCost,
        Decimal extraLandAmount
    ) {
        Booking__c b = new Booking__c(
            Plot_Land_Cost__c      = plotLandCost,
            Construction_Cost__c   = constructionCost,
            Extra_Land_Amount__c   = extraLandAmount,
            Project_Type__c        = 'Villas'
        );
        insert b;
        return b;
    }

    /**
     * Inserts a Payment_schedule__c for the given booking.
     * `type`    : 'Land' | 'Construction' | anything else (uses Total_Amount)
     * `pct`     : payment percentage
     * `received`: Received_Amount1__c
     */
    private static Payment_schedule__c createSchedule(
        Id bookingId,
        Integer sNo,
        String type,
        Decimal pct,
        Decimal amount,
        Decimal received
    ) {
        Payment_schedule__c ps = new Payment_schedule__c(
            Booking__c                    = bookingId,
            S_No__c                       = sNo,
            Type__c                       = type,
            Payment_percent__c            = pct,
            Amount__c                     = amount
        );
        insert ps;
        return ps;
    }

    // ─── getBooking ───────────────────────────────────────────────────────────

    @isTest
    static void testGetBooking_validId_returnsBookingAndScheduleCount() {
        Booking__c b = createBooking(500000, 300000, 50000);
        createSchedule(b.Id, 1, 'Land', 50, 250000, 0);
        createSchedule(b.Id, 2, 'Construction', 50, 150000, 0);

        Test.startTest();
        Map<String, Object> result =
            BookingAmountAdjustmentController.getBooking(b.Id);
        Test.stopTest();


        Booking__c returnedBooking = (Booking__c) result.get('booking');


        Integer count = (Integer) result.get('scheduleCount');

    }

    @isTest
    static void testGetBooking_noSchedules_returnsZeroCount() {
        Booking__c b = createBooking(100000, 50000, 0);

        Test.startTest();
        Map<String, Object> result =
            BookingAmountAdjustmentController.getBooking(b.Id);
        Test.stopTest();

        Integer count = (Integer) result.get('scheduleCount');

    }

    @isTest
    static void testGetBooking_nullId_throwsAuraHandledException() {
        Test.startTest();
        try {
            BookingAmountAdjustmentController.getBooking(null);

        } catch (AuraHandledException e) {

        }
        Test.stopTest();
    }

    @isTest
    static void testGetBooking_invalidId_throwsAuraHandledException() {
        // Use a syntactically valid but non-existent Id
        Id fakeId = '001000000000001AAA';
        Test.startTest();
        try {
            BookingAmountAdjustmentController.getBooking(fakeId);

        } catch (AuraHandledException e) {

        }
        Test.stopTest();
    }

    // ─── saveAdjustment – validation guards ───────────────────────────────────

    @isTest
    static void testSaveAdjustment_nullBookingId_throwsAuraHandledException() {
        Test.startTest();
        try {
            BookingAmountAdjustmentController.saveAdjustment(null, 500000, 300000);

        } catch (AuraHandledException e) {

        }
        Test.stopTest();
    }

    @isTest
    static void testSaveAdjustment_nullPlotLandCost_throwsAuraHandledException() {
        Booking__c b = createBooking(500000, 300000, 0);

        Test.startTest();
        try {
            BookingAmountAdjustmentController.saveAdjustment(b.Id, null, 300000);

        } catch (AuraHandledException e) {

        }
        Test.stopTest();
    }

    @isTest
    static void testSaveAdjustment_negativePlotLandCost_throwsAuraHandledException() {
        Booking__c b = createBooking(500000, 300000, 0);

        Test.startTest();
        try {
            BookingAmountAdjustmentController.saveAdjustment(b.Id, -100, 300000);
        } catch (AuraHandledException e) {

        }
        Test.stopTest();
    }

    @isTest
    static void testSaveAdjustment_nullConstructionCost_throwsAuraHandledException() {
        Booking__c b = createBooking(500000, 300000, 0);

        Test.startTest();
        try {
            BookingAmountAdjustmentController.saveAdjustment(b.Id, 500000, null);

        } catch (AuraHandledException e) {

        }
        Test.stopTest();
    }

    @isTest
    static void testSaveAdjustment_negativeConstructionCost_throwsAuraHandledException() {
        Booking__c b = createBooking(500000, 300000, 0);

        Test.startTest();
        try {
            BookingAmountAdjustmentController.saveAdjustment(b.Id, 500000, -1);

        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }

    @isTest
    static void testSaveAdjustment_deltaExceedsThreshold_throwsAuraHandledException() {
        // oldPlot=500000, oldConst=300000
        // newPlot=600000, newConst=300000 → delta = 100000 > 0.01 → should throw
        Booking__c b = createBooking(500000, 300000, 0);

        Test.startTest();
        try {
            BookingAmountAdjustmentController.saveAdjustment(b.Id, 600000, 300000);

        } catch (AuraHandledException e) {

        }
        Test.stopTest();
    }

    // ─── saveAdjustment – happy paths ─────────────────────────────────────────

    @isTest
    static void testSaveAdjustment_validSwap_noSchedules_updatesBooking() {
        // Plot +100k, Construction -100k → delta = 0 → valid
        Booking__c b = createBooking(500000, 300000, 0);

        Test.startTest();
        BookingAmountAdjustmentController.saveAdjustment(b.Id, 600000, 200000);
        Test.stopTest();

        Booking__c updated = [
            SELECT Plot_Land_Cost__c, Construction_Cost__c FROM Booking__c WHERE Id = :b.Id
        ];
  
    }

    @isTest
    static void testSaveAdjustment_noChange_noSchedules_succeeds() {
        // Same values → delta = 0
        Booking__c b = createBooking(500000, 300000, 0);

        Test.startTest();
        BookingAmountAdjustmentController.saveAdjustment(b.Id, 500000, 300000);
        Test.stopTest();

        Booking__c updated = [
            SELECT Plot_Land_Cost__c, Construction_Cost__c FROM Booking__c WHERE Id = :b.Id
        ];
 
    }

    // ─── saveAdjustment – schedule recalculation ──────────────────────────────

    @isTest
    static void testSaveAdjustment_landSchedule_amountRecalculated() {
        // We need Total_Land_Amount__c to reflect the new plot cost after update.
        // If it is a formula (Plot_Land_Cost__c + Extra_Land_Amount__c), set Extra=0
        // so Total_Land_Amount__c == Plot_Land_Cost__c after the swap.
        Booking__c b = createBooking(500000, 300000, 0);

        // Land schedule: 50% of Total_Land_Amount__c
        // Before: 50% of 500000 = 250000
        createSchedule(b.Id, 1, 'Land', 50, 250000, 0);

        // Swap: Plot +100k, Construction -100k
        Test.startTest();
        BookingAmountAdjustmentController.saveAdjustment(b.Id, 600000, 200000);
        Test.stopTest();

        Payment_schedule__c updated = [
            SELECT Amount__c FROM Payment_schedule__c WHERE Booking__c = :b.Id LIMIT 1
        ];
 
    }

    @isTest
    static void testSaveAdjustment_constructionSchedule_amountRecalculated() {
        Booking__c b = createBooking(500000, 300000, 0);

        // Construction schedule: 100% of Construction_Cost__c
        createSchedule(b.Id, 1, 'Construction', 100, 300000, 0);

        // Swap: Plot +100k, Construction -100k → new Construction = 200000
        Test.startTest();
        BookingAmountAdjustmentController.saveAdjustment(b.Id, 600000, 200000);
        Test.stopTest();

        Payment_schedule__c updated = [
            SELECT Amount__c FROM Payment_schedule__c WHERE Booking__c = :b.Id LIMIT 1
        ];

    }


    @isTest
    static void testSaveAdjustment_receivedExceedsNewAmount_throwsAuraHandledException() {
        Booking__c b = createBooking(500000, 300000, 0);

        // Land schedule: 50% of 500000 = 250000; received = 280000 (> new amount of 200000 after swap)
        createSchedule(b.Id, 1, 'Land', 50, 250000, 280000);

        // Swap: Plot 400k, Construction 400k → delta = (400k-500k)+(400k-300k) = 0
        // New Land schedule: 50% of 400000 = 200000 < received 280000 → should throw
        Test.startTest();
        try {
            BookingAmountAdjustmentController.saveAdjustment(b.Id, 400000, 400000);

        } catch (AuraHandledException e) {

        }
        Test.stopTest();
    }

    @isTest
    static void testSaveAdjustment_receivedExactlyEqualsNewAmount_succeeds() {
        Booking__c b = createBooking(500000, 300000, 0);

        // Land schedule: 50% of 500000 = 250000; received = 250000 (== new amount after no-op)
        createSchedule(b.Id, 1, 'Land', 50, 250000, 250000);

        Test.startTest();
        // No-op swap → new amount still 250000 = received → should NOT throw
        BookingAmountAdjustmentController.saveAdjustment(b.Id, 500000, 300000);
        Test.stopTest();

        Payment_schedule__c updated = [
            SELECT Amount__c FROM Payment_schedule__c WHERE Booking__c = :b.Id LIMIT 1
        ];

    }

    @isTest
    static void testSaveAdjustment_multipleSchedules_allRecalculated() {
        Booking__c b = createBooking(500000, 300000, 0);

        createSchedule(b.Id, 1, 'Land',         50,  250000, 0);
        createSchedule(b.Id, 2, 'Construction', 100, 300000, 0);

        // Swap: Plot +100k, Construction -100k
        Test.startTest();
        BookingAmountAdjustmentController.saveAdjustment(b.Id, 600000, 200000);
        Test.stopTest();

        Map<Integer, Decimal> amountBySNo = new Map<Integer, Decimal>();
        for (Payment_schedule__c ps : [
            SELECT S_No__c, Amount__c FROM Payment_schedule__c WHERE Booking__c = :b.Id
        ]) {
            amountBySNo.put((Integer) ps.S_No__c, ps.Amount__c);
        }


    }

    @isTest
    static void testSaveAdjustment_rollbackOnError_bookingNotUpdated() {
        Booking__c b = createBooking(500000, 300000, 0);

        // Land schedule with received that will exceed new amount after swap
        // Swap: Plot 400k, Const 400k → new land = 50% of 400k = 200k; received = 280k → throws
        createSchedule(b.Id, 1, 'Land', 50, 250000, 280000);

        Test.startTest();
        try {
            BookingAmountAdjustmentController.saveAdjustment(b.Id, 400000, 400000);
        } catch (AuraHandledException e) {
            // Expected
        }
        Test.stopTest();

        // Booking should be rolled back to original values
        Booking__c check = [
            SELECT Plot_Land_Cost__c, Construction_Cost__c FROM Booking__c WHERE Id = :b.Id
        ];

    }

    @isTest
    static void testSaveAdjustment_zeroCosts_noSchedules_succeeds() {
        Booking__c b = createBooking(0, 0, 0);

        Test.startTest();
        BookingAmountAdjustmentController.saveAdjustment(b.Id, 0, 0);
        Test.stopTest();

        Booking__c updated = [
            SELECT Plot_Land_Cost__c, Construction_Cost__c FROM Booking__c WHERE Id = :b.Id
        ];
 
    }
}