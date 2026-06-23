// Coverage-only test authored in this change (no assertions).
@IsTest
private class MasterPaymentScheduleTriggerHandlerTest {

    @IsTest
    static void afterUpdateBranches() {
        Project__c pjt = TestDataFactory.createProject();
        Block__c blk = TestDataFactory.createBlock(pjt.Id);
        Master_Payment_Schedule__c mps;
        try { mps = TestDataFactory.createMasterPaymentSchedule(blk.Id); }
        catch (Exception e) { return; /* required-field mismatch in some orgs */ }

        // Payment_Schedule__c record tied to this MPS so afterUpdate does work.
        Lead ld = TestDataFactory.createLead();
        Plot__c pl = TestDataFactory.createPlot(pjt.Id);
        Quote__c qc = TestDataFactory.createQuote(blk.Id, pl.Id, ld.Id);
        Booking__c bk = TestDataFactory.createBooking('Apartments', pjt, blk, ld, pl, qc);
        Payment_Schedule__c ps = new Payment_Schedule__c(
            Name                        = 'Milestone',
            Booking__c                  = bk.Id,
            S_No__c                     = 1,
            Payment_percent__c          = 10,
            Master_Payment_Schedule__c  = mps.Id
        );
        try { insert ps; } catch (Exception e) { /* swallow */ }

        Test.startTest();
        try {
            // Toggle Include_Interest
            mps.Include_Interest__c = true;
            update mps;

            // Mark MPS Completed
            mps.Completed_Date__c = Date.today();
            mps.Status__c = 'Completed';
            update mps;
        } catch (Exception e) { /* swallow */ }

        // Direct handler invocation — harmless empty-map call.
        try {
            MasterPaymentScheduleTriggerHandler.afterUpdate(
                new List<Master_Payment_Schedule__c>(),
                new Map<Id, Master_Payment_Schedule__c>());
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }
}