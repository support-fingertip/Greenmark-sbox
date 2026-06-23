@isTest
public class BookingControllerTest {

    @isTest
    static void testAllBookingControllerMethods() {

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

        Test.startTest();

        // 1. Picklist Methods
        BookingController.getPaymentTypePicklistValues();
        BookingController.getFundingtTypePicklistValues();

        // 2. Quote Record
        BookingController.quoteRecord(qc.Id);

        // 3. Save File
        Blob testBlob = Blob.valueOf('Test File Content');
        String base64File = EncodingUtil.base64Encode(testBlob);
        BookingController.saveFile(qc.Id, 'Sample.pdf', base64File, 'application/pdf', 'BookingDoc');

        // 4. Convert Quote - happy path
        List<String> payTypes  = BookingController.getPaymentTypePicklistValues();
        List<String> fundTypes = BookingController.getFundingtTypePicklistValues();

        Booking__c newBook = new Booking__c(
            Funding_Type__c    = fundTypes.isEmpty() ? null : fundTypes[0],
            Booking_Amount__c  = 50000,
            Mode_Of_Payment__c = payTypes.isEmpty()  ? null : payTypes[0],
            Booking_Date__c    = Date.today()
        );

        List<Co_Applicant__c> caList = new List<Co_Applicant__c>{
            new Co_Applicant__c(Name = 'Test User', Primary_Phone__c = '1234567891')
        };
        BookingController.convertQuote(qc.Id, newBook, caList);

        // 5. Convert Quote - empty co-applicant name
        Plot__c ut2 = new Plot__c(Status__c = 'Available', Project__c = pjt.Id);
        insert ut2;

        Quote__c qc2 = new Quote__c(
            Block_Lookup__c  = bc.Id,
            Quote_status__c  = 'Drafted',
            Block__c         = 'A2',
            Project__c       = 'Trifecta Vanto',
            Payment_Type__c  = 'Standard',
            Sale_Area__c     = 1000,
            Built_up_area__c = 1200,
            Rate_per_sqft__c = 5000,
            Unit__c          = ut2.Id,
            SLead__c         = ld.Id,
            Property_Type__c = validPropertyType
        );
        insert qc2;

        BookingController.convertQuote(qc2.Id, new Booking__c(
            Funding_Type__c = fundTypes.isEmpty() ? null : fundTypes[0],
            Booking_Date__c = Date.today()
        ), new List<Co_Applicant__c>{ new Co_Applicant__c(Name = '') });

        // 6. Convert Quote - unit already sold
        Plot__c soldUnit = new Plot__c(Status__c = 'Sold', Project__c = pjt.Id);
        insert soldUnit;

        Quote__c soldQuote = new Quote__c(
            Block_Lookup__c  = bc.Id,
            Quote_status__c  = 'Drafted',
            Block__c         = 'A2',
            Project__c       = 'Trifecta Vanto',
            Payment_Type__c  = 'Standard',
            Sale_Area__c     = 1000,
            Built_up_area__c = 1200,
            Rate_per_sqft__c = 5000,
            Unit__c          = soldUnit.Id,
            SLead__c         = ld.Id,
            Property_Type__c = validPropertyType
        );
        insert soldQuote;
        BookingController.convertQuote(soldQuote.Id, new Booking__c(Funding_Type__c = fundTypes.isEmpty() ? null : fundTypes[0]), new List<Co_Applicant__c>());

        // 7. Convert Quote - unit already booked
        Plot__c bookedUnit = new Plot__c(Status__c = 'Booked', Project__c = pjt.Id);
        insert bookedUnit;

        Quote__c bookedQuote = new Quote__c(
            Block_Lookup__c  = bc.Id,
            Quote_status__c  = 'Drafted',
            Block__c         = 'A2',
            Project__c       = 'Trifecta Vanto',
            Payment_Type__c  = 'Standard',
            Sale_Area__c     = 1000,
            Built_up_area__c = 1200,
            Rate_per_sqft__c = 5000,
            Unit__c          = bookedUnit.Id,
            SLead__c         = ld.Id,
            Property_Type__c = validPropertyType
        );
        insert bookedQuote;
        BookingController.convertQuote(bookedQuote.Id, new Booking__c(Funding_Type__c = fundTypes.isEmpty() ? null : fundTypes[0]), new List<Co_Applicant__c>());

        // 8. Change Unit Status
        Plot__c ut3 = new Plot__c(Status__c = 'Booked', Project__c = pjt.Id);
        insert ut3;

        Booking__c book = new Booking__c(
            Funding_Type__c = fundTypes.isEmpty() ? null : fundTypes[0],
            Quote__c        = qc.Id,
            Plot__c         = ut3.Id
        );
        insert book;
        //BookingController.changeUnitStatus(new List<Booking__c>{ book });

        Test.stopTest();
    }

    private class RestMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody('{}');
            res.setStatusCode(200);
            return res;
        }
    }
}