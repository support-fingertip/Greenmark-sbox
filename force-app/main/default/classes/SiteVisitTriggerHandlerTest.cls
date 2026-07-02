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

    // Verifies the Completed feedback email fires only on a status TRANSITION, never on
    // insert-as-Completed. The feedback email path performs no callout, so no HTTP mock is needed.
    @isTest
    static void completedFeedbackEmailIsTransitionOnly(){
        Utility.runLeadTrigger = false;
        Lead ld = new Lead(LastName = 'Transition Lead', Company = 'Test',
                           Email = 'transition@example.com', Phone__c = '9990004444');
        insert ld;

        // Inserted directly as Completed -> must NOT send a feedback email.
        Site_Visit__c sv = new Site_Visit__c(
            SLead__c = ld.Id, Date__c = Datetime.now().addDays(1), Status__c = 'Completed');
        insert sv;

        Test.startTest();
        // A genuine Scheduled -> Completed transition: should send exactly one feedback email.
        Map<Id, Site_Visit__c> oldMap = new Map<Id, Site_Visit__c>{
            sv.Id => new Site_Visit__c(Id = sv.Id, Status__c = 'Scheduled')
        };
        SiteVisitTriggerHandler.sendStatusEmails(new List<Site_Visit__c>{ sv }, oldMap);

        // Insert path (oldMap null) with Status already Completed: should enqueue nothing.
        SiteVisitTriggerHandler.sendStatusEmails(new List<Site_Visit__c>{ sv }, null);
        Test.stopTest();

        System.assertEquals(1, Limits.getEmailInvocations(),
            'Only the transition should send a feedback email; insert-as-Completed sends none');
    }
}