public class BookingCancellationRequestController {
    @AuraEnabled
    public static void cancelBooking(Id bookingId) {
        Booking__c bk = [SELECT Id,Name, Is_Cancellation_Requested_by_Executive__c,CRM_Manager__c
                         FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        bk.Is_Cancellation_Requested_by_Executive__c = true;
        update bk;
        // Send notification to CRM Manager
        sendCancellationNotification(bk);
        
    }
    
    @AuraEnabled
    public static boolean bookingChecking(Id bookingId) {
        Booking__c bk = [SELECT Id, Is_Cancellation_Requested_by_Executive__c 
                           FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        
        boolean isCancelled = false;
        
        if(bk.Is_Cancellation_Requested_by_Executive__c) {
               isCancelled = true;
           }
        
        return isCancelled;
    }
    
    /**
* Sends a notification to the CRM Manager about the booking cancellation request
* @param booking The booking record that was cancelled
*/
    private static void sendCancellationNotification(Booking__c booking) {
        if (booking.CRM_Manager__c == null) {
            return; // Exit if no CRM Manager is assigned
        }
        
        // Get current user details
        User currentUser = [SELECT Id, Name, Email, Username 
                            FROM User 
                            WHERE Id = :UserInfo.getUserId() 
                            LIMIT 1];
        
        // Create custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        
        // Set notification details
        notification.setTitle('Booking Cancellation Request');
        notification.setBody('Booking ID: ' + booking.Name + 
                             'has been requested for Cancellation by ' + currentUser.Name );
        
        // Set the target ID (the booking record)
        notification.setTargetId(booking.Id);
        
        // Get the custom notification type ID
        CustomNotificationType notificationType = 
            [SELECT Id 
             FROM CustomNotificationType 
             WHERE DeveloperName = 'Booking_Cancellation_Approval_Notification' 
             LIMIT 1];
        
        notification.setNotificationTypeId(notificationType.Id);
        
        try {
            if(booking.CRM_Manager__c != null)
            {
                // Send notification to CRM Manager
                notification.send(new Set<String>{booking.CRM_Manager__c});
            }
            
        } catch (Exception e) {
            System.debug('Error sending notification: ' + e.getMessage());
            // You might want to log this error or handle it differently
        }
    }
}