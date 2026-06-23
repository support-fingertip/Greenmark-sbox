public class UserStatusController {
    
    @AuraEnabled
    public static User getUserRec(){
        return [SELECT Id,Name,Availability__c FROM User Where id =:UserInfo.getUserId()];
    }
    
    @AuraEnabled
    public static void updateUser(User ulist,String reasone){  
        System.debug('===========>'+reasone);
        //createDailyLog(ulist,reasone);   
        update ulist;  
        system.debug('list'+ulist);
        
    }
}