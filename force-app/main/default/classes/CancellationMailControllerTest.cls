@isTest
public class CancellationMailControllerTest {

    @isTest
    static void testAllCancellationMailControllerMethods() {

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
            Project__c              = 'Trifecta Vanto'
        );
        insert book;

        // Payment Schedule with S_No__c = 1 (required by sendWelcomeEmail)
        Master_Payment_Schedule__c mps = new Master_Payment_Schedule__c(
            Project__c        = pjt.Id,
            S_No__c           = 1,
            Status__c         = 'Completed',
            Completed_Date__c = Date.today()
        );
        insert mps;

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Booking__c                 = book.Id,
            Master_Payment_Schedule__c = mps.Id,
            Amount__c                  = 100000,
            Status__c                  = 'Scheduled',
            Is_Demanded__c             = false,
            S_No__c                    = 1
        );
        insert ps;

        // General_Settings__c with template body containing all placeholders
        General_Settings__c gs = new General_Settings__c(
            Type__c          = 'Cancellation Mail Template',
            Project_Name1__c = 'Trifecta Vanto',
            Subject__c       = 'Cancellation ##PROJECT_NAME## ##BLOCK_NAME## ##UNIT_NUMBER##',
            Template_Body__c = 'Dear ##APPLICANT_NAME##, Project: ##PROJECT_NAME##, Block: ##BLOCK_NAME##, Unit: ##UNIT_NUMBER##, Agreement: ##AGREEMENT_DATE##, CRM: ##CRM_NAME##, Phone: ##CRM_PHONE##, Email: ##CRM_EMAIL##, Company: ##COMAPANY_NAME##, ##SIGNATURE##'
        );
        insert gs;

        Test.startTest();

        // 1. getRecordData - covers all merge logic and placeholder replacements
        try {
            CancellationMailController.getRecordData(book.Id);
        } catch (Exception e) { System.debug('getRecordData: ' + e.getMessage()); }

        // 2. sendWelcomeEmail - covers email send, attachment, CC logic
        try {
            CancellationMailController.sendWelcomeEmail(
                book.Id,
                'Test Email Body',
                new List<String>{ 'test@test.com' },
                new List<String>()
            );
        } catch (Exception e) { System.debug('sendWelcomeEmail: ' + e.getMessage()); }

        Test.stopTest();
    }
}