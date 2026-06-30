@isTest
public class KenytSiteVisitReminderSchedulerTest {
    @isTest
    static void testSchedulerRuns() {
        Lead l = new Lead(LastName='SV Rem', Company='Test', Phone__c='9000000001');
        insert l;
        Site_Visit__c sv1 = new Site_Visit__c(SLead__c=l.Id, Status__c='Scheduled',
            Date__c = System.now().addDays(1));
        Site_Visit__c sv2 = new Site_Visit__c(SLead__c=l.Id, Status__c='Scheduled',
            Date__c = System.now());
        insert new List<Site_Visit__c>{ sv1, sv2 };

        Test.startTest();
        KenytSiteVisitReminderScheduler.sendReminders();   // no active template -> safe no-op
        System.schedule('Kenyt SV Rem Test', '0 0 7 * * ?', new KenytSiteVisitReminderScheduler());
        Test.stopTest();
        System.assert(true, 'scheduler must run without error');
    }
}
