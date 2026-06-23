public class UpdateTimeExtensionDateController {
    
    /**
    * Update booking record with new owner, stage, and comments
    * @param bookingId The ID of the booking record
    * @param newOwnerId The new owner user ID
    * @param newStage The new stage value
    * @param newNote The comment to add to booking summary
    */
    @AuraEnabled
    public static void updateBooking( Id bookingId, String newNote, Decimal extensionDays, String status) {
        try {
            
            // ================= VALIDATION =================
            if(bookingId == null) {
                throw new AuraHandledException('Booking ID is required.');
            }
            
            // ================= QUERY BOOKING =================
            Booking__c bookingRec = [
                SELECT Id, Stage__c, OwnerId, 
                Booking_Summary__c, Extension_Days__c
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];
            
            // Update extension days
            bookingRec.Extension_Days__c = extensionDays;
            
            // ================= APPEND STAGE SUMMARY =================
            if(String.isNotBlank(newNote)) {
                
                Datetime dt = Datetime.now();
                String formattedTime = dt.format('dd-MM-yy hh:mm a');
                
                User currentUser = [
                    SELECT Name 
                    FROM User 
                    WHERE Id = :UserInfo.getUserId()
                    LIMIT 1
                ];
                
                Integer noteCount = 1;
                
                if (String.isNotBlank(bookingRec.Booking_Summary__c)) {
                    List<String> notes = bookingRec.Booking_Summary__c.split('\n');
                    noteCount = notes.size() + 1;
                } else {
                    bookingRec.Booking_Summary__c = '';
                }
                
                String newComment = 
                    'Stage Summary ' + noteCount + ': ' +
                    currentUser.Name + ' [' +
                    formattedTime + ']: ' + newNote;
                
                if(String.isNotBlank(bookingRec.Booking_Summary__c)) {
                    bookingRec.Booking_Summary__c += '\n' + newComment;
                } else {
                    bookingRec.Booking_Summary__c = newComment;
                }
            }
            
            // ================= HANDLE APPROVAL PROCESS =================
            if(String.isNotBlank(status)) {
                
                List<ProcessInstanceWorkitem> workItems = [ SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkitem
                    WHERE ProcessInstance.TargetObjectId = :bookingId AND ProcessInstance.Status = 'Pending' AND ActorId = :UserInfo.getUserId() LIMIT 1
                ];

                
                if(!workItems.isEmpty()) {
                    
                    Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                    req.setWorkitemId(workItems[0].Id);
                    
                    if(status == 'Approved') {req.setAction('Approve');
                        bookingRec.Stage__c = 'Agreement Extension Approved';
                    }
                    else if(status == 'Rejected') {req.setAction('Reject');
                        bookingRec.Stage__c = 'Agreement Extension Rejected';
                    }
                    
                    req.setComments(newNote);
                    Approval.ProcessResult result = Approval.process(req);
                    if(!result.isSuccess()) {
                        throw new AuraHandledException('Approval process failed.');
                    }
                }
            }
            
            // ================= UPDATE BOOKING =================
            update bookingRec;
            
        } catch(Exception e) {
            throw new AuraHandledException(
                'Error updating booking: ' + e.getMessage()
            );
        }
    }
    
}