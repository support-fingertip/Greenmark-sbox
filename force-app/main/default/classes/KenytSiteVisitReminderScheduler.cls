/**
 * KenytSiteVisitReminderScheduler
 * -------------------------------
 * Sends the two time-based site-visit reminders via Kenyt (BRD 4.12.2 #5 and #6):
 *   - SV_REMINDER_1 : one day before the scheduled visit
 *   - SV_REMINDER_2 : on the same day as the scheduled visit
 *
 * Schedule it to run once daily (e.g. early morning), for example:
 *   System.schedule('Kenyt SV Reminders', '0 0 7 * * ?', new KenytSiteVisitReminderScheduler());
 *
 * Both sends are no-ops until the matching Kenyt_Template__mdt records are active,
 * so scheduling it early is safe.
 */
global class KenytSiteVisitReminderScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        sendReminders();
    }

    public static void sendReminders() {
        // Reminder 1 - visits scheduled TOMORROW
        DateTime tomorrowStart = DateTime.newInstance(Date.today().addDays(1), Time.newInstance(0, 0, 0, 0));
        DateTime tomorrowEnd   = tomorrowStart.addDays(1);
        Set<Id> reminder1 = new Map<Id, Site_Visit__c>([
            SELECT Id FROM Site_Visit__c
            WHERE Status__c = 'Scheduled' AND Date__c >= :tomorrowStart AND Date__c < :tomorrowEnd
        ]).keySet();
        if (!reminder1.isEmpty()) {
            KenytWhatsAppService.send('SV_REMINDER_1', reminder1, 'Site_Visit__c');
        }

        // Reminder 2 - visits scheduled TODAY
        DateTime todayStart = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        DateTime todayEnd   = todayStart.addDays(1);
        Set<Id> reminder2 = new Map<Id, Site_Visit__c>([
            SELECT Id FROM Site_Visit__c
            WHERE Status__c = 'Scheduled' AND Date__c >= :todayStart AND Date__c < :todayEnd
        ]).keySet();
        if (!reminder2.isEmpty()) {
            KenytWhatsAppService.send('SV_REMINDER_2', reminder2, 'Site_Visit__c');
        }
    }
}
