public without sharing class  UserAvailabilityController {
    
    @AuraEnabled
    public static List<User> getAllUsers(string profile){
        system.debug('profile'+profile);
        Id UserId = UserInfo.getUserId();
        User curUser = [select id,name,Profile.name from user where id=:UserInfo.getUserId() ];
        if(curUser.profile.name == 'System Administrator' || curUser.profile.name == 'Management User'  )
        {
            return [SELECT Id,Name,Username,Profile.Name,Availability__c,is_working__c,Manager.Name,Working__c 
                    FROM User Where isActive = true and Profile.Name=:profile ORDER BY NAME ASC];
        }
        else
        {
            set<Id> UserIds = RoleHeirarchyUtility.getRoleSubordinateUsers(UserId);
            return [SELECT Id,Name,Username,Profile.Name,Availability__c,is_working__c,Manager.Name,Working__c 
                    FROM User Where isActive = true and Profile.Name=:profile AND Id IN:UserIds  ORDER BY NAME ASC];
        }
        
      
    }
    
    @AuraEnabled 
    public static List<User> getMyUsers(string profile){
        User curUser = [select id,name,Profile.name from user where id=:UserInfo.getUserId() ];
        if(curUser.profile.name == 'Presales Head' || curUser.profile.name == 'Sales Head'
           || curUser.profile.name == 'Site visit Head' 
           || curUser.Profile.Name == 'Recovery Head' ){
               return [SELECT Id,Name,Username,Profile.Name,Availability__c,
                       Manager.Name,Working__c,is_working__c  FROM User WHERE
                       (Manager.ManagerId = :UserInfo.getUserId() or ManagerId=:UserInfo.getUserId())
                       and isActive = true and Profile.Name=:profile ORDER BY NAME ASC];
           }
        else{
            return [SELECT Id,Name,Username,Profile.Name,Availability__c,
                    Manager.Name,Working__c,is_working__c
                    FROM User WHERE ManagerId = :UserInfo.getUserId() and isActive = true 
                    and Profile.Name=:profile ORDER BY NAME ASC];
        }
    }
    
    @AuraEnabled
    public static void updateUser(String selUserId,User selUser){  
        update selUser;  
    }
    @AuraEnabled
    public static void updateUser2(User selUser){  
        update selUser;  
    }
}