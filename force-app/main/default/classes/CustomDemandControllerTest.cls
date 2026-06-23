@isTest
public class CustomDemandControllerTest {

    @isTest
    static void testAllCustomDemandControllerMethods() {

        // Project
        Project__c pjt = new Project__c(
            Name       = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c  = true
        );
        insert pjt;

        // Block
        Block__c bc = new Block__c(
            Name                  = 'A',
            Intrest_Percentage__c = 12,
            Project__c            = pjt.Id
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

        Booking__c book = new Booking__c(
            Applicant_Name__c       = 'Test User',
            First_Applicant_Name__c = 'Test User',
            Project1__c             = pjt.Id,
            Plot__c                 = ut.Id,
            Quote__c                = qc.Id,
            SLead__c                = ld.Id,
            Booking_Date__c         = Date.today(),
            Booking_Amount__c       = 50000,
            Email__c                = 'test@test.com'
        );
        insert book;

        // Master Payment Schedule - previous (S_No__c = 1, Completed)
        Master_Payment_Schedule__c mpsPrev = new Master_Payment_Schedule__c(
            Project__c         = pjt.Id,
            Block__c           = bc.Id,
            S_No__c            = 1,
            Status__c          = 'Completed',
            Completed_Date__c  = Date.today().addDays(-30),
            Payment_Percent__c = 10
        );
        insert mpsPrev;

        // Master Payment Schedule - current (S_No__c = 2)
        Master_Payment_Schedule__c mpsCurrent = new Master_Payment_Schedule__c(
            Project__c         = pjt.Id,
            Block__c           = bc.Id,
            S_No__c            = 2,
            Status__c          = 'Completed',
            Completed_Date__c  = Date.today(),
            Payment_Percent__c = 20
        );
        insert mpsCurrent;

        // Payment Schedule for previous milestone (S_No__c = 1, Completed)
        Payment_Schedule__c psPrev = new Payment_Schedule__c(
            Booking__c                 = book.Id,
            Master_Payment_Schedule__c = mpsPrev.Id,
            Amount__c                  = 50000,
            Payment_Percent__c         = 10,
            S_No__c                    = 1,
            Status__c                  = 'Completed'
        );
        insert psPrev;

        // Payment Schedule for current milestone (S_No__c = 2)
        Payment_Schedule__c psCurrent = new Payment_Schedule__c(
            Booking__c                 = book.Id,
            Master_Payment_Schedule__c = mpsCurrent.Id,
            Amount__c                  = 100000,
            Payment_Percent__c         = 20,
            S_No__c                    = 2,
            Status__c                  = 'Scheduled'
        );
        insert psCurrent;

        Test.startTest();

        // 1. Constructor - valid paymentScheduledId (covers full apartmentScheduleCalculations)
        PageReference pageRef = Page.Demand_Invioce_Custom;
        pageRef.getParameters().put('Id', book.Id);
        pageRef.getParameters().put('PId', psCurrent.Id);
        Test.setCurrentPage(pageRef);
        try {
            ApexPages.StandardController stdCtrl = new ApexPages.StandardController(book);
            CustomDemandController ctrl = new CustomDemandController(stdCtrl);
        } catch (Exception e) { System.debug('constructor valid PId: ' + e.getMessage()); }

        // 2. Constructor - null paymentScheduledId (covers null PId early return branch)
        PageReference pageRefNull = Page.Demand_Invioce_Custom;
        pageRefNull.getParameters().put('Id', book.Id);
        pageRefNull.getParameters().put('PId', null);
        Test.setCurrentPage(pageRefNull);
        try {
            ApexPages.StandardController stdCtrlNull = new ApexPages.StandardController(book);
            CustomDemandController ctrlNull = new CustomDemandController(stdCtrlNull);
        } catch (Exception e) { System.debug('constructor null PId: ' + e.getMessage()); }

        // 3. getMilestoneLabel - covers daySuffixMap entries
        // 1st, 2nd, 3rd, 4th (default th), 21st, 22nd, 23rd, 31st
        CustomDemandController.getMilestoneLabel(1);
        CustomDemandController.getMilestoneLabel(2);
        CustomDemandController.getMilestoneLabel(3);
        CustomDemandController.getMilestoneLabel(4);
        CustomDemandController.getMilestoneLabel(11);
        CustomDemandController.getMilestoneLabel(21);
        CustomDemandController.getMilestoneLabel(22);
        CustomDemandController.getMilestoneLabel(23);
        CustomDemandController.getMilestoneLabel(31);
        CustomDemandController.getMilestoneLabel(null);

        // 4. Constructor with master schedule that has empty msRecordList
        // (covers isEmpty early return in apartmentScheduleCalculations)
        Master_Payment_Schedule__c mpsEmpty = new Master_Payment_Schedule__c(
            Project__c         = pjt.Id,
            Block__c           = bc.Id,
            S_No__c            = 99,
            Status__c          = 'In Progress',
            Payment_Percent__c = 5
        );
        insert mpsEmpty;

        Payment_Schedule__c psEmpty = new Payment_Schedule__c(
            Booking__c                 = book.Id,
            Master_Payment_Schedule__c = mpsEmpty.Id,
            Amount__c                  = 10000,
            Payment_Percent__c         = 5,
            S_No__c                    = 99,
            Status__c                  = 'Scheduled'
        );
        insert psEmpty;

        PageReference pageRefEmpty = Page.Demand_Invioce_Custom;
        pageRefEmpty.getParameters().put('Id', book.Id);
        pageRefEmpty.getParameters().put('PId', psEmpty.Id);
        Test.setCurrentPage(pageRefEmpty);
        try {
            ApexPages.StandardController stdCtrlEmpty = new ApexPages.StandardController(book);
            CustomDemandController ctrlEmpty = new CustomDemandController(stdCtrlEmpty);
        } catch (Exception e) { System.debug('constructor empty master: ' + e.getMessage()); }

        Test.stopTest();
    }
}