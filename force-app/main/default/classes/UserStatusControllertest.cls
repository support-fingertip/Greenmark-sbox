@isTest
public class UserStatusControllertest {
    public static testMethod void userstatustest(){
        //test.startTest();
        Profile p1 = [SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];
        
        User u1 = new User(
            ProfileId = p1.Id,
            LastName = 'RH23',
            Email = 'RH@gm1ail11.com',
            Username = 'RH@1gmail111.com' + System.currentTimeMillis(),
            CompanyName = 'RH1',
            Title = 'titletitl1e',
            Alias = 'lokma1n',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Availability__c = true,
            IsActive = true,
            is_working__c = true
        );
        insert u1;

        UserStatusController.getUserRec();
        User u = [SELECT Id,Name,ManagerId,Availability__c FROM User where Profile.Name='Sales'limit 1];
        
        UserStatusController.updateUser(u,'test');
        u.Availability__c=false;
        update u;
        UserStatusController.updateUser(u,'test');
        //test.stoptest();
    }
}