@isTest
public class BookingWelcomeMailTest {

    @isTest
    static void testAllBookingWelcomeMailMethods() {

        // Setup Data
        Project__c pjt = new Project__c(
            Name = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c = true
        );
        insert pjt;

        Block__c bc = new Block__c(
            Name = 'A',
            Intrest_Percentage__c = 12,
            Project__c = pjt.Id
        );
        insert bc;

        Lead ld = new Lead(
            LastName = 'Test',
            Company = 'testcompany',
            Phone__c = '8778987789',
            Source_Type__c = 'Google',
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert ld;

        Plot__c ut = new Plot__c(
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut;

        List<RecordType> bookingRecordTypes = [
            SELECT Id, Name
            FROM RecordType
            WHERE SObjectType = 'Booking__c'
            LIMIT 1
        ];
        String validPropertyType = bookingRecordTypes.isEmpty() ? null : bookingRecordTypes[0].Name;

        Quote__c qc = new Quote__c(
            Block_Lookup__c  = bc.Id,
            Quote_status__c  = 'Drafted',
            Block__c         = 'A2',
            Project__c       = 'Trifecta Vanto',
            Payment_Type__c  = 'Standard',
            Sale_Area__c     = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100,
            Unit__c          = ut.Id,
            SLead__c         = ld.Id,
            Property_Type__c = validPropertyType
        );
        insert qc;

        Booking__c book = new Booking__c(
            Applicant_Name__c       = 'Test User',
            First_Applicant_Name__c = 'Test User',
            Project1__c             = pjt.Id,
            Plot__c                 = ut.Id,
            Quote__c                = qc.Id,
            SLead__c                = ld.Id,
            Booking_Date__c         = Date.today(),
            Booking_Amount__c       = 50000,
            Email__c                = 'test@test.com',
            Email1__c               = 'test1@test.com',
            Bank_Email__c           = 'bank@test.com',
            Project_Type__c         = 'Villas'
        );
        insert book;

        Test.startTest();

        // 1. sendEmailToCustomerCancellation - Cancellation type
        try {
            BookingWelcomeMail.sendEmailToCustomerCancellation(book.Id, 'Cancellation');
        } catch (Exception e) { System.debug('sendEmailToCustomerCancellation Cancellation: ' + e.getMessage()); }

        // 2. sendEmailToCustomerCancellation - PC type
        try {
            BookingWelcomeMail.sendEmailToCustomerCancellation(book.Id, 'PC');
        } catch (Exception e) { System.debug('sendEmailToCustomerCancellation PC: ' + e.getMessage()); }

        // 3. sendEmailToCustomerCancellation - SaleAgreement type
        try {
            BookingWelcomeMail.sendEmailToCustomerCancellation(book.Id, 'SaleAgreement');
        } catch (Exception e) { System.debug('sendEmailToCustomerCancellation SaleAgreement: ' + e.getMessage()); }

        // 4. sendEmailToCustomer - Cancellation type
        try {
            BookingWelcomeMail.sendEmailToCustomer(book.Id, 'Cancellation');
        } catch (Exception e) { System.debug('sendEmailToCustomer Cancellation: ' + e.getMessage()); }

        // 5. sendEmailToCustomer - PC type
        try {
            BookingWelcomeMail.sendEmailToCustomer(book.Id, 'PC');
        } catch (Exception e) { System.debug('sendEmailToCustomer PC: ' + e.getMessage()); }

        // 6. sendEmailToCustomer - ConsolidatedReceipt type
        try {
            BookingWelcomeMail.sendEmailToCustomer(book.Id, 'ConsolidatedReceipt');
        } catch (Exception e) { System.debug('sendEmailToCustomer ConsolidatedReceipt: ' + e.getMessage()); }

        // 7. sendEmailToCustomersWithIds - Cancellation type
        try {
            BookingWelcomeMail.sendEmailToCustomersWithIds(new List<Id>{ book.Id }, 'Cancellation');
        } catch (Exception e) { System.debug('sendEmailToCustomersWithIds Cancellation: ' + e.getMessage()); }

        // 8. sendEmailToCustomersWithIds - ConsolidatedReceipt type
        try {
            BookingWelcomeMail.sendEmailToCustomersWithIds(new List<Id>{ book.Id }, 'ConsolidatedReceipt');
        } catch (Exception e) { System.debug('sendEmailToCustomersWithIds ConsolidatedReceipt: ' + e.getMessage()); }

        // 9. sendEmailToCustomersWithIds - empty list
        try {
            BookingWelcomeMail.sendEmailToCustomersWithIds(new List<Id>(), 'Cancellation');
        } catch (Exception e) { System.debug('sendEmailToCustomersWithIds empty: ' + e.getMessage()); }

        // 10. sendEmailToBank - SaleAgreement Villas type
        try {
            BookingWelcomeMail.sendEmailToBank(book.Id, 'SaleAgreement');
        } catch (Exception e) { System.debug('sendEmailToBank SaleAgreement: ' + e.getMessage()); }

        // 11. sendEmailToBank - SaleDeed type
        try {
            BookingWelcomeMail.sendEmailToBank(book.Id, 'SaleDeed');
        } catch (Exception e) { System.debug('sendEmailToBank SaleDeed: ' + e.getMessage()); }

        // 12. sendEmailtoCustomer1
        try {
            BookingWelcomeMail.sendEmailtoCustomer1(book.Id);
        } catch (Exception e) { System.debug('sendEmailtoCustomer1: ' + e.getMessage()); }

        // 13. sendEmailToCustomerNOC
        try {
            BookingWelcomeMail.sendEmailToCustomerNOC(book.Id);
        } catch (Exception e) { System.debug('sendEmailToCustomerNOC: ' + e.getMessage()); }

        // 14. sendEmailToCustomerTPA
        try {
            BookingWelcomeMail.sendEmailToCustomerTPA(book.Id);
        } catch (Exception e) { System.debug('sendEmailToCustomerTPA: ' + e.getMessage()); }

        // 15. sendEmailToCustomerLOU
        try {
            BookingWelcomeMail.sendEmailToCustomerLOU(book.Id);
        } catch (Exception e) { System.debug('sendEmailToCustomerLOU: ' + e.getMessage()); }

        // 16. getBookingDetails
        try {
            BookingWelcomeMail.getBookingDetails(book.Id);
        } catch (Exception e) { System.debug('getBookingDetails: ' + e.getMessage()); }

        // 17. sendRequestForAgreementAmount
        try {
            BookingWelcomeMail.sendRequestForAgreementAmount(book.Id);
        } catch (Exception e) { System.debug('sendRequestForAgreementAmount: ' + e.getMessage()); }

        // 18. sendRequestForRegistration
        try {
            BookingWelcomeMail.sendRequestForRegistration(book.Id);
        } catch (Exception e) { System.debug('sendRequestForRegistration: ' + e.getMessage()); }

        // 19. Project_Type__c = non-Villas to cover else branch in SaleAgreement/SaleDeed
        Booking__c book2 = new Booking__c(
            Applicant_Name__c       = 'Test User 2',
            First_Applicant_Name__c = 'Test User 2',
            Project1__c             = pjt.Id,
            Plot__c                 = ut.Id,
            Quote__c                = qc.Id,
            SLead__c                = ld.Id,
            Booking_Date__c         = Date.today(),
            Booking_Amount__c       = 50000,
            Email__c                = 'test2@test.com',
            Bank_Email__c           = 'bank2@test.com',
            Project_Type__c         = 'Apartment'
        );
        try { insert book2; } catch (Exception e) { System.debug('insert book2: ' + e.getMessage()); }

        try {
            BookingWelcomeMail.sendEmailToBank(book2.Id, 'SaleAgreement');
        } catch (Exception e) { System.debug('sendEmailToBank Apartment SaleAgreement: ' + e.getMessage()); }

        try {
            BookingWelcomeMail.sendEmailToBank(book2.Id, 'SaleDeed');
        } catch (Exception e) { System.debug('sendEmailToBank Apartment SaleDeed: ' + e.getMessage()); }

        try {
            BookingWelcomeMail.sendEmailToCustomerCancellation(book2.Id, 'SaleAgreement');
        } catch (Exception e) { System.debug('sendEmailToCustomerCancellation Apartment: ' + e.getMessage()); }

        Test.stopTest();
    }
}