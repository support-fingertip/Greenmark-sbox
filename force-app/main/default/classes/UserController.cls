public with sharing class UserController {
    
    @AuraEnabled
    public static List<User> getUsers() {
        List<User> users = [SELECT Id, Name, Profile.Name FROM User where isActive = true and profile.name !=null];
        return users;
    }
    @AuraEnabled
    public static void UpdateUser(Id userID,Id recordId,boolean ischcek) {
        Lead ldlst = [SELECT Id, Name, OwnerId,Pre_sales_user__c,IsPushed__c,Pushed_By__c,Pushed_On__c,Lead_status__c,Lead_source__c FROM Lead where id =:recordId];
        if(ischcek == false){
                ldlst.OwnerId = userID;
            //ldlst.Pre_sales_user__c = null;
              
        }
        if(ldlst.Lead_source__c=='Walk-In'){
           ldlst.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
            ldlst.Pre_sales_user__c=userID;
        }
        if(ischcek == true){
            //ldlst.Pre_sales_user__c =null;
            ldlst.OwnerId = userID;
            ldlst.Lead_status__c = 'Qualified';
            ldlst.Pushed_On__c = system.now();
            ldlst.Pushed_By__c = UserInfo.getUserId();
            ldlst.IsPushed__c=true;
            ldlst.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        }
        update ldlst;
    }
}