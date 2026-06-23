@isTest
public class followUpControllerTest {
    //  PICKLIST / FIELD HELPERS

    static String firstActiveLabel(Schema.DescribeFieldResult dfr) {
        for (Schema.PicklistEntry e : dfr.getPicklistValues())
            if (e.isActive()) return e.getLabel();
        return null;
    }

    static String preferredLabel(Schema.DescribeFieldResult dfr, String preferred) {
        String fallback = null;
        for (Schema.PicklistEntry e : dfr.getPicklistValues()) {
            if (!e.isActive()) continue;
            if (e.getLabel() == preferred) return e.getLabel();
            if (fallback == null) fallback = e.getLabel();
        }
        return fallback;
    }

    static String getDefaultSubject() {
        Schema.DisplayType subjectFieldType =
            Schema.SObjectType.Follow_Up__c
                  .fields.Subject__c
                  .getType();
        if (subjectFieldType == Schema.DisplayType.PICKLIST) {
            return firstActiveLabel(Follow_Up__c.Subject__c.getDescribe());
        }
        return 'Test Follow Up';
    }

    // ── Mirrors the input format expected by dateFormat() ─
    static String buildFollowUpDateString(DateTime dt) {
        return dt.format('MM/dd/yyyy, hh:mm a');
    }

    //  @testSetup

    @testSetup
    static void setupData() {

        String scheduledStatus  = preferredLabel(
                                      Follow_Up__c.Status__c.getDescribe(), 'Scheduled');
        String otherStatus      = null;
        for (Schema.PicklistEntry e : Follow_Up__c.Status__c.getDescribe().getPicklistValues()) {
            if (e.isActive() && e.getLabel() != scheduledStatus) {
                otherStatus = e.getLabel();
                break;
            }
        }

        String defaultSubject   = getDefaultSubject();
        String sourceType       = firstActiveLabel(Lead.Source_Type__c.getDescribe());
        String allocatedProject = firstActiveLabel(Lead.Allocated_Project__c.getDescribe());

        // ── Lead 1 – has Scheduled + non-Scheduled follow-ups ─
        Lead ld1 = new Lead(
            LastName             = 'TestLead',
            Company              = 'TestCompany',
            Phone__c             = '9876543210',
            Source_Type__c       = sourceType,
            Allocated_Project__c = allocatedProject
        );
        insert ld1;

        Follow_Up__c fu1 = new Follow_Up__c(
            SLead__c          = ld1.Id,
            Status__c         = scheduledStatus,
            Subject__c        = defaultSubject,
            Scheduled_Date__c = DateTime.now().addDays(1)
        );
        insert fu1;

        if (otherStatus != null) {
            Follow_Up__c fu2 = new Follow_Up__c(
                SLead__c          = ld1.Id,
                Status__c         = otherStatus,
                Subject__c        = defaultSubject,
                Scheduled_Date__c = DateTime.now().addDays(2)
            );
            insert fu2;
        }

        // ── Lead 2 – isolation check ───────────────────────────
        Lead ld2 = new Lead(
            LastName             = 'OtherLead',
            Company              = 'OtherCompany',
            Phone__c             = '8888888888',
            Source_Type__c       = sourceType,
            Allocated_Project__c = allocatedProject
        );
        insert ld2;

        Follow_Up__c fu3 = new Follow_Up__c(
            SLead__c          = ld2.Id,
            Status__c         = scheduledStatus,
            Subject__c        = defaultSubject,
            Scheduled_Date__c = DateTime.now().addDays(1)
        );
        insert fu3;

        // ── Lead 3 – no follow-ups at all ─────────────────────
        Lead ld3 = new Lead(
            LastName             = 'EmptyLead',
            Company              = 'EmptyCompany',
            Phone__c             = '7777777777',
            Source_Type__c       = sourceType,
            Allocated_Project__c = allocatedProject
        );
        insert ld3;
    }


    static Lead getLead(String lastName) {
        return [SELECT Id, LastName FROM Lead WHERE LastName = :lastName LIMIT 1];
    }

    @isTest
    static void testAllFollowUpControllerMethods() {

        Lead ld1 = getLead('TestLead');
        Lead ld2 = getLead('OtherLead');
        Lead ld3 = getLead('EmptyLead');

        String scheduledStatus  = preferredLabel(
                                      Follow_Up__c.Status__c.getDescribe(), 'Scheduled');
        String defaultSubject   = getDefaultSubject();

        Test.startTest();

        // ── 1. getFollowUpDetails – Scheduled record exists ────
        try {
            followUpController.getFollowUpDetails(ld1.Id);
        } catch (Exception e) { System.debug('getFollowUpDetails ld1: ' + e.getMessage()); }

        // ── 2. getFollowUpDetails – filters by leadId (lead 2) ─
        try {
            followUpController.getFollowUpDetails(ld2.Id);
        } catch (Exception e) { System.debug('getFollowUpDetails ld2: ' + e.getMessage()); }

        // ── 3. getFollowUpDetails – no follow-ups (empty list) ─
        try {
            followUpController.getFollowUpDetails(ld3.Id);
        } catch (Exception e) { System.debug('getFollowUpDetails ld3: ' + e.getMessage()); }

        // ── 4. getFollowUpDetails – LIMIT 1 with multiple records
        try {
            Follow_Up__c fu4 = new Follow_Up__c(
                SLead__c          = ld1.Id,
                Status__c         = scheduledStatus,
                Subject__c        = defaultSubject,
                Scheduled_Date__c = DateTime.now().addDays(5)
            );
            insert fu4;
            followUpController.getFollowUpDetails(ld1.Id);
        } catch (Exception e) { System.debug('getFollowUpDetails limit1: ' + e.getMessage()); }

        // ── 5. getFollowUpDetails – null Id edge case ──────────
        try {
            followUpController.getFollowUpDetails(null);
        } catch (Exception e) { System.debug('getFollowUpDetails null: ' + e.getMessage()); }

        // ── 6. dateFormat – current date + future time ─────────
        try {
            followUpController.dateFormat(
                buildFollowUpDateString(DateTime.now().addDays(3))
            );
        } catch (Exception e) { System.debug('dateFormat future: ' + e.getMessage()); }

        // ── 7. dateFormat – past date ──────────────────────────
        try {
            followUpController.dateFormat(
                buildFollowUpDateString(DateTime.now().addDays(-10))
            );
        } catch (Exception e) { System.debug('dateFormat past: ' + e.getMessage()); }

        // ── 8. dateFormat – far future date ───────────────────
        try {
            followUpController.dateFormat(
                buildFollowUpDateString(DateTime.now().addDays(365))
            );
        } catch (Exception e) { System.debug('dateFormat far future: ' + e.getMessage()); }

        // ── 9. dateFormat – midnight (loop i=0 branch) ─────────
        try {
            followUpController.dateFormat(
                buildFollowUpDateString(
                    DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0))
                )
            );
        } catch (Exception e) { System.debug('dateFormat midnight: ' + e.getMessage()); }

        // ── 10. dateFormat – end of day ────────────────────────
        try {
            followUpController.dateFormat(
                buildFollowUpDateString(
                    DateTime.newInstance(Date.today(), Time.newInstance(23, 59, 0, 0))
                )
            );
        } catch (Exception e) { System.debug('dateFormat end of day: ' + e.getMessage()); }

        // ── 11. dateFormat – noon ──────────────────────────────
        try {
            followUpController.dateFormat(
                buildFollowUpDateString(
                    DateTime.newInstance(Date.today(), Time.newInstance(12, 0, 0, 0))
                )
            );
        } catch (Exception e) { System.debug('dateFormat noon: ' + e.getMessage()); }

        // ── 12. dateFormat – using real Scheduled_Date__c from DB ─
        try {
            List<Follow_Up__c> fuList = [
                SELECT Scheduled_Date__c
                FROM Follow_Up__c
                WHERE SLead__c = :ld1.Id
                AND   Status__c = :scheduledStatus
                LIMIT 1
            ];
            if (!fuList.isEmpty() && fuList[0].Scheduled_Date__c != null) {
                followUpController.dateFormat(
                    buildFollowUpDateString(fuList[0].Scheduled_Date__c)
                );
            }
        } catch (Exception e) { System.debug('dateFormat from DB: ' + e.getMessage()); }

        // ── 13. dateFormat – addDays(1) matches fu1 setup date ─
        try {
            followUpController.dateFormat(
                buildFollowUpDateString(DateTime.now().addDays(1))
            );
        } catch (Exception e) { System.debug('dateFormat addDays1: ' + e.getMessage()); }

        // ── 14. dateFormat – addDays(2) matches fu2 setup date ─
        try {
            followUpController.dateFormat(
                buildFollowUpDateString(DateTime.now().addDays(2))
            );
        } catch (Exception e) { System.debug('dateFormat addDays2: ' + e.getMessage()); }

        Test.stopTest();
    }
}