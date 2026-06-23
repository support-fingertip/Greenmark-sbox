@isTest
public class BulkRaiseDemandControllerTest {

    @isTest
    static void testAllBulkRaiseDemandControllerMethods() {

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

        Plot__c ut2 = new Plot__c(
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut2;

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

        Quote__c qc2 = new Quote__c(
            Block_Lookup__c  = bc.Id,
            Quote_status__c  = 'Drafted',
            Block__c         = 'A2',
            Project__c       = 'Trifecta Vanto',
            Payment_Type__c  = 'Standard',
            Sale_Area__c     = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100,
            Unit__c          = ut2.Id,
            SLead__c         = ld.Id,
            Property_Type__c = validPropertyType
        );
        insert qc2;

        Booking__c book = new Booking__c(
            Applicant_Name__c = 'Test User',
            Project1__c       = pjt.Id,
            Plot__c           = ut.Id,
            Quote__c          = qc.Id,
            SLead__c          = ld.Id,
            Booking_Date__c   = Date.today(),
            Booking_Amount__c = 50000,
            Email__c          = 'test@test.com'
        );
        insert book;

        Booking__c book2 = new Booking__c(
            Applicant_Name__c = 'Test User 2',
            Project1__c       = pjt.Id,
            Plot__c           = ut2.Id,
            Quote__c          = qc2.Id,
            SLead__c          = ld.Id,
            Booking_Date__c   = Date.today(),
            Booking_Amount__c = 50000,
            Email__c          = 'test2@test.com'
        );
        insert book2;

        // Current master payment schedule - S_No__c = 2
        Master_Payment_Schedule__c mps = new Master_Payment_Schedule__c(
            Project__c        = pjt.Id,
            S_No__c           = 2,
            Status__c         = 'Completed',
            Completed_Date__c = Date.today()
        );
        insert mps;

        // Previous master payment schedule - S_No__c = 1 (different from current)
        // This makes aggregate query return results → covers aggregateResult != null branch
        Master_Payment_Schedule__c mpsPrev = new Master_Payment_Schedule__c(
            Project__c        = pjt.Id,
            S_No__c           = 1,
            Status__c         = 'Completed',
            Completed_Date__c = Date.today().addDays(-30)
        );
        insert mpsPrev;

        // Payment Schedule for book1 linked to current mps (S_No__c = 2)
        Payment_Schedule__c ps = new Payment_Schedule__c(
            Booking__c                 = book.Id,
            Master_Payment_Schedule__c = mps.Id,
            Amount__c                  = 100000,
            Status__c                  = 'Scheduled',
            Is_Demanded__c             = false,
            Payment_Due_Date__c        = Date.today()
        );
        insert ps;

        // Payment Schedule for book1 linked to previous mps (S_No__c = 1)
        // This gets picked up by aggregate query (Status=Completed, S_No != current)
        // → covers aggregateResult != null branch
        Payment_Schedule__c psPrev = new Payment_Schedule__c(
            Booking__c                 = book.Id,
            Master_Payment_Schedule__c = mpsPrev.Id,
            Amount__c                  = 100000,
            Status__c                  = 'Scheduled',
            Is_Demanded__c             = false
        );
        insert psPrev;

        // Payment Schedule for book2 - covers continue branch
        Payment_Schedule__c ps2 = new Payment_Schedule__c(
            Booking__c                 = book2.Id,
            Master_Payment_Schedule__c = mps.Id,
            Amount__c                  = 100000,
            Status__c                  = 'Scheduled',
            Is_Demanded__c             = false
        );
        insert ps2;

        Test.startTest();

        // 1. getBookingRecords
        BulkRaiseDemandController.getBookingRecords(mps.Id);

        // 2. getBookingRecordsWithProject
        BulkRaiseDemandController.getBookingRecordsWithProject(mps.Id);

        // 3. bookingScheduleCalculations - direct call with both bookings
        Map<Id, Payment_Schedule__c> paymentBookMap = new Map<Id, Payment_Schedule__c>();
        paymentBookMap.put(book.Id, ps);
        paymentBookMap.put(book2.Id, ps2);

        BulkRaiseDemandController.bookingScheduleCalculations(
            new List<Booking__c>{ book, book2 },
            paymentBookMap,
            mps
        );

        // 4. updatePaymentSchedules - Payment_Due_Date__c populated (covers date branch)
        BulkRaiseDemandController.updatePaymentSchedules(ps.Id);

        // 5. updatePaymentSchedules - no Payment_Due_Date__c (covers null date branch)
        BulkRaiseDemandController.updatePaymentSchedules(ps2.Id);

        Test.stopTest();
    }
}