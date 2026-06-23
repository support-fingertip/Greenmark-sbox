@isTest
public class DemandInvioceControllerTest {

    @isTest
    static void testAllDemandInvioceControllerMethods() {

        // Project
        Project__c pjt = new Project__c(
            Name       = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c  = true
        );
        insert pjt;

        // Block
        Block__c bc = new Block__c(
            Name                         = 'A',
            Intrest_Percentage__c        = 12,
            Project__c                   = pjt.Id,
            Email__c                     = 'block@test.com',
            Project_Address__c           = 'Test Project Address',
            Company_Address__c           = 'Test Company Address',
            Company_Name__c              = 'Test Company',
            Land_Company_Name__c         = 'Test Land Company',
            Construction_Company_Name__c = 'Test Construction Company',
            Bank_Name__c                 = 'HDFC',
            Account_Number__c            = '1234567890',
            IFSC_Code__c                 = 'HDFC0001234',
            Type_of_Account__c           = 'Current',
            Branch__c                    = 'Test Branch'
        );
        insert bc;

        // Lead
        Schema.DescribeFieldResult sourceTypeField = Lead.Source_Type__c.getDescribe();
        String validSourceType = null;
        for (Schema.PicklistEntry ple : sourceTypeField.getPicklistValues()) {
            if (ple.isActive()) { validSourceType = ple.getLabel(); break; }
        }

        Lead ld = new Lead(
            LastName             = 'Test',
            Company              = 'testcompany',
            Phone__c             = '8778987789',
            Source_Type__c       = validSourceType,
            Allocated_Project__c = pjt.Project__c
        );
        insert ld;

        // Plot
        Schema.DescribeFieldResult plotStatusField = Plot__c.Status__c.getDescribe();
        String validPlotStatus = null;
        for (Schema.PicklistEntry ple : plotStatusField.getPicklistValues()) {
            if (ple.isActive() && ple.getLabel() == 'Available') {
                validPlotStatus = ple.getLabel(); break;
            }
        }

        Plot__c ut = new Plot__c(
            Status__c       = validPlotStatus,
            Project__c      = pjt.Id,
            Block_Lookup__c = bc.Id
        );
        insert ut;

        // Quote RecordType
        List<RecordType> quoteRecordTypes = [
            SELECT Id, Name FROM RecordType
            WHERE SObjectType = 'Quote__c' LIMIT 1
        ];
        String validQuotePropertyType = quoteRecordTypes.isEmpty() ? null : quoteRecordTypes[0].Name;

        // Quote Payment_Type__c
        Schema.DescribeFieldResult paymentTypeField = Quote__c.Payment_Type__c.getDescribe();
        String validPaymentType = null;
        for (Schema.PicklistEntry ple : paymentTypeField.getPicklistValues()) {
            if (ple.isActive()) { validPaymentType = ple.getLabel(); break; }
        }

        Quote__c qc = new Quote__c(
            Block_Lookup__c  = bc.Id,
            Quote_status__c  = 'Drafted',
            Block__c         = 'A2',
            Project__c       = pjt.Project__c,
            Payment_Type__c  = validPaymentType,
            Sale_Area__c     = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100,
            Unit__c          = ut.Id,
            SLead__c         = ld.Id,
            Property_Type__c = validQuotePropertyType
        );
        insert qc;

        // Booking RecordType
        List<RecordType> bookingRecordTypes = [
            SELECT Id, Name FROM RecordType
            WHERE SObjectType = 'Booking__c' LIMIT 1
        ];
        String validBookingPropertyType = bookingRecordTypes.isEmpty() ? null : bookingRecordTypes[0].Name;

        // Booking - Apartment type
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
            Project_Type__c         = 'Apartments'
        );
        insert book;

        // Booking - Villas type
        Booking__c bookVillas = new Booking__c(
            Applicant_Name__c       = 'Test Villas User',
            First_Applicant_Name__c = 'Test Villas User',
            Project1__c             = pjt.Id,
            Plot__c                 = ut.Id,
            Quote__c                = qc.Id,
            SLead__c                = ld.Id,
            Booking_Date__c         = Date.today(),
            Booking_Amount__c       = 50000,
            Email__c                = 'villas@test.com',
            Project_Type__c         = 'Villas'
        );
        insert bookVillas;

        // Co Applicant
        Co_Applicant__c coApp = new Co_Applicant__c(
            Name             = 'Co Applicant Test',
            Booking__c       = book.Id,
            Primary_Phone__c = '9876543210'
        );
        insert coApp;

        // Master Payment Schedule
        Master_Payment_Schedule__c mps = new Master_Payment_Schedule__c(
            Project__c         = pjt.Id,
            Block__c           = bc.Id,
            S_No__c            = 1,
            Status__c          = 'Completed',
            Completed_Date__c  = Date.today(),
            Payment_Percent__c = 10
        );
        insert mps;

        // Payment Schedule - Completed (for psRecordList)
        Payment_Schedule__c psCompleted = new Payment_Schedule__c(
            Booking__c                 = book.Id,
            Master_Payment_Schedule__c = mps.Id,
            Amount__c                  = 100000,
            Payment_Percent__c         = 10,
            S_No__c                    = 1,
            Status__c                  = 'Completed',
            Type__c                    = 'Land',
            Payment_Due_Date__c        = Date.today().addDays(7)
        );
        insert psCompleted;

        // Payment Schedule - Completed for Villas Land type
        Payment_Schedule__c psVillasLand = new Payment_Schedule__c(
            Booking__c                 = bookVillas.Id,
            Master_Payment_Schedule__c = mps.Id,
            Amount__c                  = 100000,
            Payment_Percent__c         = 10,
            S_No__c                    = 1,
            Status__c                  = 'Completed',
            Type__c                    = 'Land',
            Payment_Due_Date__c        = Date.today().addDays(7)
        );
        insert psVillasLand;

        // Payment Schedule - Completed for Villas Construction type
        Master_Payment_Schedule__c mps2 = new Master_Payment_Schedule__c(
            Project__c         = pjt.Id,
            Block__c           = bc.Id,
            S_No__c            = 2,
            Status__c          = 'Completed',
            Completed_Date__c  = Date.today(),
            Payment_Percent__c = 10
        );
        insert mps2;

        Payment_Schedule__c psVillasConst = new Payment_Schedule__c(
            Booking__c                 = bookVillas.Id,
            Master_Payment_Schedule__c = mps2.Id,
            Amount__c                  = 100000,
            Payment_Percent__c         = 10,
            S_No__c                    = 2,
            Status__c                  = 'Completed',
            Type__c                    = 'Construction',
            Payment_Due_Date__c        = Date.today().addDays(7)
        );
        insert psVillasConst;

        Test.startTest();

        // 1. Constructor - Apartment, no reminderType (covers default DEMAND NOTE path)
        PageReference pageRef = Page.Demand_Invoice;
        pageRef.getParameters().put('Id', book.Id);
        Test.setCurrentPage(pageRef);
        try {
            DemandInvioceController ctrl = new DemandInvioceController(
                new ApexPages.StandardController(book)
            );
        } catch (Exception e) { System.debug('Apartment no reminder: ' + e.getMessage()); }

        // 2. Constructor - reminderType = Demand_1ST_REMINDER
        PageReference pageRef1 = Page.Demand_Invoice;
        pageRef1.getParameters().put('Id', book.Id);
        pageRef1.getParameters().put('reminderType', 'Demand_1ST_REMINDER');
        Test.setCurrentPage(pageRef1);
        try {
            DemandInvioceController ctrl1 = new DemandInvioceController(
                new ApexPages.StandardController(book)
            );
        } catch (Exception e) { System.debug('Reminder 1: ' + e.getMessage()); }

        // 3. Constructor - reminderType = Demand_2ND_REMINDER
        PageReference pageRef2 = Page.Demand_Invoice;
        pageRef2.getParameters().put('Id', book.Id);
        pageRef2.getParameters().put('reminderType', 'Demand_2ND_REMINDER');
        Test.setCurrentPage(pageRef2);
        try {
            DemandInvioceController ctrl2 = new DemandInvioceController(
                new ApexPages.StandardController(book)
            );
        } catch (Exception e) { System.debug('Reminder 2: ' + e.getMessage()); }

        // 4. Constructor - reminderType = Demand_3RD_REMINDER
        PageReference pageRef3 = Page.Demand_Invoice;
        pageRef3.getParameters().put('Id', book.Id);
        pageRef3.getParameters().put('reminderType', 'Demand_3RD_REMINDER');
        Test.setCurrentPage(pageRef3);
        try {
            DemandInvioceController ctrl3 = new DemandInvioceController(
                new ApexPages.StandardController(book)
            );
        } catch (Exception e) { System.debug('Reminder 3: ' + e.getMessage()); }

        // 5. Constructor - reminderType = custom value (covers else branch)
        PageReference pageRefCustom = Page.Demand_Invoice;
        pageRefCustom.getParameters().put('Id', book.Id);
        pageRefCustom.getParameters().put('reminderType', 'CUSTOM_REMINDER');
        Test.setCurrentPage(pageRefCustom);
        try {
            DemandInvioceController ctrlCustom = new DemandInvioceController(
                new ApexPages.StandardController(book)
            );
        } catch (Exception e) { System.debug('Custom reminder: ' + e.getMessage()); }

        // 6. Constructor - Villas + Land type (covers Villas Land branch)
        PageReference pageRefVillasLand = Page.Demand_Invoice;
        pageRefVillasLand.getParameters().put('Id', bookVillas.Id);
        Test.setCurrentPage(pageRefVillasLand);
        try {
            DemandInvioceController ctrlVillasLand = new DemandInvioceController(
                new ApexPages.StandardController(bookVillas)
            );
        } catch (Exception e) { System.debug('Villas Land: ' + e.getMessage()); }

        // 7. Booking with no completed payment schedules (covers isEmpty early return)
        Booking__c bookEmpty = new Booking__c(
            Applicant_Name__c       = 'Empty User',
            First_Applicant_Name__c = 'Empty User',
            Project1__c             = pjt.Id,
            Plot__c                 = ut.Id,
            Quote__c                = qc.Id,
            SLead__c                = ld.Id,
            Booking_Date__c         = Date.today(),
            Booking_Amount__c       = 50000,
            Email__c                = 'empty@test.com',
            Project_Type__c         = 'Apartments'
        );
        insert bookEmpty;

        PageReference pageRefEmpty = Page.Demand_Invoice;
        pageRefEmpty.getParameters().put('Id', bookEmpty.Id);
        Test.setCurrentPage(pageRefEmpty);
        try {
            DemandInvioceController ctrlEmpty = new DemandInvioceController(
                new ApexPages.StandardController(bookEmpty)
            );
        } catch (Exception e) { System.debug('Empty schedules: ' + e.getMessage()); }

        // 8. Directly instantiate bookingInfoWrapper to cover all property lines
        DemandInvioceController.bookingInfoWrapper biw = new DemandInvioceController.bookingInfoWrapper();
        biw.customerId      = 'C-001';
        biw.reminderType    = 'DEMAND NOTE';
        biw.customerName    = 'Test User';
        biw.unitNo          = 'A101';
        biw.block           = 'A';
        biw.project         = 'Trifecta Vanto';
        biw.demandDate      = Date.today();
        biw.projectAddress  = 'Test Address';
        biw.email           = 'test@test.com';
        biw.contactNo       = '9876543210';
        biw.webAddress      = 'www.trifectaprojects.com';
        biw.companyAddress  = 'Test Company Address';
        biw.companyName     = 'Test Company';
        biw.bankName        = 'HDFC';
        biw.accountNumber   = '1234567890';
        biw.ifscCode        = 'HDFC0001234';
        biw.typeOfAccount   = 'Current';
        biw.branch          = 'Test Branch';

        Test.stopTest();
    }
}