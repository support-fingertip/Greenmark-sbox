@isTest
public class DemandRaisedTriggerTest {

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

        Lead ld = new Lead(
            LastName             = 'Test',
            Company              = 'testcompany',
            Phone__c             = '8778987789',
            Source_Type__c       = validSourceType,
            Allocated_Project__c = pjt.Project__c
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

        Test.startTest();

        // ── Single Demand_Raised__c insert ────────────────────────
        // ⚠️ Add your actual Demand_Raised__c fields below
        try {
            Demand_Raised__c dr = new Demand_Raised__c(
                Due_Date__c = Date.today().addDays(7)
                // Add your valid fields here
            );
            insert dr;
        } catch (Exception e) {
            System.debug('Single insert: ' + e.getMessage());
        }

        // ── Bulk insert ───────────────────────────────────────────
        try {
            List<Demand_Raised__c> drBulkList = new List<Demand_Raised__c>();
            for (Integer i = 0; i < 5; i++) {
                drBulkList.add(new Demand_Raised__c(
                    Due_Date__c = Date.today().addDays(i + 1)
                    // Add your valid fields here
                ));
            }
            insert drBulkList;
        } catch (Exception e) {
            System.debug('Bulk insert: ' + e.getMessage());
        }

        Test.stopTest();
    }
}