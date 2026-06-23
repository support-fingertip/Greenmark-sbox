public with sharing class MarkUnqualifiedController {
    
    public static Boolean markleadUnqualified=false;
     @AuraEnabled
    public static void updateLeadComment(Id leadId, String reason, String comment) {
        if(leadId != null) {
            markleadUnqualified=true;
            Lead leadToUpdate = [SELECT Id,Unqualified_Reason__c,Last_Unqualified_At__c,Remark__c,Last_Note__c,Last_Unqualified_by__c,Mark_Unqualified__c,No_Of_Times_Unqualified__c,Lead_Assigned__c FROM Lead WHERE Id = :leadId LIMIT 1];
            leadToUpdate.Last_Unqualified_At__c = system.now();
            leadToUpdate.Last_Unqualified_by__c = UserInfo.getUserId();
            leadToUpdate.Mark_Unqualified__c = true;
            leadToUpdate.No_Of_Times_Unqualified__c += 1;
            leadToUpdate.Lead_Assigned__c = false;
            leadToUpdate.Lead_status__c = 'New';
            leadToUpdate.Unqualified_Reason__c = reason;
             if (reason == 'Other') {
        leadToUpdate.Remark__c = comment;
    } else {
        leadToUpdate.Remark__c = null;
    }
          /*  
            //For Updating the Last Note for Unqualified Reason as a Last Note
            User us = [select id,name from User where id =: userInfo.getUserId()];
        Datetime dt = Datetime.now();
        Timezone tz = Timezone.getTimeZone('Asia/Kolkata');
        //dt = dt.addSeconds(tz.getOffset(dt)/1000);
       // String strTimeInAMorPM = dt.format('MMMMM dd, yyyy hh:mm a');
		   String strTimeInAMorPM = dt.format('dd-MM-yy HH:mm a');

        Integer noteCount = 1;
        if (leadToUpdate.Last_Note__c == null) {
            leadToUpdate.Last_Note__c = '';
        } else if (!leadToUpdate.Last_Note__c.trim().equals('')) {
            List<String> notes = leadToUpdate.Last_Note__c.split('\n');
            noteCount = notes.size() + 1;
        }
            
      leadToUpdate.Last_Note__c += '\nNote ' + noteCount + ': ' + us.Name + ' [' + strTimeInAMorPM + ']: ' + commentText;
   */
       
            
            
            
            
            
            
            List<Lead_Unqualification__c> lqlst = new List<Lead_Unqualification__c>();
            
            Lead_Unqualification__c lq = new Lead_Unqualification__c();
            lq.User__c = UserInfo.getUserId();
            
            if (reason == 'Other') {
                
            lq.Unqualified_Reason__c = reason +' : '+comment;
            }
            else{
                lq.Unqualified_Reason__c = reason;
            }
            lq.Unqualified_At__c = system.now();
            lq.Lead__c =leadToUpdate.Id;
            lqlst.add(lq);
          //  leadToUpdate.Comment__c = commentText;
            if(lqlst.size()>0){
                insert lqlst;
            update leadToUpdate;
            }
        }
    }
    @AuraEnabled
public static List<String> getUnqualifiedReasons() {
    List<String> options = new List<String>();
    Schema.DescribeFieldResult fieldResult = Lead.Unqualified_Reason__c.getDescribe();
    List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
    
    for (Schema.PicklistEntry entry : picklistValues) {
        options.add(entry.getLabel());
    }
    return options;
}

}