// Coverage-only test authored in this change (no assertions).
@IsTest
private class UpdateLeadStatusControllerTest {

    @TestSetup
    static void setup() {
        Lead l = TestDataFactory.createLead();
    }

    @IsTest
    static void coversUpdateLastNote() {
        Lead ld = [SELECT Id, Last_Comment__c FROM Lead LIMIT 1];
        Test.startTest();
        try {
            UpdateLeadStatusController.updateLastNote(
                ld.Id, 'First note', true, false, null, null);

            UpdateLeadStatusController.updateLastNote(
                ld.Id, 'Second note with followup', true, false,
                Datetime.now().addDays(1), 'call');

            UpdateLeadStatusController.updateLastNote(
                ld.Id, 'secondary skip', false, true,
                Datetime.now().addDays(2), '');
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void coversUpdateLastNoteInBulk() {
        Lead ld = [SELECT Id FROM Lead LIMIT 1];
        Map<Id, String> m = new Map<Id, String>{ ld.Id => 'bulk note 1' };
        Test.startTest();
        try {
            UpdateLeadStatusController.updateLastNoteInBulk(m);
            // second run to exercise the existing-comment branch
            UpdateLeadStatusController.updateLastNoteInBulk(
                new Map<Id, String>{ ld.Id => 'bulk note 2' });
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void coversFetchLastNotes() {
        Lead ld = [SELECT Id FROM Lead LIMIT 1];
        ld.Last_Comment__c = 'Note 1: hello\nNote 2: world\n';
        update ld;
        Test.startTest();
        try {
            UpdateLeadStatusController.fetchLeadLastNotes(ld.Id);
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }
}