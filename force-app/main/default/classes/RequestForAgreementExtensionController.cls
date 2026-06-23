public class RequestForAgreementExtensionController {

    @AuraEnabled
    public static String submitforextensionApproval(Id bookingId, String newNote,Decimal extensionDays) {

        try {

            //  Validate Input
            if(bookingId == null){
                throw new AuraHandledException('Booking Id is required.');
            }

            // Query Booking
            Booking__c bookingRec = [
                SELECT Id, Stage__c, OwnerId, Booking_Summary__c
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];

            // Append Summary Note
            if(String.isNotBlank(newNote)){
                
                Datetime dt = Datetime.now();
                String formattedTime = dt.format('dd-MM-yy hh:mm a');
                
                User currentUser = [
                    SELECT Name
                    FROM User
                    WHERE Id = :UserInfo.getUserId()
                    LIMIT 1
                ];
                
                Integer noteCount = 1;
                
                if(String.isNotBlank(bookingRec.Booking_Summary__c)){
                    List<String> notes = bookingRec.Booking_Summary__c.split('\n');
                    noteCount = notes.size() + 1;
                }
                
                String newComment =
                    'Summary ' + noteCount + ': ' +
                    currentUser.Name + ' [' +
                    formattedTime + ']: ' + newNote;
                
                if(String.isNotBlank(bookingRec.Booking_Summary__c)){
                    bookingRec.Booking_Summary__c += '\n' + newComment;
                } else {
                    bookingRec.Booking_Summary__c = newComment;
                }
            }
            bookingRec.Time_Extension_Requested__c = true;
            bookingRec.Extension_Days__c = extensionDays;
            update bookingRec;

            // Submit For Approval
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments(newNote);
            req.setProcessDefinitionNameOrId('Agreement_Time_Extension_Approval');
            req.setObjectId(bookingId);

            Approval.ProcessResult result = Approval.process(req);

            if(!result.isSuccess()){
                throw new AuraHandledException('Approval submission failed.');
            }

            return 'Submitted for approval successfully.';

        } catch (Exception e) {
            throw new AuraHandledException(
                'Error submitting for approval: ' + e.getMessage()
            );
        }
    }
}