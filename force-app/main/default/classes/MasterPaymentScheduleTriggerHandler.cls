public class MasterPaymentScheduleTriggerHandler {
    public static void afterUpdate( List<Master_Payment_Schedule__c> newMasterPaymentSchedules, Map<Id, Master_Payment_Schedule__c> oldMasterPaymentSchedules) 
    {
        Set<Id> completedMPSIds         = new Set<Id>();
        Map<Id, Master_Payment_Schedule__c> completedMpsMap = new Map<Id, Master_Payment_Schedule__c>();
        Map<Id, Boolean> masterInterestMap = new Map<Id, Boolean>();
        Set<String> completedProjectNames  = new Set<String>();
        
        // ── Single pass over trigger records ──────────────────────────────────
        for (Master_Payment_Schedule__c mps : newMasterPaymentSchedules) {
            Master_Payment_Schedule__c oldMps = oldMasterPaymentSchedules.get(mps.Id);
            if (oldMps == null) continue;

            if (mps.Status__c == 'Completed' && mps.Status__c != oldMps.Status__c) {
                completedMPSIds.add(mps.Id);
                completedMpsMap.put(mps.Id, mps);
                completedProjectNames.add(mps.Project_Name__c);
            }

            if (mps.Include_Interest__c != oldMps.Include_Interest__c) {
                masterInterestMap.put(mps.Id, mps.Include_Interest__c);
            }
        }

        // ── Single bulk query + single DML on Payment_Schedule__c ─────────────
        // Merge both sets of IDs so we touch each child record only once
        Set<Id> allRelevantMPSIds = new Set<Id>();
        allRelevantMPSIds.addAll(completedMPSIds);
        allRelevantMPSIds.addAll(masterInterestMap.keySet());

        if (!allRelevantMPSIds.isEmpty()) {
            List<Payment_Schedule__c> schedulesToUpdate = new List<Payment_Schedule__c>();

            for (Payment_Schedule__c schedule : [
                SELECT Id, Master_Payment_Schedule__c,
                       Include_Interest__c, Status__c, Completed_Date_New__c
                FROM Payment_Schedule__c
                WHERE Master_Payment_Schedule__c IN :allRelevantMPSIds
            ]) {
                Id mpsId = schedule.Master_Payment_Schedule__c;

                // Apply completion changes
                if (completedMpsMap.containsKey(mpsId)) {
                    Master_Payment_Schedule__c mps = completedMpsMap.get(mpsId);
                    schedule.Status__c            = 'Completed';
                    schedule.Completed_Date_New__c = mps.Completed_Date__c;
                }

                // Apply interest changes
                if (masterInterestMap.containsKey(mpsId)) {
                    schedule.Include_Interest__c = masterInterestMap.get(mpsId);
                }

                schedulesToUpdate.add(schedule);
            }

            if (!schedulesToUpdate.isEmpty()) {
                update schedulesToUpdate;
            }
        }

        // ── Notifications for completed milestones ────────────────────────────
        if (!completedProjectNames.isEmpty()) {
            // Map project → active owner IDs
            Map<String, Set<String>> projectToActiveOwnerIds = new Map<String, Set<String>>();
            for (Booking__c book : [
                SELECT Id, OwnerId, Project__c
                FROM Booking__c
                WHERE Project__c IN :completedProjectNames
                AND   Is_Owner_Active__c = true
            ]) {
                if (!projectToActiveOwnerIds.containsKey(book.Project__c)) {
                    projectToActiveOwnerIds.put(book.Project__c, new Set<String>());
                }
                projectToActiveOwnerIds.get(book.Project__c).add(book.OwnerId);
            }

            // Fetch notification type once
            String notificationTypeId = getNotificationTypeId();

            // Send one notification per completed MPS
            for (Id mpsId : completedMpsMap.keySet()) {
                Master_Payment_Schedule__c mps = completedMpsMap.get(mpsId);
                Set<String> userIds = projectToActiveOwnerIds.get(mps.Project_Name__c);
                if (userIds == null || userIds.isEmpty()) continue;

                String body = 'Payment Milestone ' + mps.Name
                            + ' for ' + mps.Project_Name__c
                            + ' has been completed. Please proceed with Demand Raising.';

                CustomNotificationService.notificationSend(
                    'Master Payment Schedule Update',
                    mps.Id,
                    body,               // fixed capitalisation
                    userIds,
                    notificationTypeId
                );
            }
        }
    }

    private static String getNotificationTypeId() {
        CustomNotificationType[] types = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = 'Master_Payment_Schedule_Completion_Notification'
            LIMIT 1
        ];
        return types.isEmpty() ? null : types[0].Id;
    }
}