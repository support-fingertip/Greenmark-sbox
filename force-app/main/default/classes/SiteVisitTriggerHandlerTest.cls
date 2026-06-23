@isTest
public class SiteVisitTriggerHandlerTest {
    @isTest
    public static void siteVisit(){
         
        // Get record type IDs
        Id salesRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
       // Id preSalesRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();

        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser'+System.currentTimeMillis()+'@example.com',
            Username = 'testuser'+System.currentTimeMillis()+'@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive = true
        );
        insert testUser;

        System.runAs(testUser) {
            // Create Leads
         
            Lead lad1 = new Lead(
                LastName = 'TestLead2',
                Allocated_Project__c = 'Trifecta Vanto',
                Phone__c = '9182748512',
                Secondary_Phone__c = '9182748514',
                Lead_Status__c = 'SV Done',
                RecordTypeId = salesRecordTypeId,
                Source_Type__c = 'Google',
                Sales_user__c = testUser.Id 
            );
            insert lad1;
           

          List<Site_Visit__c> siteList = new List<Site_Visit__c>();
            

            // Site Visit records — now with OwnerId
            Site_Visit__c sv = new Site_Visit__c(
                Date__c = System.now().addDays(3),
                Status__c = 'Scheduled',
                Project__c = 'Trifecta Vanto',
                OTP__c = '0001',
                SLead__c = lad1.Id,
                OwnerId = testUser.Id,
                Site_Visit_Remarks__c ='test'
            );
            insert sv;
            sv.Status__c = 'Scheduled';
            update sv;
            siteList.add(sv);

            sv.Status__c = 'Verified by GRE';
            update sv;

          
            
            Map<Id,Site_Visit__c> siteMap = new Map<Id,Site_Visit__c>{sv.Id =>sv};
                
                
                SiteVisitTriggerHandler.afterInsert(siteList);
            SiteVisitTriggerHandler.AfterUpdate(siteList,siteMap);
            SiteVisitTriggerHandler.beforeUpdate(siteList,siteMap);
            SiteVisitTriggerHandler.AfterUpdate(siteList,siteMap);
            SiteVisitTriggerHandler.updateLeadNotesFromSiteVisits(siteList);
            
            
    }

}
    
    @isTest
    public static void siteVisit1(){
         
        // Get record type IDs
        Id salesRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
       // Id preSalesRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();

        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser'+System.currentTimeMillis()+'@example.com',
            Username = 'testuser'+System.currentTimeMillis()+'@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive = true
        );
        insert testUser;

        System.runAs(testUser) {
            // Create Leads
         
            Lead lad1 = new Lead(
                LastName = 'TestLead2',
                Allocated_Project__c = 'Trifecta Vanto',
                Phone__c = '9182748512',
                Secondary_Phone__c = '9182748514',
                Lead_Status__c = 'SV Done',
                RecordTypeId = salesRecordTypeId,
                Source_Type__c = 'Google',
                Sales_user__c = testUser.Id 
            );
            insert lad1;
           

          List<Site_Visit__c> siteList = new List<Site_Visit__c>();
            

            // Site Visit records — now with OwnerId
            Site_Visit__c sv = new Site_Visit__c(
                Date__c = System.now().addDays(3),
                Status__c = 'Scheduled',
                Project__c = 'Trifecta Vanto',
                OTP__c = '0001',
                SLead__c = lad1.Id,
                OwnerId = testUser.Id
            );
            insert sv;
            sv.Status__c = 'Completed';
            update sv;
            siteList.add(sv);



          
            
            Map<Id,Site_Visit__c> siteMap = new Map<Id,Site_Visit__c>{sv.Id =>sv};
                
                
                SiteVisitTriggerHandler.afterInsert(siteList);
            SiteVisitTriggerHandler.AfterUpdate(siteList,siteMap);
            SiteVisitTriggerHandler.beforeUpdate(siteList,siteMap);
            SiteVisitTriggerHandler.AfterUpdate(siteList,siteMap);
                
            
    }

}
}