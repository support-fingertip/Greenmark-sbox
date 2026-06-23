@isTest
public class BookingDemandInvoiceTest {

    @isTest
    static void testAllBookingDemandInvoiceMethods() {

        // Setup Data
        Project__c pjt = new Project__c(
            Name = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c = true,
            GST_on_Aggrement__c = 0.06
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
            Applicant_Name__c  = 'Test User',
            Project1__c        = pjt.Id,
            Plot__c            = ut.Id,
            Quote__c           = qc.Id,
            SLead__c           = ld.Id,
            Booking_Date__c    = Date.today(),
            Booking_Amount__c  = 50000
        );
        insert book;

        Co_Applicant__c coApp = new Co_Applicant__c(
            Name            = 'Co Applicant Test',
            PAN_Number__c   = 'ABCDE1234F',
            Booking__c      = book.Id,
            Primary_Phone__c = '9876543210'
        );
        insert coApp;

        Demand_Raised__c dr = new Demand_Raised__c(
            Booking__c         = book.Id,
            Amount_Demanded__c = 100000
        );
        insert dr;

        Test.startTest();

        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(book);
        BookingDemandInvoice controller = new BookingDemandInvoice(stdCtrl);

        Test.stopTest();
    }
}