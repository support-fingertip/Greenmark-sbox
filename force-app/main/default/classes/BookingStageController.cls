public with sharing class BookingStageController {
    
    @AuraEnabled
    public static Map<String, Object> getInitData(Id bookingId) {
        try {
            Map<String, Object> result = new Map<String, Object>();
            
            // Query the booking record (added RecordTypeId)
            Booking__c book = [
                SELECT Id, Stage__c, OwnerId, Booking_Summary__c, RecordTypeId
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];
            
            //  Using ConnectApi to get picklist values filtered by Record Type
            ConnectApi.PicklistValuesCollection picklistValues = 
                ConnectApi.RecordUi.getPicklistValuesByRecordType('Booking__c', book.RecordTypeId);
            
            //  Get only Stage__c values for this Record Type
            List<String> pickValues = new List<String>();
            for (ConnectApi.PicklistValue p : picklistValues.picklistFieldValues.get('Stage__c').values) {
                pickValues.add(p.label);
            }
            
            // Get only active CRM Executive users
            List<User> userList = [
                SELECT Id, Name
                FROM User
                WHERE Profile.Name = 'CRM Executive'
                AND IsActive = true
                ORDER BY Name
            ];
            
            result.put('booking', book);
            result.put('stages', pickValues);
            result.put('users', userList);
            
            return result;
            
        } catch(Exception e) {
            throw new AuraHandledException('Error loading booking data: ' + e.getMessage());
        }
    }
    /**
* Update booking record with new owner, stage, and comments
* @param bookingId The ID of the booking record
     * @param newOwnerId The new owner user ID
     * @param newStage The new stage value
     * @param newNote The comment to add to booking summary
     */
    @AuraEnabled
    public static void updateBooking(
        Id bookingId,
        Id newOwnerId,
        String newStage,
        String newNote
    ) {
        try {
            // Validate inputs
            if(String.isBlank(bookingId)) {
                throw new AuraHandledException('Booking ID is required');
            }
            if(String.isBlank(newOwnerId)) {
                throw new AuraHandledException('Owner ID is required');
            }
            if(String.isBlank(newStage)) {
                throw new AuraHandledException('Stage is required');
            }
            
            // Query the booking record
            Booking__c bookingRec = [
                SELECT Id, Stage__c, OwnerId, Booking_Summary__c
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];
            
            // Update owner and stage
            if(bookingRec.OwnerId != newOwnerId ||  bookingRec.Stage__c !=newStage )
            {
                bookingRec.Stage_Status__c = 'In Progress';
                bookingRec.Move_to_Next_Stage__c = false;
            }
            bookingRec.OwnerId = newOwnerId;
            bookingRec.Stage__c = newStage;

            // Stamp the new owner onto the stage-specific CRM Executive lookup
            if (newStage == 'Agreement') {
                bookingRec.Agreement_CRM_Executive__c = newOwnerId;
            } else if (newStage == 'Land Registration' || newStage == 'Registration') {
                bookingRec.Registration_CRM_Executive__c = newOwnerId;
            } else if (newStage == 'Demands & Progressive Collections') {
                bookingRec.Demands_Collections_CRM_Executive__c = newOwnerId;
            } else if (newStage == 'Possession / Handover') {
                bookingRec.Possession_Handover_CRM_Executive__c = newOwnerId;
            } else if (newStage == 'Customer Service & Complaints') {
                bookingRec.Customer_Service_CRM_Executive__c = newOwnerId;
            }


            // Format and append the comment
            Datetime dt = Datetime.now();
            String strTimeInAMorPM = dt.format('dd-MM-yy HH:mm a');
            
            User currentUser = [
                SELECT Id, Name 
                FROM User 
                WHERE Id = :UserInfo.getUserId()
                LIMIT 1
            ];
            
            if(newNote != null)
            {
                // Calculate note count
                Integer noteCount = 1;
                if (String.isNotBlank(bookingRec.Booking_Summary__c)) {
                    List<String> notes = bookingRec.Booking_Summary__c.split('\n');
                    noteCount = notes.size() + 1;
                } else {
                    bookingRec.Booking_Summary__c = '';
                }
                
                
                // Append new comment
                String newComment = 'Stage Summary ' + noteCount + ': ' + 
                    currentUser.Name + ' [' + 
                    strTimeInAMorPM + ']: ' + newNote;
                
                if(String.isNotBlank(bookingRec.Booking_Summary__c)) {
                    bookingRec.Booking_Summary__c += '\n' + newComment;
                } else {
                    bookingRec.Booking_Summary__c = newComment;
                }
            }
            
            // Update the record
            update bookingRec;
            
        } catch(Exception e) {
               system.debug('Error updating booking: ' + e.getMessage());
            throw new AuraHandledException('Error updating booking: ' + e.getMessage());
         
        }
    }
}