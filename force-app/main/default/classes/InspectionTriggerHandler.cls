public class InspectionTriggerHandler {

    // Inspection statuses that count as "open" for the Booking roll-up
    private static final Set<String> OPEN_STATUSES = new Set<String>{
        'Failed', 'In Progress', 'Scheduled'
    };

    public static void beforeUpdate(List<Inspection__c> newList, Map<Id, Inspection__c> oldMap) {
        
        Set<Id> inspectionIdsToCheck = new Set<Id>();
        
        for (Inspection__c ins : newList) {
            
            // ── Condition 1: Block status → Completed if snags are open ──────────
            if (ins.Status__c == 'Completed' && oldMap.get(ins.Id).Status__c != 'Completed') {
                inspectionIdsToCheck.add(ins.Id);
            }
            
            // ── Condition 2: Set First Set Time when Expected Date is entered for the first time ──
            if (ins.Expected_Completed_Date__c != null                          
                && oldMap.get(ins.Id).Expected_Completed_Date__c == null       
                && ins.Expected_Competion_Date_First_Set_Time__c == null) {     
                    
                    ins.Expected_Competion_Date_First_Set_Time__c = DateTime.now(); 
                }
            
            // ── Condition 3: Block date change after grace period (from Custom Label) ────
            if (ins.Expected_Completed_Date__c != oldMap.get(ins.Id).Expected_Completed_Date__c
                && oldMap.get(ins.Id).Expected_Completed_Date__c != null
                && ins.Expected_Competion_Date_First_Set_Time__c != null) 
            {
                
                // Get grace period in minutes from Custom Label
                // Setup → Custom Labels → Inspection_Expected_Completion_Date_Edit_In_mints
                Integer gracePeriodMinutes = Integer.valueOf(
                    System.Label.Inspection_Expected_Completion_Date_Edit_In_mints
                );
                
                // Calculate minutes passed since first set
                Long minutesPassed = (DateTime.now().getTime()
                                      - ins.Expected_Competion_Date_First_Set_Time__c.getTime())
                    / (1000 * 60);  // ← divided by milliseconds in a minute
                
                if (minutesPassed > gracePeriodMinutes) {
                    ins.addError(
                        'Expected Completion Date can only be corrected within '
                        + gracePeriodMinutes + ' minutes of first entry. '
                        + 'Please raise an Extension Request.'
                    );
                }
            }
        }
        
        if (inspectionIdsToCheck.isEmpty()) return;
        
        // Fetch related open Snags count per Inspection
        Map<Id, Integer> openSnagCount = new Map<Id, Integer>();
        
        for (AggregateResult ar : [
            SELECT Inspection__c insId, COUNT(Id) cnt
            FROM Snag_List__c
            WHERE Inspection__c IN :inspectionIdsToCheck
            AND Status__c != 'Resolved'
            GROUP BY Inspection__c
        ]) {
            openSnagCount.put((Id) ar.get('insId'), (Integer) ar.get('cnt'));
        }
        
        // Throw error if any inspection has open snags
        for (Inspection__c ins : newList) {
            if (inspectionIdsToCheck.contains(ins.Id)) {
                if (openSnagCount.containsKey(ins.Id)) {
                    ins.Status__c = oldMap.get(ins.Id).Status__c; // revert status
                    ins.addError(
                        'Inspection cannot be marked Completed because some Snags are still OPEN.'
                    );
                }
            }
        } 
    }
    //  AFTER UPDATE → send email when ALL snags are closed
    public static void sendCompletionEmail(List<Inspection__c> newList, Map<Id, Inspection__c> oldMap) {
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Set<Id> completedInspectionIds = new Set<Id>();
        Map<Id, Inspection__c> completedInsMap = new Map<Id, Inspection__c>();
        
        for (Inspection__c ins : newList) {
            if (ins.Status__c == 'Completed' && oldMap.get(ins.Id).Status__c != 'Completed') {
                Integer openCount = [SELECT COUNT() FROM Snag_List__c 
                                     WHERE Inspection__c = :ins.Id AND Status__c != 'Resolved'];
                if (openCount == 0) {
                    completedInspectionIds.add(ins.Id);
                    completedInsMap.put(ins.Id, ins);
                }
            }
        }
        
        // Bulk query — fetch Booking Name + First_Applicant_Name__c + OwnerId
        Map<Id, Booking__c> inspectionToBooking = new Map<Id, Booking__c>();
        if (!completedInspectionIds.isEmpty()) {
            for (Inspection__c ins : [SELECT Id, Booking__c, Booking__r.OwnerId,
                                      Booking__r.Name, Booking__r.First_Applicant_Name__c,Customer_Name__c
                                      FROM Inspection__c
                                      WHERE Id IN :completedInspectionIds]) {
                                          inspectionToBooking.put(ins.Id, ins.Booking__r);
                                      }
        }
        
        // Fetch custom notification type
        CustomNotificationType notifType = [SELECT Id 
                                            FROM CustomNotificationType 
                                            WHERE DeveloperName = 'Inspection_Notification' 
                                            LIMIT 1];
        
        for (Inspection__c ins : newList) {
            System.debug('Called');
            
            // ── Status changed to Completed ──────────────────────────────────────
            if (ins.Status__c == 'Completed' && oldMap.get(ins.Id).Status__c != 'Completed') {
                
                Integer openCount = [SELECT COUNT() FROM Snag_List__c 
                                     WHERE Inspection__c = :ins.Id AND Status__c != 'Resolved'];
                System.debug(openCount);
                
                if (openCount == 0) {
                    
                    
                    // ── Bell Notification to Booking Owner ───────────────────────
                    if (inspectionToBooking.containsKey(ins.Id)) {
                        Booking__c booking         = inspectionToBooking.get(ins.Id);
                        Id          bookingOwnerId  = booking.OwnerId;
                        String      bookingName     = booking.Name != null ? booking.Name : '';
                        String      applicantName   = booking.First_Applicant_Name__c != null 
                            ? booking.First_Applicant_Name__c 
                            : '';
                        
                        Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        notification.setNotificationTypeId(notifType.Id);
                        notification.setTargetId(ins.Id);
                        notification.setTitle('Snags Resolved – ' + bookingName + ' | ' + applicantName);
                        notification.setBody('All snags for inspection have been resolved. Please proceed with the next steps.');
                        
                        notification.send(new Set<String>{ bookingOwnerId });
                    }
                }
            }
            
            // ── Extended Completed Date changed + Approved ───────────────────────
            System.debug('Called ' + ins.Extended_Completed_Date__c
                         + oldMap.get(ins.Id).Extended_Completed_Date__c
                         + '==' + ins.Approval_Status__c);
            
            if (ins.Extended_Completed_Date__c != null && ins.Approval_Status__c == 'Approved') {
                System.debug(ins.Extended_Completed_Date__c + '=== ' + oldMap.get(ins.Id).Extended_Completed_Date__c);
                
                Messaging.SingleEmailMessage email1 = new Messaging.SingleEmailMessage();
                email1.toAddresses = new String[]{ ins.Customer_Email__c };
                    email1.subject     = 'Inspection Extended Date Notification';
                
                Date d = ins.Extended_Completed_Date__c;
                String formattedDate = (d == null)
                    ? 'N/A'
                    : String.valueOf(d.day()).leftPad(2, '0')   + '-' +
                        String.valueOf(d.month()).leftPad(2, '0') + '-' +
                        String.valueOf(d.year());
                
                email1.plainTextBody = 'Dear Sir/Madam,\n\nYour inspection completed date has been updated. '
                    + 'New Expected Completed Date ' + formattedDate+'\n\n' +
                    'If you have any further concerns or require additional assistance, please feel free to reach out to us.\n\n' +
                    'Thank you for your time and cooperation.\n\n' +
                    'Warm Regards,\n' +
                    'CRM Team,\n'+
                    'Trifecta Projects Pvt Ltd';
                
                email1.setSaveAsActivity(true);
                email1.setWhatId(ins.Id);
                emails.add(email1);
            }
        }
        
        if (!emails.isEmpty()) {
            System.debug(emails);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);
            System.debug(results);
        }
    }

    /**
     * Roll up the number of OPEN inspections (Status__c = Failed / In Progress /
     * Scheduled) onto the parent Booking__c.Open_Inspections__c field.
     *
     * Runs on insert / update / delete / undelete. Both new and old records are
     * considered so that re-parented inspections and status changes refresh the
     * count on every Booking that was affected.
     *
     * @param newList Trigger.new (null on delete)
     * @param oldList Trigger.old (null on insert / undelete)
     */
    public static void updateBookingOpenInspections(List<Inspection__c> newList,
                                                     List<Inspection__c> oldList) {

        Set<Id> bookingIds = new Set<Id>();

        if (newList != null) {
            for (Inspection__c ins : newList) {
                if (ins.Booking__c != null) bookingIds.add(ins.Booking__c);
            }
        }
        if (oldList != null) {
            for (Inspection__c ins : oldList) {
                if (ins.Booking__c != null) bookingIds.add(ins.Booking__c);
            }
        }

        if (bookingIds.isEmpty()) return;

        // Seed every affected Booking with 0 so counts reset to zero when the
        // last open inspection is closed or removed.
        Map<Id, Integer> openCountByBooking = new Map<Id, Integer>();
        for (Id bId : bookingIds) {
            openCountByBooking.put(bId, 0);
        }

        for (AggregateResult ar : [
            SELECT Booking__c bId, COUNT(Id) cnt
            FROM Inspection__c
            WHERE Booking__c IN :bookingIds
            AND Status__c IN :OPEN_STATUSES
            GROUP BY Booking__c
        ]) {
            openCountByBooking.put((Id) ar.get('bId'), (Integer) ar.get('cnt'));
        }

        List<Booking__c> bookingsToUpdate = new List<Booking__c>();
        for (Id bId : openCountByBooking.keySet()) {
            bookingsToUpdate.add(new Booking__c(
                Id                   = bId,
                Open_Inspections__c  = openCountByBooking.get(bId)
            ));
        }

        if (!bookingsToUpdate.isEmpty()) {
            update bookingsToUpdate;
        }
    }

    /**
     * Apex managed sharing: when an Inspection__c is created, share it with the
     * related Booking's Owner with Read/Write (Edit) access.
     *
     * NOTE: this requires the Inspection__c org-wide default to be Private or
     * Read Only — sharing rows cannot be inserted while the OWD is Public
     * Read/Write.
     *
     * @param newList Trigger.new (after insert)
     */
    public static void shareWithBookingOwner(List<Inspection__c> newList) {

        Set<Id> bookingIds = new Set<Id>();
        for (Inspection__c ins : newList) {
            if (ins.Booking__c != null) bookingIds.add(ins.Booking__c);
        }
        if (bookingIds.isEmpty()) return;

        // Map each Booking to its Owner.
        Map<Id, Id> ownerByBooking = new Map<Id, Id>();
        for (Booking__c b : [SELECT Id, OwnerId FROM Booking__c WHERE Id IN :bookingIds]) {
            ownerByBooking.put(b.Id, b.OwnerId);
        }

        List<Inspection__Share> shares = new List<Inspection__Share>();
        for (Inspection__c ins : newList) {
            if (ins.Booking__c == null) continue;

            Id ownerId = ownerByBooking.get(ins.Booking__c);
            if (ownerId == null) continue;

            // Skip if the Booking Owner is already the Inspection owner — a
            // share row for the owner is invalid and would error.
            if (ownerId == ins.OwnerId) continue;

            shares.add(new Inspection__Share(
                ParentId      = ins.Id,
                UserOrGroupId = ownerId,
                AccessLevel   = 'Edit',
                RowCause      = Schema.Inspection__Share.RowCause.Manual
            ));
        }

        if (!shares.isEmpty()) {
            // allOrNone = false: don't roll back the inspection insert if a
            // single share row is invalid (e.g. owner already has access).
            Database.insert(shares, false);
        }
    }
}