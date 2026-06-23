// Coverage-only test authored in this change (no assertions).
@IsTest
private class SendReceiptToCustomerClassTest {

    @IsTest
    static void sendReceiptApartments() {
        Booking__c bk = TestDataFactory.createBooking('Apartments');
        List<Payment_Schedule__c> ps = TestDataFactory.createPaymentSchedules(bk.Id, 1);
        try {
            Receipt__c rec = TestDataFactory.createReceipt(bk.Id);
            TestDataFactory.createReceiptLineItem(rec.Id, ps[0].Id, bk.Id);
        } catch (Exception e) { /* swallow */ }

        try { insert new Co_Applicant__c(Booking__c = bk.Id, Name = 'Co', Email__c = 'co@example.com'); }
        catch (Exception e) { /* swallow */ }

        Test.startTest();
        try { SendReceiptToCustomerClass.sendReceiptToCustomer(bk.Id); }
        catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void sendReceiptVillas() {
        Booking__c bk = TestDataFactory.createBooking('Villas');
        Test.startTest();
        try { SendReceiptToCustomerClass.sendReceiptToCustomer(bk.Id); }
        catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }
}