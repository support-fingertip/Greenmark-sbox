public class MarkBookingStageCompletedController {
    
    @AuraEnabled
    public static void markStageAsCompleted(String bookingId, String newNote) {
        try {
            Booking__c bookingRec = [
                SELECT Id, Name, Booking_Summary__c, CRM_Manager__c,Lead_Name__c, Stage__c, Stage_Status__c, Owner_Full_Name__c,Project_Type__c, Block__c,
                Block__r.Name, Block__r.Agreement_CRM_Executive__c, Block__r.Demands_Collections_CRM_Executive__c,
                Block__r.Registration_CRM_Executive__c,Block__r.Possession_Handover_CRM_Executive__c,Block__r.Customer_Service_CRM_Executive__c
                FROM Booking__c WHERE Id = :bookingId LIMIT 1
            ];
            
            User currentUser = [
                SELECT Id, Name
                FROM User
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            
            Datetime dt = Datetime.now();
            String strTimeInAMorPM = dt.format('dd-MM-yy HH:mm a');
            
            Integer noteCount = 1;
            
            if (String.isBlank(bookingRec.Booking_Summary__c)) {
                bookingRec.Booking_Summary__c = '';
            } else {
                List<String> notes = bookingRec.Booking_Summary__c.split('\n');
                noteCount = notes.size() + 1;
            }
            
            bookingRec.Booking_Summary__c +=
                '\nStage Summary ' + noteCount + ': ' +
                currentUser.Name + ' [' + strTimeInAMorPM + ']: ' + newNote;
            
            String previousStage = bookingRec.Stage__c;
            
            Stage_Progression__mdt progression = resolveProgression(
                bookingRec.Project_Type__c, bookingRec.Stage__c);
            
            // Pre-validate the next CRM Executive lookup BEFORE the completion DML
            // so we don't leave the booking at (OldStage, Completed) when we
            // already know we can't advance.
            Object nextOwnerObj = null;
            if (progression != null) {
                if (bookingRec.Block__c == null) {
                    String msg = 'Booking ' + bookingRec.Name +  ' is not linked to a Block; cannot resolve next CRM Executive.';
                    AuraHandledException ex = new AuraHandledException(msg);
                    ex.setMessage(msg);
                    throw ex;
                }
                nextOwnerObj = bookingRec.Block__r.get(progression.Block_Executive_Field_API__c);
                if (nextOwnerObj == null) {
                    String msg = progression.Next_Stage__c +' CRM Executive is not configured on Block ' + bookingRec.Block__r.Name + '. Please contact system administrator.';
                    AuraHandledException ex = new AuraHandledException(msg);
                    ex.setMessage(msg);
                    throw ex;
                }
            }
            
            Savepoint sp = Database.setSavepoint();
            try {
                // Phase A — fires stage-completion validation rules. If a rule
                // throws (e.g. required document missing), the booking stays
                // at (OldStage, In Progress) thanks to the rollback below and
                // the user sees the validation message in the Aura toast.
                bookingRec.Stage_Status__c       = 'Completed';
                bookingRec.Move_to_Next_Stage__c = true;
                update bookingRec;
                
                // Phase B — advance Stage / Owner only when a progression
                // matches. The completion validations don't re-fire because
                // Stage_Status__c is no longer 'Completed' on this DML.
                if (progression != null) {
                    bookingRec.Stage__c              = progression.Next_Stage__c;
                    bookingRec.OwnerId               = (Id) nextOwnerObj;
                    bookingRec.Stage_Status__c       = 'In Progress';
                    bookingRec.Move_to_Next_Stage__c = false;
                    String bookingFieldApi = progression.Block_Executive_Field_API__c;
                    
                    if (String.isBlank(bookingFieldApi)) {
                        String msg = 'Booking field API name is not configured.';
                        AuraHandledException ex = new AuraHandledException(msg);
                        ex.setMessage(msg);
                        throw ex;
                    }
                    
                    bookingRec.put(bookingFieldApi, (Id) nextOwnerObj);
                    update bookingRec;
                }
            } catch (AuraHandledException ahe) {
                Database.rollback(sp);
                throw ahe;
            } catch (Exception phaseEx) {
                Database.rollback(sp);
                throw phaseEx;
            }
            
            // Send Notification
            if (bookingRec.CRM_Manager__c != null) {
                String stageDescriptor = (progression != null)
                    ? previousStage + '\' completed; advanced to \'' + progression.Next_Stage__c
                    : previousStage;
                String title = bookingRec.Lead_Name__c + ' – Stage \'' + stageDescriptor + '\' by ' + bookingRec.Owner_Full_Name__c;
                String body =
                    'Booking: ' + bookingRec.Name + '\n' +
                    'Stage: ' + (bookingRec.Stage__c != null ? bookingRec.Stage__c : '') + '\n' +
                    'Customer Name: ' + (bookingRec.Lead_Name__c != null ? bookingRec.Lead_Name__c : '') + '\n' +
                    'Current CRM Executive: ' +
                    (bookingRec.Owner_Full_Name__c != null ? bookingRec.Owner_Full_Name__c : '') + '\n' +
                    'Please proceed with the next steps.';
                
                CustomNotificationService.notificationSend(title, bookingRec.Id, body, new Set<String>{ bookingRec.CRM_Manager__c }, getNotificationTypeId());
            }
        }
        catch (AuraHandledException ahe) {
            throw ahe; // re-throw as-is — message already set correctly
        }
        catch (Exception e) {
            throw new AuraHandledException('Error updating booking: ' + e.getMessage());
        }
    }
    /**
    * Resolves the next stage / owner field for a given (Project Type, Current Stage)
    * tuple from Stage_Progression__mdt. Returns null when no row matches — the
    * caller treats that as a terminal stage and skips stage/owner advancement.
    */
    private static Stage_Progression__mdt resolveProgression(String projectType, String currentStage) {
        if (String.isBlank(projectType) || String.isBlank(currentStage)) return null;
        List<Stage_Progression__mdt> rows = [
            SELECT Block_Executive_Field_API__c, Next_Stage__c
            FROM Stage_Progression__mdt
            WHERE Project_Type__c = :projectType
              AND Current_Stage__c = :currentStage
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    /**
    * Method Name  : getNotificationTypeId
    * Description  : Fetches Custom Notification Type Id for
    *                Booking Assignment Notification.
    *
    * Returns:
    * @return String - CustomNotificationType Id
    */
    public static String getNotificationTypeId() {

        CustomNotificationType nt = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = 'Booking_Assignment_Notification'
            LIMIT 1
        ];

        return nt.Id;
    }
}