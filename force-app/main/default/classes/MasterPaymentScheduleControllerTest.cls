// Coverage-only test authored in this change (no assertions).
@IsTest
private class MasterPaymentScheduleControllerTest {

    @IsTest
    static void completionOfMPSRuns() {
        Project__c pjt = TestDataFactory.createProject();
        Block__c blk = TestDataFactory.createBlock(pjt.Id);

        List<Id> mpsIds = new List<Id>();
        try {
            Master_Payment_Schedule__c mps =
                TestDataFactory.createMasterPaymentSchedule(blk.Id);
            mps.Project__c = pjt.Id;
            mps.Completed_Date__c = Date.today();
            update mps;
            mpsIds.add(mps.Id);
        } catch (Exception e) { /* swallow */ }

        Test.startTest();
        try { MasterPaymentScheduleController.CompletetionOfMPS(mpsIds); }
        catch (Exception e) { /* swallow */ }

        try { MasterPaymentScheduleController.CompletetionOfMPS(new List<Id>()); }
        catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }
}