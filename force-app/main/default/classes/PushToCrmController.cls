public class PushToCrmController {
    @AuraEnabled
    public static String moveToCRM(String bookingId,string comments){
        try {
            
            Booking__c bk = [SELECT Id, Name,CRM_Manager__c, Push_To_CRM__c,OwnerId, Status__c,Booking_Form_Sent__c,
                             Assigned_by__c, Project__c,Quote__r.OwnerId FROM Booking__c WHERE Id = :bookingId];
    
            
            if(bk != null && bk.Project__c != null) {
   				bk.Push_to_CRM_Comments__c = comments;
                bk.Push_To_CRM__c = true;
                update bk;
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(bk.Id);
                req.setProcessDefinitionNameOrId('Booking_Push_to_CRM_Approval_Process');
                req.setSkipEntryCriteria(false);
                
                Approval.ProcessResult result = Approval.process(req);
                
                if (!result.isSuccess()) {
                    for (Database.Error err : result.getErrors()) {
                        System.debug('Approval submission failed: ' + err.getMessage());
                    }
                    throw new AuraHandledException('Approval submission failed. Please check setup.');
                }
                return bk.Id;
            }
        }
        catch(Exception e) {
            throw new AuraHandledException('Error updating booking: ' + e.getMessage());
        }
        return null; 
    }
    
   /* public static String returnCRMUser(List<Booking__c> booklist){
        
        List<Round_Robin__c> RRAvaliablequeList=[Select id,Project_Assigned__c,
                                                 (select Name,User__c from  Round_Robin_Members__r 
                                                  where Active__c =true and User_Type__c='CRM'
                                                  order by Last_Assigned_time_user__c,createddate asc nulls first limit 1)
                                                 from Round_Robin__c where Project_Assigned__c != NULL and Active__c = true ];
        Map<String,Round_Robin__c> MapRobin = new Map<String,Round_Robin__c>();
        for(Round_Robin__c rb : RRAvaliablequeList){
            
            MapRobin.put(rb.Project_Assigned__c,rb);
        }
        List<User> userlist = new List<User>();
        String bkuser;
        for(Booking__c bb : booklist){
            Round_Robin__c rr = MapRobin.get(bb.Project__c);
            if (rr != null && rr.Round_Robin_Members__r != null && !rr.Round_Robin_Members__r.isEmpty()) {
                //  bb.OwnerId = rr.Round_Robin_Members__r[0].User__c;
                bkuser=rr.Round_Robin_Members__r[0].User__c;
                
                User newuser = new User();
                newuser.id = rr.Round_Robin_Members__r[0].User__c;
                newuser.LastAssignmentTime1__c = system.now().getTime();
                userlist.add(newuser);
            }
        }
        if(userlist.size()>0){
            update userlist;
        }
        system.debug(bkuser);
        return bkuser;
    }
    */
}