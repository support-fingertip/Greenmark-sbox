public class BookingSummaryController {
    @AuraEnabled
    public static void updateLastNote(String bookingId, String newNote) {
        Booking__c booking = [SELECT Id, Booking_Summary__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        User us = [select id,name from User where id =: userInfo.getUserId()];
        Datetime dt = Datetime.now();
        Timezone tz = Timezone.getTimeZone('Asia/Kolkata');
        String strTimeInAMorPM = dt.format('dd-MM-yy HH:mm a');
        
        Integer noteCount = 1;
        if (booking.Booking_Summary__c == null) {
            booking.Booking_Summary__c = '';
        } else if (!booking.Booking_Summary__c.trim().equals('')) {
            List<String> notes = booking.Booking_Summary__c.split('\n');
            noteCount = notes.size() + 1;
        }
        booking.Booking_Summary__c += '\nBooking Summary ' + noteCount + ': ' + us.Name + ' [' + strTimeInAMorPM + ']: ' + newNote;
        
        update booking;
    }
    
    
    @AuraEnabled
    public static List<String> fetchLeadLastNotes(String bookingId) {
        Booking__c booking = [SELECT Id, Booking_Summary__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        List<String> lastNotes = new List<String>();
        
        if (booking != null && booking.Booking_Summary__c != null) {
            lastNotes = booking.Booking_Summary__c.split('\n');
            
            // Filter out empty strings or null values
            List<String> filteredNotes = new List<String>();
            for (String note : lastNotes) {
                if (note != null && note != '') {
                    filteredNotes.add(note);
                }
            }
            
            lastNotes = filteredNotes;
            // Reverse the list to get notes in descending order
            List<String> reversedNotes = new List<String>();
            for (Integer i = lastNotes.size() - 1; i >= 0; i--) {
                reversedNotes.add(lastNotes[i]);
            }
            lastNotes = reversedNotes;
            
        }
        
        return lastNotes;
    }
}