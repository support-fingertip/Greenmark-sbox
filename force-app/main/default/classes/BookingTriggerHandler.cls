/****************************************************************
* Class Name   : BookingTriggerHandler
* Company      : Fingertipplus
* Created Date : 05-02-2026
* @description : Trigger handler for Booking__c object.
*                Handles:
*                - Payment Schedule mapping from Quote to Booking
*                - WhatsApp & SMS notifications on booking creation
*                - Owner assignment custom notification on update
* @author      : Durga Prasad
*
* Change Log:
* -----------------------------------------------------------------------------
* Ver | Author        | Date        | Description
* -----------------------------------------------------------------------------
* 1.0 | Durga Prasad  | 05-02-2026  | Initial version
* -----------------------------------------------------------------------------
*****************************************************************/
public class BookingTriggerHandler {
    /**
    * Method Name  : afterInsert
    * Description  : Executes after Booking__c records are inserted.
    *
    * Functionality:
    * 1. Maps related Payment_Schedule__c records from Quote__c → Booking__c.
    * 2. Updates all payment schedules linked to the Quote with the newly
    *    created Booking Id.
    * 3. Triggers WhatsApp and SMS notifications if the custom label
    *    'Enable_whatsapp_notifications' is set to TRUE.
    *
    * Process Flow:
    * - Collect Quote Ids from new Booking records.
    * - Fetch all Payment_Schedule__c linked to those Quotes.
    * - Update Booking__c lookup on Payment_Schedule__c.
    * - Enqueue WhatsAppController and SMSHandler queueable jobs.
    *
    *
    * Parameters:
    * @param newBookingList - List of newly inserted Booking__c records
    */
    public static void afterInsert(list<Booking__c> newBookingList){
        for(Booking__c bk: newBookingList)
        {
            // Step 1: Map Quote Id → Booking Id
            Map<Id, Id> quoteToBookingMap = new Map<Id, Id>();
            for (Booking__c booking : newBookingList) {
                if (booking.Quote__c != null) {
                    quoteToBookingMap.put(booking.Quote__c, booking.Id);
                }
                
            }
            
            if (!quoteToBookingMap.isEmpty()) {
                // Step 2: Fetch all Payment Schedules for these quotes
                List<Payment_Schedule__c> schedulesToUpdate = [
                    SELECT Id, Quote__c, Booking__c, S_No__c, Status__c
                    FROM Payment_Schedule__c
                    WHERE Quote__c IN :quoteToBookingMap.keySet()
                ];
                
                // Step 3: Assign Booking Id and mark first schedule as Completed
                for (Payment_Schedule__c schedule : schedulesToUpdate) {
                    schedule.Booking__c = quoteToBookingMap.get(schedule.Quote__c);
                }
                
                // Step 4: Update all in one go
                if (!schedulesToUpdate.isEmpty()) {
                    update schedulesToUpdate;
                }
            }
            
            if(label.Enable_whatsapp_notifications == 'TRUE'){
                
                List<Booking__c> books = [select Id,Name,S__c,First_Applicant_Name__c,Mobile__c,Plot__c,Plot__r.Name,Plot__r.Super_Built_up_Area__c,
                                          Plot__r.BHK_Type__c,Project1__c,Project1__r.Name from Booking__c where Id IN :trigger.new];
                
                WhatsappController wactrl = new WhatsappController(books,'6');
                System.enqueueJob(wactrl);
                SMSHandler smsctrl = new SMSHandler(books,'6');
                System.enqueueJob(smsctrl);
            }
        }
    }
    
    public static void beforeInsert(list<Booking__c> newBookingList){
        for(Booking__c bk: newBookingList)
        {
            for (Booking__c booking : newBookingList) {
                if (booking.Credit_Source__c != null) {
                    booking.Credit_Source_For_Sharing__c = booking.Credit_Source__c;
                }
                
            }
        }
    }
    
    /**
    * Method Name  : beforeUpdate
    * Description  : Executes before Booking__c records are updated to enforce
    *                business rules during approval stage transition.
    *
    * Functionality:
    * 1. Detects when Sub_Stages__c is changed to 'Management User Approved'.
    * 2. Validates that an Initial CRM Executive (CRM_Executive__c) is populated.
    * 3. If CRM Executive is available:
    *      - Transfers Booking ownership to the CRM Executive.
    * 4. If CRM Executive is NOT available:
    *      - Blocks the update with a validation error message.
    *
    * Business Rule:
    * - A booking cannot move to 'Management User Approved' stage
    *   without assigning an Initial Booking CRM Executive.
    *
    *
    * Parameters:
    * @param newBookingList - List of Booking__c records being updated
    * @param oldBookingMap  - Map of old Booking__c records by Id
    *
    * Used From:
    * - Booking Trigger (before update context)
    */
    public static void beforeUpdate(List<Booking__c> newBookingList,Map<Id, Booking__c> oldBookingMap)
    { 
        for (Booking__c bk : newBookingList)
        {
            Booking__c oldBk = oldBookingMap.get(bk.Id);
            
            /* Case 1: Sub Stage changed to Management User Approved */
            if (oldBk.Sub_Stages__c != bk.Sub_Stages__c && bk.Sub_Stages__c == 'Management User Approved') 
            {
                if (bk.CRM_executive__c != null) {
                    bk.OwnerId = bk.CRM_executive__c;
                    bk.Booking_Moved_To_Booked_Stage_Time__c = system.today();
                    bk.Stage_Status__c = 'In Progress';
                    bk.Move_to_Next_Stage__c = false;
                }
                else
                {
                    bk.addError('Please specify the Initial Booking CRM Executive in the booking to proceed with Approval');
                }
            }
        }
    }
    
    /**
    * Method Name  : afterUpdate
    * Description  : Executes after Booking__c records are updated.
    *
    * Functionality:
    * 1. Detects change in OwnerId of Booking.
    * 2. Sends a Custom Notification to the newly assigned owner.
    *
    * Notification Contains:
    * - Booking Name
    * - Stage
    * - Customer Name
    * - Action message for next steps
    *
    * Parameters:
    * @param newBookingList - List of updated Booking__c records
    * @param oldBookingMap  - Map of old Booking__c records by Id
    */
    public static void afterUpdate(List<Booking__c> newBookingList, Map<Id, Booking__c> oldBookingMap) {
        // ===== 1. SEND OWNER ASSIGNMENT NOTIFICATION =====
        String notificationTypeId = getNotificationTypeId();
        Map<Id, Id> bookingToOwnerMap = new Map<Id, Id>();
        Set<Id> unitSet = new Set<Id>();
        Set<Id> unitSetToUpdateSoldStatus = new Set<Id>();
        Set<Id> cancelledBookings = new Set<Id>();
        Set<Id> cancelledLeads = new Set<Id>();
        for (Booking__c bk : newBookingList) {
            Booking__c oldBk = oldBookingMap.get(bk.Id);
            if (oldBk.OwnerId != bk.OwnerId && bk.OwnerId != null) {
                bookingToOwnerMap.put(bk.Id, bk.OwnerId);
                String title = bk.Lead_Name__c + ' booking has been assigned to you';
                
                String body = 'Booking: ' + bk.Name + '\n'
                    + 'Stage: ' + bk.Stage__c + '\n'
                    + 'Customer Name: ' + bk.Lead_Name__c + '\n'
                    + 'Please proceed with the next steps.';
                
                CustomNotificationService.notificationSend(
                    title,
                    bk.Id,
                    body,
                    new Set<String>{bk.OwnerId},
                    notificationTypeId
                );
            }
            else if(oldBk.Stage__c != bk.Stage__c && bk.Stage__c != null)
            {
                String title = bk.Lead_Name__c + ' booking moved to stage ' + bk.Stage__c + ' and has been assigned to you.';
                String body = 'Booking: ' + bk.Name + '\n'
                    + 'Stage: ' + bk.Stage__c + '\n'
                    + 'Customer Name: ' + bk.Lead_Name__c + '\n';
                if(bk.Stage__c == 'Cancellation')
                {
                    if(bk.Plot__c != null)
                    {
                        unitSet.add(bk.Plot__c);
                    }
                    if(bk.SLead__c != null)
                    {
                        cancelledLeads.add(bk.SLead__c);
                    }
                    cancelledBookings.add(bk.Id);
                }
                else if(bk.Stage__c == 'Possession / Handover')
                {
                    if(bk.Plot__c != null)
                    {
                        unitSetToUpdateSoldStatus.add(bk.Plot__c);
                    }
                    body += 'Please proceed with the next steps.';
                }
                else
                {
                    body += 'Please proceed with the next steps.';
                }

                CustomNotificationService.notificationSend(
                    title,
                    bk.Id,
                    body,
                    new Set<String>{bk.OwnerId},
                    notificationTypeId
                );
            }

        }
        syncChildOwner(bookingToOwnerMap);
        shareBookingWithCRMExecutives(newBookingList, oldBookingMap);
        sendCancellationRequestEmail(newBookingList, oldBookingMap);
        sendCancellationApprovedEmail(newBookingList, oldBookingMap);
        if(!unitSet.isEmpty())
        {
            updatePlotAvailability(unitSet);
        }
        if(!unitSetToUpdateSoldStatus.isEmpty())
        {
            updatePlotStatusToSold(unitSetToUpdateSoldStatus);
        }
        
        if(!cancelledBookings.isEmpty())
        {
            updateReceiptStatusCancelled(cancelledBookings);
        }
        if(!cancelledLeads.isEmpty())
        {
            updateLeadStatusToQuotation(cancelledLeads);
        }
    }
    /**
    * Method Name  : syncChildOwner
    * Description  : Generic method to update owner of related child objects
    *                based on Booking owner change.
    *
    * Supported Objects:
    * - Payment_Schedule__c
    * - Co_Applicant__c
    *
    * Parameters:
    * @param bookingToOwnerMap - Map<BookingId, NewOwnerId>
    */
    public static void syncChildOwner(Map<Id, Id> bookingToOwnerMap) {
        
        if (bookingToOwnerMap.isEmpty()) {
            return;
        }
        //1.Co-Applicants - Master Detail
        //2.Receipt - Master Detail
        //3.Demand Raised - Master Detail
        //4.Payment Schdule - Lookup
        //5.Refund - Master Detail
        //6.Inspections - Lookup - But Owner we shoun't update here we need to share it
        //7.Ticket - Master Detail
        
        // ===== 1. Update Payment Schedules =====
        List<Payment_Schedule__c> psList = [
            SELECT Id, OwnerId, Booking__c
            FROM Payment_Schedule__c
            WHERE Booking__c IN :bookingToOwnerMap.keySet()
        ];
        
        for (Payment_Schedule__c ps : psList) {
            ps.OwnerId = bookingToOwnerMap.get(ps.Booking__c);
        }
        

        // ===== 3. DML =====
        if (!psList.isEmpty()) {
            update psList;
        }
        
        // ===== 3. Inspections — share with the new Booking Owner (Read/Write) =====
        Schema.SObjectType inspShareType = Schema.getGlobalDescribe().get('Inspection__Share');
        if (inspShareType != null) {
            List<SObject> inspShares = new List<SObject>();
            for (Inspection__c insp : [
                SELECT Id, OwnerId, Booking__c
                FROM Inspection__c
                WHERE Booking__c IN :bookingToOwnerMap.keySet()
            ]) {
                Id newOwnerId = bookingToOwnerMap.get(insp.Booking__c);
                if (newOwnerId == null) continue;
                if (newOwnerId == insp.OwnerId) continue;   // owner needs no share
                
                SObject s = inspShareType.newSObject();
                s.put('ParentId',      insp.Id);
                s.put('UserOrGroupId', newOwnerId);
                s.put('AccessLevel',   'Edit');             // Read/Write
                s.put('RowCause',      'Manual');
                inspShares.add(s);
            }
            
            if (!inspShares.isEmpty()) {
                Database.insert(inspShares, false);
            }
        }
   

    }

    /**
    * Method Name  : shareBookingWithCRMExecutives
    * Description  : When any of the 5 stage-specific CRM Executive lookup fields
    *                on Booking__c change, grant Read share to the newly assigned
    *                user and revoke the previously assigned user. The share is
    *                cascaded to the lookup children Payment_Schedule__c,
    *                Refund__c and Inspection__c. Master-Detail children
    *                (Co_Applicant__c, Receipt__c, Demand_Raised__c) inherit
    *                automatically and need no code.
    *
    *                The Booking Owner is always excluded from share insertion
    *                because the owner already has implicit Read/Write; inserting
    *                a Read share for the owner raises FIELD_FILTER_VALIDATION_EXCEPTION.
    */
    public static void shareBookingWithCRMExecutives(List<Booking__c> newBookingList, Map<Id, Booking__c> oldBookingMap) {
        Map<Id, Set<Id>> toShare  = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> toRevoke = new Map<Id, Set<Id>>();
    
        List<String> fields = new List<String>{
            'CRM_executive__c',
            'Agreement_CRM_Executive__c',
            'Registration_CRM_Executive__c',
            'Demands_Collections_CRM_Executive__c',
            'Possession_Handover_CRM_Executive__c',
            'Customer_Service_CRM_Executive__c',
            'Sales_User__c'
        };
    
        for (Booking__c bk : newBookingList) {
            Booking__c oldBk = (oldBookingMap != null) ? oldBookingMap.get(bk.Id) : null;

            //  Only process if any relevant field has changed
            Boolean hasChanged = (
                bk.OwnerId != oldBk.OwnerId ||
                bk.Stage__c != oldBk.Stage__c ||
                bk.CRM_executive__c != oldBk.CRM_executive__c ||
                bk.Agreement_CRM_Executive__c != oldBk.Agreement_CRM_Executive__c ||
                bk.Registration_CRM_Executive__c != oldBk.Registration_CRM_Executive__c ||
                bk.Demands_Collections_CRM_Executive__c != oldBk.Demands_Collections_CRM_Executive__c ||
                bk.Possession_Handover_CRM_Executive__c != oldBk.Possession_Handover_CRM_Executive__c ||
                bk.Customer_Service_CRM_Executive__c != oldBk.Customer_Service_CRM_Executive__c ||
                bk.Sales_User__c != oldBk.Sales_User__c
            );
    
            if (!hasChanged) continue;
    
            // Issue 2 Fix — Exclude both old and new OwnerId from stillAssigned
            Set<Id> stillAssigned = new Set<Id>();
            for (String f : fields) {
                Id v = (Id) bk.get(f);
                if (v != null && v != bk.OwnerId) {
                    stillAssigned.add(v);
                }
            }
    
            for (String f : fields) {
                Id newVal = (Id) bk.get(f);
                Id oldVal = (Id) oldBk.get(f);

                if (oldVal != null && !stillAssigned.contains(oldVal) && oldVal != bk.OwnerId) {
                    if (!toRevoke.containsKey(bk.Id)) {
                        toRevoke.put(bk.Id, new Set<Id>());
                    }
                    toRevoke.get(bk.Id).add(oldVal);
                }
    
                if (newVal != null && newVal != bk.OwnerId) {
                    if (!toShare.containsKey(bk.Id)) {
                        toShare.put(bk.Id, new Set<Id>());
                    }
                    toShare.get(bk.Id).add(newVal);
                }
            }
        }
    
        if (toShare.isEmpty() && toRevoke.isEmpty()) return;
    
        // ──────────────────────────────────────────
        // REVOKE
        // ──────────────────────────────────────────
        if (!toRevoke.isEmpty()) {
            List<Booking__Share> existing = [
                SELECT Id, ParentId, UserOrGroupId
                FROM Booking__Share
                WHERE ParentId IN :toRevoke.keySet()
                  AND RowCause = 'Manual'
            ];
    
            List<Booking__Share> toDelete = new List<Booking__Share>();
            for (Booking__Share s : existing) {
                Set<Id> usersToRevoke = toRevoke.get(s.ParentId);
                if (usersToRevoke != null && usersToRevoke.contains(s.UserOrGroupId)) {
                    toDelete.add(s);
                }
            }
    
            if (!toDelete.isEmpty()) {
                Database.delete(toDelete, false);
            }
        }
    
        // ──────────────────────────────────────────
        // SHARE
        // ──────────────────────────────────────────
        if (!toShare.isEmpty()) {
    
            //  Issue 3 Fix — Dedup against existing share records before insert
            Set<String> existingKeys = new Set<String>();
            for (Booking__Share ex : [
                SELECT ParentId, UserOrGroupId
                FROM Booking__Share
                WHERE ParentId IN :toShare.keySet()
                  AND RowCause = 'Manual'
            ]) {
                existingKeys.add(ex.ParentId + '_' + ex.UserOrGroupId);
            }
    
            List<Booking__Share> toInsert = new List<Booking__Share>();
            for (Id bookingId : toShare.keySet()) {
                for (Id userId : toShare.get(bookingId)) {
                    String key = bookingId + '_' + userId;
                    if (!existingKeys.contains(key)) {
                        Booking__Share s       = new Booking__Share();
                        s.ParentId             = bookingId;
                        s.UserOrGroupId        = userId;
                        s.AccessLevel          = 'Read';
                        s.RowCause             = Schema.Booking__Share.RowCause.Manual;
                        toInsert.add(s);
                    }
                }
            }
    
            if (!toInsert.isEmpty()) {
                Database.insert(toInsert, false);
            }
        }
    
        // ──────────────────────────────────────────
        // CASCADE TO CHILDREN
        // ──────────────────────────────────────────
        Set<Id> bookingIdsAll = new Set<Id>();
        bookingIdsAll.addAll(toShare.keySet());
        bookingIdsAll.addAll(toRevoke.keySet());
    
        if (!bookingIdsAll.isEmpty()) {
            cascadeShareToChildren(bookingIdsAll, toShare, toRevoke);
        }
    }

    /**
    * Cascade Booking-level share/revoke to its Lookup child records:
    * Payment_Schedule__c, Refund__c, Inspection__c. Master-Detail children
    * inherit access from the parent Booking share automatically.
    */
    private static void cascadeShareToChildren(Set<Id> bookingIds,Map<Id, Set<Id>> toShare,Map<Id, Set<Id>> toRevoke) {
        if (bookingIds == null || bookingIds.isEmpty()) return;

        Map<Id, List<Id>> bookingToPS   = new Map<Id, List<Id>>();
        Map<Id, List<Id>> bookingToRef  = new Map<Id, List<Id>>();
        Map<Id, List<Id>> bookingToInsp = new Map<Id, List<Id>>();

        for (Payment_Schedule__c c : [
            SELECT Id, Booking__c FROM Payment_Schedule__c
            WHERE Booking__c IN :bookingIds
        ]) {
            if (!bookingToPS.containsKey(c.Booking__c)) bookingToPS.put(c.Booking__c, new List<Id>());
            bookingToPS.get(c.Booking__c).add(c.Id);
        }
        for (Refund__c c : [
            SELECT Id, Booking__c FROM Refund__c
            WHERE Booking__c IN :bookingIds
        ]) {
            if (!bookingToRef.containsKey(c.Booking__c)) bookingToRef.put(c.Booking__c, new List<Id>());
            bookingToRef.get(c.Booking__c).add(c.Id);
        }
        for (Inspection__c c : [
            SELECT Id, Booking__c FROM Inspection__c
            WHERE Booking__c IN :bookingIds
        ]) {
            if (!bookingToInsp.containsKey(c.Booking__c)) bookingToInsp.put(c.Booking__c, new List<Id>());
            bookingToInsp.get(c.Booking__c).add(c.Id);
        }

        insertChildShares('Payment_Schedule__Share', bookingToPS,   toShare);
        insertChildShares('Refund__Share',           bookingToRef,  toShare);
        insertChildShares('Inspection__Share',       bookingToInsp, toShare);

        deleteChildShares('Payment_Schedule__Share', bookingToPS,   toRevoke);
        deleteChildShares('Refund__Share',           bookingToRef,  toRevoke);
        deleteChildShares('Inspection__Share',       bookingToInsp, toRevoke);
    }

    private static void insertChildShares(String shareObjectName,Map<Id, List<Id>> bookingToChildIds,Map<Id, Set<Id>> toShare) {
        if (toShare == null || toShare.isEmpty() || bookingToChildIds.isEmpty()) return;
        Schema.SObjectType shareType = Schema.getGlobalDescribe().get(shareObjectName);
        if (shareType == null) return;

        List<SObject> shares = new List<SObject>();
        for (Id bookingId : toShare.keySet()) {
            List<Id> childIds = bookingToChildIds.get(bookingId);
            if (childIds == null || childIds.isEmpty()) continue;
            for (Id childId : childIds) {
                for (Id userId : toShare.get(bookingId)) {
                    SObject s = shareType.newSObject();
                    s.put('ParentId', childId);
                    s.put('UserOrGroupId', userId);
                    s.put('AccessLevel', 'Read');
                    s.put('RowCause', 'Manual');
                    shares.add(s);
                }
            }
        }
        if (!shares.isEmpty()) {
            Database.insert(shares, false);
        }
    }

    private static void deleteChildShares(String shareObjectName,Map<Id, List<Id>> bookingToChildIds,Map<Id, Set<Id>> toRevoke) {
        if (toRevoke == null || toRevoke.isEmpty() || bookingToChildIds.isEmpty()) return;
        Schema.SObjectType shareType = Schema.getGlobalDescribe().get(shareObjectName);
        if (shareType == null) return;

        Set<Id> childIds = new Set<Id>();
        Map<Id, Set<Id>> childToRevokeUsers = new Map<Id, Set<Id>>();
        for (Id bookingId : toRevoke.keySet()) {
            List<Id> kids = bookingToChildIds.get(bookingId);
            if (kids == null) continue;
            for (Id k : kids) {
                childIds.add(k);
                childToRevokeUsers.put(k, toRevoke.get(bookingId));
            }
        }
        if (childIds.isEmpty()) return;

        String soql = 'SELECT Id, ParentId, UserOrGroupId FROM ' + shareObjectName +
                      ' WHERE ParentId IN :childIds AND RowCause = \'Manual\'';
        List<SObject> existing = Database.query(soql);
        List<SObject> toDelete = new List<SObject>();
        for (SObject s : existing) {
            Id parentId = (Id) s.get('ParentId');
            Id userId   = (Id) s.get('UserOrGroupId');
            Set<Id> users = childToRevokeUsers.get(parentId);
            if (users != null && users.contains(userId)) {
                toDelete.add(s);
            }
        }
        if (!toDelete.isEmpty()) {
            Database.delete(toDelete, false);
        }
    }

    /**
    * Method Name  : getNotificationTypeId
    * Description  : Fetches Custom Notification Type Id for
    *                Booking Assignment Notification.
    *
    * Returns:
    * @return String - CustomNotificationType Id
    */
    private static String getNotificationTypeId() {
        
        CustomNotificationType nt = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = 'Booking_Assignment_Notification'
            LIMIT 1
        ];
        
        return nt.Id;
    }
    public static void sendCancellationRequestEmail(List<Booking__c> newBookingList, Map<Id, Booking__c> oldBookingMap) {
        Set<Id> bookingIds = new Set<Id>();
        
        for (Booking__c bk : newBookingList) {
            Booking__c oldBk = oldBookingMap.get(bk.Id);
            
            if (
                oldBk != null &&
                bk.Is_Cancellation_Requested_by_Executive__c == true &&
                oldBk.Is_Cancellation_Requested_by_Executive__c != true
            ) {
                bookingIds.add(bk.Id);
            }
        }
        
        if (bookingIds.isEmpty()) {
            return;
        }
        
        List<Booking__c> bookingList = [
            SELECT Id,
            Name,
            First_Applicant_Name__c,
            CRM_Head__c,
            CRM_Head__r.Email,
            CRM_Manager__c,
            CRM_Manager__r.Email,
            Project_Sales_Head__c,
            Project_Sales_Head__r.Email,
            Sales_User__c,
            Sales_User__r.Email,
            Sales_Head__c,
            Sales_Head__r.Email
            FROM Booking__c
            WHERE Id IN :bookingIds
        ];
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        for (Booking__c bk : bookingList) {
            Set<String> toAddressSet = new Set<String>();
            
            if (bk.CRM_Head__r != null && String.isNotBlank(bk.CRM_Head__r.Email)) {
                toAddressSet.add(bk.CRM_Head__r.Email);
            }
            if (bk.CRM_Manager__r != null && String.isNotBlank(bk.CRM_Manager__r.Email)) {
                toAddressSet.add(bk.CRM_Manager__r.Email);
            }
            if (bk.Project_Sales_Head__r != null && String.isNotBlank(bk.Project_Sales_Head__r.Email)) {
                toAddressSet.add(bk.Project_Sales_Head__r.Email);
            }
            if (bk.Sales_User__r != null && String.isNotBlank(bk.Sales_User__r.Email)) {
                toAddressSet.add(bk.Sales_User__r.Email);
            }
            if (bk.Sales_Head__r != null && String.isNotBlank(bk.Sales_Head__r.Email)) {
                toAddressSet.add(bk.Sales_Head__r.Email);
            }
            
            // Getting the CC Emails from Custom Label
            String ccEmailLabel = Label.CCEmailIds; // e.g., "durgaprasad@fingertipplus.com,durgaprasadrgukt99@gmail.com"
            
            if(String.isNotBlank(ccEmailLabel)) {
                List<String> labelEmails = ccEmailLabel.split(',');
                for(String email : labelEmails) {
                    toAddressSet.add(email.trim());
                }
            }
            
            if (toAddressSet.isEmpty()) {
                continue;
            }
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>(toAddressSet));
            mail.setSubject('Booking Cancellation Request - ' + bk.Name);
            mail.setSaveAsActivity(true);
            mail.setWhatId(bk.Id);
            
            
            
            String body =
                'Dear Team,\n\n' +
                'A booking cancellation request has been raised.\n\n' +
                'Booking Id : ' + bk.Name + '\n' +
                'Customer Name : ' + (bk.First_Applicant_Name__c != null ? bk.First_Applicant_Name__c : '') + '\n\n' +
                'Please review and take the necessary action.\n\n' +
                'Regards,\n' +
                'CRM System';
            
            mail.setPlainTextBody(body);
            emailList.add(mail);
        }
        
        if (!emailList.isEmpty()) {
            Messaging.sendEmail(emailList);
        }
    }
    public static void sendCancellationApprovedEmail(List<Booking__c> newBookingList, Map<Id, Booking__c> oldBookingMap) {
        Set<Id> bookingIds = new Set<Id>();
        
        for (Booking__c bk : newBookingList) {
            Booking__c oldBk = oldBookingMap.get(bk.Id);
            
            if (
                oldBk != null &&
                oldBk.Stage__c != bk.Stage__c &&
                bk.Stage__c == 'Cancellation'
            ) {
                bookingIds.add(bk.Id);
            }
        }
        
        if (bookingIds.isEmpty()) {
            return;
        }
        
        List<Booking__c> bookingList = [
            SELECT Id,
            Name,
            Finance_Lead__c,
            Finance_Lead__r.Email
            FROM Booking__c
            WHERE Id IN :bookingIds
        ];
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        for (Booking__c bk : bookingList) {
            if (bk.Finance_Lead__r == null || String.isBlank(bk.Finance_Lead__r.Email)) {
                continue;
            }
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ bk.Finance_Lead__r.Email });
            mail.setSubject('Cancellation Has Been Approved for the Booking - ' + bk.Name);
            
            String body =
                'Dear Finance Team,\n\n' +
                'Cancellation has been approved for the booking - ' + bk.Name + '.\n\n' +
                'Please proceed with refund process.\n\n' +
                'Regards,\n' +
                'CRM System';
            
            mail.setPlainTextBody(body);
            emailList.add(mail);
        }
        
        if (!emailList.isEmpty()) {
            Messaging.sendEmail(emailList);
        }
    }
    public static void updatePlotAvailability(Set<Id> unitSet){
        // Step 1: Update Plot status to Available
        List<Plot__c> plotList = [
            SELECT Id, Name, Status__c, Project_Name__c, Project__c
            FROM Plot__c
            WHERE Id IN :unitSet
        ];
        
        for(Plot__c p : plotList)
        {
            p.Status__c = 'Available';
        }
        
        if(!plotList.isEmpty())
        {
            update plotList;
        }
        
        // Step 2: Collect all Project Ids from the plots
        Set<String> projectIds = new Set<String>();
        for(Plot__c p : plotList)
        {
            if(p.Project_Name__c != null)
            {
                projectIds.add(p.Project_Name__c);
            }
        }
        
        if(projectIds.isEmpty()) return;
        
        // Step 3: Query Round Robin for those projects
        List<Round_Robin__c> RRqueList = [
            SELECT Id, Project_Assigned__c, Project_Head__c,
            (
                SELECT Name, User__c
                FROM Round_Robin_Members__r
                WHERE Active__c = true
                AND User__r.IsActive = true
                AND User_Profile__c = 'Sales'
            )
            FROM Round_Robin__c
            WHERE Project_Assigned__c IN :projectIds
            AND Active__c = true
        ];
        
        // Step 4: Build a Map of Project => List of RR Sales Users
        Map<String, List<Round_Robin_Member__c>> projectToMembersMap = new Map<String, List<Round_Robin_Member__c>>();
        for(Round_Robin__c rr : RRqueList)
        {
            if(rr.Round_Robin_Members__r.size() > 0)
            {
                projectToMembersMap.put(rr.Project_Assigned__c, rr.Round_Robin_Members__r);
            }
        }
        
        // Step 5: Get the Custom Notification Type
        CustomNotificationType notifType = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = 'Plot_Availability_Notification'
            LIMIT 1
        ];
        
        // Step 6: Send notification per Plot → only to RR members of that project
        for(Plot__c p : plotList)
        {
            List<Round_Robin_Member__c> members = projectToMembersMap.get(p.Project_Name__c);
            
            if(members == null || members.isEmpty()) continue;
            
            // Build recipient Set for this plot's project RR members
            Set<String> recipientIds = new Set<String>();
            for(Round_Robin_Member__c member : members)
            {
                if(member.User__c != null)
                {
                    recipientIds.add(member.User__c);
                }
            }
            
            if(recipientIds.isEmpty()) continue;
            
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setNotificationTypeId(notifType.Id);
            notification.setTargetId(p.Id);
            notification.setTitle('Unit Now Available – ' + p.Project_Name__c);
            notification.setBody('Unit "' + p.Name + '" in Project "' + p.Project_Name__c + '" has been marked as Available.');
            notification.send(recipientIds);
        }
    }
    
    public static void updatePlotStatusToSold(Set<Id> unitSetToUpdateSoldStatus){
        // Step 1: Update Plot status to Available
        List<Plot__c> plotList = [
            SELECT Id, Name, Status__c, Project_Name__c, Project__c
            FROM Plot__c
            WHERE Id IN :unitSetToUpdateSoldStatus
        ];
        
        for(Plot__c p : plotList)
        {
            p.Status__c = 'Sold';
        }
        
        if(!plotList.isEmpty())
        {
            update plotList;
        }
        
       
    }
    public static void updateLeadStatusToQuotation(Set<Id> cancelledLeads){
        // Step 1: Update Plot status to Available
        List<Lead> leadList = [
            SELECT Id, Lead_Status__c
            FROM Lead
            WHERE Id IN :cancelledLeads
        ];
        
        for(Lead ld : leadList)
        {
            ld.Lead_Status__c = 'Quotation';
        }
        
        if(!leadList.isEmpty())
        {
            update leadList;
        }
        
        
    }
    public static void updateReceiptStatusCancelled(Set<Id> bookingIds){
        // Step 1: Update Plot status to Available
        List<Receipt__c> receiptList = [
            SELECT Id,Approval_status__c
            FROM Receipt__c
            WHERE Booking__c IN :bookingIds
        ];
        
        for(Receipt__c p : receiptList)
        {
            p.Approval_status__c = 'Cancelled';
        }
        
        if(!receiptList.isEmpty())
        {
            update receiptList;
        }
        
       
    }

}