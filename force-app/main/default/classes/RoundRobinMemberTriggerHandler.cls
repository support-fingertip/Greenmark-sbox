/**
 * RoundRobinMemberTriggerHandler
 * ------------------------------
 * BRD 4.1.9: when an Admin/Sales Head marks a round-robin member as inactive,
 * the executive receives a notification.
 *
 * Fires whenever Active__c flips true -> false on a member, regardless of how it
 * was changed (toggle UI, record edit, or Apex). Sends:
 *   - a custom (bell) notification, and
 *   - an email
 * to the member's User.
 */
// Sends bell + email to the executive on member deactivation (BRD 4.1.9).
public without sharing class RoundRobinMemberTriggerHandler {

    private static final String NOTIF_TYPE = 'Round_Robin_Member_Deactivated';

    public static void afterUpdate(List<Round_Robin_Member__c> newList,
                                   Map<Id, Round_Robin_Member__c> oldMap) {
        // Collect members that just went Active true -> false, with a user.
        Map<Id, Round_Robin_Member__c> deactivatedByUser = new Map<Id, Round_Robin_Member__c>();
        Set<Id> rrIds = new Set<Id>();
        for (Round_Robin_Member__c m : newList) {
            Round_Robin_Member__c old = oldMap.get(m.Id);
            if (old != null && old.Active__c == true && m.Active__c == false && m.User__c != null) {
                deactivatedByUser.put(m.User__c, m);
                if (m.Round_Robin__c != null) { rrIds.add(m.Round_Robin__c); }
            }
        }
        if (deactivatedByUser.isEmpty()) { return; }

        // Only notify active Salesforce users.
        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Name, Email, IsActive FROM User WHERE Id IN :deactivatedByUser.keySet() AND IsActive = true
        ]);
        if (userMap.isEmpty()) { return; }

        // Round robin names for the message.
        Map<Id, String> rrName = new Map<Id, String>();
        for (Round_Robin__c rr : [SELECT Id, Name FROM Round_Robin__c WHERE Id IN :rrIds]) {
            rrName.put(rr.Id, rr.Name);
        }

        sendBellNotifications(deactivatedByUser, userMap, rrName);
        sendEmails(deactivatedByUser, userMap, rrName);
    }

    private static String buildMessage(Round_Robin_Member__c m, Map<Id, String> rrName) {
        String rr = (m.Round_Robin__c != null && rrName.containsKey(m.Round_Robin__c))
            ? rrName.get(m.Round_Robin__c) : 'a';
        return 'You have been marked inactive in the ' + rr +
               ' round robin. You will not receive new leads until you are reactivated.';
    }

    private static void sendBellNotifications(Map<Id, Round_Robin_Member__c> byUser,
                                              Map<Id, User> userMap, Map<Id, String> rrName) {
        List<CustomNotificationType> types = [
            SELECT Id FROM CustomNotificationType WHERE DeveloperName = :NOTIF_TYPE LIMIT 1
        ];
        if (types.isEmpty()) { return; }
        Id typeId = types[0].Id;

        for (Id userId : byUser.keySet()) {
            if (!userMap.containsKey(userId)) { continue; }
            Round_Robin_Member__c m = byUser.get(userId);
            try {
                Messaging.CustomNotification n = new Messaging.CustomNotification();
                n.setTitle('Round Robin Member Deactivated');
                n.setBody(buildMessage(m, rrName));
                n.setNotificationTypeId(typeId);
                n.setTargetId(m.Id);
                n.send(new Set<String>{ String.valueOf(userId) });
            } catch (Exception e) {
                System.debug('RR member bell notification failed: ' + e.getMessage());
            }
        }
    }

    private static void sendEmails(Map<Id, Round_Robin_Member__c> byUser,
                                   Map<Id, User> userMap, Map<Id, String> rrName) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Id userId : byUser.keySet()) {
            User u = userMap.get(userId);
            if (u == null || String.isBlank(u.Email)) { continue; }
            Round_Robin_Member__c m = byUser.get(userId);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ u.Email });
            mail.setSubject('Round Robin Member Deactivated');
            mail.setPlainTextBody('Hi ' + u.Name + ',\n\n' + buildMessage(m, rrName) +
                                  '\n\nRegards,\nGreenMark CRM');
            mail.setSaveAsActivity(false);
            emails.add(mail);
        }
        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails, false);
            } catch (Exception e) {
                System.debug('RR member deactivation email failed: ' + e.getMessage());
            }
        }
    }
}
