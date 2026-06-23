public class UpdateLeadStatusController {
    
    
    
    @AuraEnabled
    public static void updateLastNoteInBulk(Map<Id,String> ldWiFb) {
        List<Lead> LeadList = new List<Lead>();
        List<Lead> ldList = [select id,name,Last_Comment__c from Lead where Id in: ldWiFb.keySet()];
        User us = [select id,name from User where id =: userInfo.getUserId()];
        for(Lead leadRecord : ldList){
            Integer noteCount = 1;
            Datetime dt = Datetime.now();
            Timezone tz = Timezone.getTimeZone('Asia/Kolkata');
            //dt = dt.addSeconds(tz.getOffset(dt)/1000);
            String strTimeInAMorPM = dt.format('MMMMM dd, yyyy hh:mm:ss a');
            if (leadRecord.Last_Comment__c == null) {
                leadRecord.Last_Comment__c = '';
            } else if (!leadRecord.Last_Comment__c.trim().equals('')) {
                List<String> notes = leadRecord.Last_Comment__c.split('\n');
                noteCount = notes.size() + 1;
            }
            
            leadRecord.Last_Comment__c += '\nNote ' + noteCount + ': ('+us.Name+')' + ' - (' + strTimeInAMorPM + ') :      ' + ldWiFb.get(leadRecord.Id);
            
            LeadList.add(leadRecord); 
            
        }
        update LeadList;
    }
    
    
    
    @AuraEnabled
    public static void updateLastNote(String leadId, String newNote, Boolean isPrimary, Boolean isSecondary, datetime followUpDate, String followUpSubject) {
        Lead leadRecord = [SELECT Id, Last_Comment__c FROM Lead WHERE Id = :leadId LIMIT 1];
        User us = [select id,name from User where id =: userInfo.getUserId()];
        Datetime dt = Datetime.now();
        Timezone tz = Timezone.getTimeZone('Asia/Kolkata');
        //dt = dt.addSeconds(tz.getOffset(dt)/1000);
        String strTimeInAMorPM = dt.format('MMMMM dd, yyyy hh:mm:ss a');
        if(isPrimary == true){
            Integer noteCount = 1;
            if (leadRecord.Last_Comment__c == null) {
                leadRecord.Last_Comment__c = '';
            } else if (!leadRecord.Last_Comment__c.trim().equals('')) {
                List<String> notes = leadRecord.Last_Comment__c.split('\n');
                noteCount = notes.size() + 1;
            }
            
            leadRecord.Last_Comment__c += '\nNote ' + noteCount + ': ('+us.Name+')' + ' - (' + strTimeInAMorPM + ') :      ' + newNote;
        }
        
        system.debug('is follou Up created');
        if(followUpDate != null){
            system.debug('is follou Up created');
            Follow_up__c fp = new Follow_up__c();
            if(followUpSubject == '' || followUpSubject == null){
                fp.Subject__c = 'call';
            }
            else{
                fp.Subject__c = followUpSubject;
            }
            fp.Scheduled_Date__c = followUpDate.addMinutes(1);
            
            fp.SLead__c = leadId;
            insert fp;
        }
        update leadRecord;
    }
    
   /* public static void addBookingComents(String bookId, String comments) {
        Booking__c book = [SELECT Id, Last_Comment__c FROM Booking__c WHERE Id = :bookId LIMIT 1];
        User us = [select id,name from User where id =: userInfo.getUserId()];
        Datetime dt = Datetime.now();
        Timezone tz = Timezone.getTimeZone('Asia/Kolkata');
        //dt = dt.addSeconds(tz.getOffset(dt)/1000);
        String strTimeInAMorPM = dt.format('MMMMM dd, yyyy hh:mm:ss a');
        Integer noteCount = 1;
        if (book.Last_Comment__c == null) {
            book.Last_Comment__c = '';
        } else if (!book.Last_Comment__c.trim().equals('')) {
            List<String> notes = book.Last_Comment__c.split('\n');
            noteCount = notes.size() + 1;
        }
        book.Last_Comment__c += '\nNote ' + noteCount + ': ('+us.Name+')' + ' - (' + strTimeInAMorPM + ') :      ' + comments;
        update book;
    }*/
    
    
    @AuraEnabled
    public static List<String> fetchLeadLastNotes(String leadId) {
        Lead leadRecord = [SELECT Id, Last_Comment__c FROM Lead WHERE Id = :leadId LIMIT 1];
        List<String> lastNotes = new List<String>();
        
        if (leadRecord != null && leadRecord.Last_Comment__c != null) {
            lastNotes = leadRecord.Last_Comment__c.split('\n');
            
            // Filter out empty strings or null values
            List<String> filteredNotes = new List<String>();
            for (String note : lastNotes) {
                if (note != null && note != '') {
                    filteredNotes.add(note);
                }
            }
            lastNotes = filteredNotes;
        }
        return lastNotes;
    }
    
}