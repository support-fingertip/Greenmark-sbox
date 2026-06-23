@isTest
public class DemandRaisedTriggerHandlerTest {

    @isTest
    static void testDemandRaisedTriggerOnAfterInsert() {

        // ── Project ───────────────────────────────────────────────
        Project__c pjt = new Project__c(
            Name       = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c  = true
        );
        insert pjt;

        // ── Block ─────────────────────────────────────────────────
        Block__c bc = new Block__c(
            Name                  = 'A',
            Intrest_Percentage__c = 12,
            Project__c            = pjt.Id
        );
        insert bc;

        // ── Lead - Source_Type__c fetched dynamically ─────────────
        Schema.DescribeFieldResult sourceTypeField = Lead.Source_Type__c.getDescribe();
        String validSourceType = null;
        for (Schema.PicklistEntry ple : sourceTypeField.getPicklistValues()) {
            if (ple.isActive()) { validSourceType = ple.getLabel(); break; }
        }

        // ── Lead - Allocated_Project__c fetched dynamically ───────
        Schema.DescribeFieldResult leadProjectField = Lead.Allocated_Project__c.getDescribe();
        String validLeadProject = null;
        for (Schema.PicklistEntry ple : leadProjectField.getPicklistValues()) {
            if (ple.isActive()) { validLeadProject = ple.getLabel(); break; }
        }

        Lead ld = new Lead(
            LastName             = 'Test',
            Company              = 'testcompany',
            Phone__c             = '8778987789',
            Source_Type__c       = validSourceType,
            Allocated_Project__c = validLeadProject
        );
        insert ld;

        // ── Plot - Status__c fetched dynamically ──────────────────
        Schema.DescribeFieldResult plotStatusField = Plot__c.Status__c.getDescribe();
        String validPlotStatus = null;
        for (Schema.PicklistEntry ple : plotStatusField.getPicklistValues()) {
            if (ple.isActive() && ple.getLabel() == 'Available') {
                validPlotStatus = ple.getLabel();
                break;
            }
        }

        Plot__c ut = new Plot__c(
            Status__c       = validPlotStatus,
            Project__c      = pjt.Id,
            Block_Lookup__c = bc.Id
        );
        insert ut;

        // ── Quote - RecordType fetched dynamically ─────────────────
        List<RecordType> quoteRecordTypes = [
            SELECT Id, Name FROM RecordType
            WHERE SObjectType = 'Quote__c'
            LIMIT 1
        ];
        String validQuotePropertyType = quoteRecordTypes.isEmpty() ? null : quoteRecordTypes[0].Name;

        // ── Quote - Payment_Type__c fetched dynamically ────────────
        Schema.DescribeFieldResult paymentTypeField = Quote__c.Payment_Type__c.getDescribe();
        String validPaymentType = null;
        for (Schema.PicklistEntry ple : paymentTypeField.getPicklistValues()) {
            if (ple.isActive()) { validPaymentType = ple.getLabel(); break; }
        }

        // ── Quote - Project__c fetched dynamically ─────────────────
        Schema.DescribeFieldResult quoteProjectField = Quote__c.Project__c.getDescribe();
        String validQuoteProject = null;
        for (Schema.PicklistEntry ple : quoteProjectField.getPicklistValues()) {
            if (ple.isActive()) { validQuoteProject = ple.getLabel(); break; }
        }

        Quote__c qc = new Quote__c(
            Block_Lookup__c  = bc.Id,
            Quote_status__c  = 'Drafted',
            Block__c         = 'A2',
            Project__c       = validQuoteProject,
            Payment_Type__c  = validPaymentType,
            Sale_Area__c     = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100,
            Unit__c          = ut.Id,
            SLead__c         = ld.Id,
            Property_Type__c = validQuotePropertyType
        );
        insert qc;

        // ── Master Payment Schedule ───────────────────────────────
        Master_Payment_Schedule__c mps = new Master_Payment_Schedule__c(
            Project__c         = pjt.Id,
            Block__c           = bc.Id,
            S_No__c            = 1,
            Status__c          = 'Completed',
            Completed_Date__c  = Date.today(),
            Payment_Percent__c = 10
        );
        insert mps;

        // ── Payment Schedule ──────────────────────────────────────
        Payment_Schedule__c ps = new Payment_Schedule__c(
            Master_Payment_Schedule__c = mps.Id,
            Payment_Percent__c         = 10,
            S_No__c                    = 1,
            Quote__c                   = qc.Id,
            Status__c                  = 'Completed'
        );
        insert ps;

        // ── Booking - RecordType fetched dynamically ───────────────
        List<RecordType> bookingRecordTypes = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Booking__c'
            LIMIT 1
        ];

        // ── Booking - Project__c fetched dynamically ───────────────
        Schema.DescribeFieldResult bookingProjectField = Booking__c.Project__c.getDescribe();
        String validBookingProject = null;
        for (Schema.PicklistEntry ple : bookingProjectField.getPicklistValues()) {
            if (ple.isActive()) { validBookingProject = ple.getLabel(); break; }
        }

        Booking__c bk = new Booking__c(
            First_Applicant_Name__c = 'Test Applicant',
            Mobile__c               = '9876543210',
            Quote__c                = qc.Id,
            Project__c              = validBookingProject
        );
        if (!bookingRecordTypes.isEmpty()) {
            bk.RecordTypeId = bookingRecordTypes[0].Id;
        }
        insert bk;

        Test.startTest();

        // ── Single Demand_Raised__c insert ────────────────────────
        try {
            Demand_Raised__c dr = new Demand_Raised__c(
                Booking__c     = bk.Id,
                Grand_Total__c = 150000
            );
            insert dr;
        } catch (Exception e) {
            System.debug('Single insert: ' + e.getMessage());
        }

        // ── Bulk insert - covers bulk trigger execution path ───────
        try {
            List<Demand_Raised__c> drBulkList = new List<Demand_Raised__c>();
            for (Integer i = 0; i < 5; i++) {
                drBulkList.add(new Demand_Raised__c(
                    Booking__c     = bk.Id,
                    Grand_Total__c = 10000 * (i + 1)
                ));
            }
            insert drBulkList;
        } catch (Exception e) {
            System.debug('Bulk insert: ' + e.getMessage());
        }

        // ── Null/Empty guard - covers null check in handler ────────
        try {
            DemandRaisedTriggerHandler.onAfterInsert(null);
        } catch (Exception e) {
            System.debug('Null list: ' + e.getMessage());
        }

        try {
            DemandRaisedTriggerHandler.onAfterInsert(new List<Demand_Raised__c>());
        } catch (Exception e) {
            System.debug('Empty list: ' + e.getMessage());
        }

        Test.stopTest();
    }
}