@IsTest
private class SiteVisitFormControllerTest {

    @IsTest
    public static void testmethod1() {
        // Get record type IDs
        Id salesRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Id preSalesRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();

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
            Lead lad = new Lead(
                LastName = 'TestLead',
                Allocated_Project__c = 'Trifecta Vanto',
                Phone__c = '9182748514',
                //Lead_Status__c = 'Booked',
                Source_Type__c = 'Google',
                RecordTypeId = preSalesRecordTypeId,
                Sales_user__c = testUser.Id ,
                Pre_sales_user__c = testUser.Id,
                Sub_Source__c =  'test',
                Lead_source__c = 'Email'
            );
            insert lad;

            Lead lad1 = new Lead(
                LastName = 'TestLead2',
                Allocated_Project__c = 'Trifecta Vanto',
                Phone__c = '9182748512',
                Secondary_Phone__c = '9182748517',
               // Lead_Status__c = 'SV Done',
                RecordTypeId = salesRecordTypeId,
                Source_Type__c = 'Google',
                Sales_user__c = testUser.Id 
            );
            insert lad1;
            
            
             Lead lad3 = new Lead(
                LastName = 'TestLead2',
                Allocated_Project__c = 'Trifecta Vanto',
                Phone__c = '9182748562',
                Secondary_Phone__c = '9127895170',
                Lead_Status__c = 'Closed Lost',
                RecordTypeId = salesRecordTypeId,
                Source_Type__c = 'Google',
                Sales_user__c = testUser.Id 
            );
            insert lad3;
           

            // Related source
            Related_Source__c rc = new Related_Source__c(
                SLead__c = lad.Id,
                Allocated_Project__c = lad.Allocated_Project__c,
                Phone__c = lad.Phone__c
            );
            insert rc;

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

            sv.Status__c = 'Verified by GRE';
            update sv;

            Site_Visit__c svs = new Site_Visit__c(
                Date__c = System.now().addDays(3),
                Status__c = 'SV Proposed',
                Project__c = 'Trifecta Vanto',
                OTP__c = '0002',
                SLead__c = lad.Id
                
            );
            insert svs;
            
              Site_Visit__c sv3 = new Site_Visit__c(
                Date__c = System.now().addDays(3),
                Status__c = 'Completed',
                Project__c = 'Trifecta Vanto',
                OTP__c = '0002',
                SLead__c = lad.Id
                
            );
            insert sv3;
            
            Follow_up__c f = new Follow_up__c(
            Status__c = 'Scheduled',
                SLead__c = lad.Id,
                Scheduled_Date__c = Date.Today()+3,
                Subject__c = 'sub'
            );
            insert f;

            Site_Visit__c sv1 = [SELECT Id, Name, OTP__c FROM Site_Visit__c WHERE Id = :svs.Id LIMIT 1];

            // Test controller methods
            String result1 = SiteVisitFormController.checkLeadWithPhoneProject(lad.Allocated_Project__c, lad.Phone__c);
            String result2 = SiteVisitFormController.checkLeadWithPhoneProject(lad1.Allocated_Project__c, sv1.OTP__c);

            SiteVisitFormController.getLead(lad.Id);
            SiteVisitFormController.leadNotExists(lad1.Id, 'Warm', 'remarks');
            SiteVisitFormController.getDependentMap( lad, 'Source_Type__c', 'Lead_source__c');
            SiteVisitFormController.extractPicklistValues('lad','Source_Type__c');

            // Test createSv
            DateTime dt = System.now();
            SiteVisitFormController.createSv('Test Remark', dt, 'Trifecta Vanto', lad.Id, 'Warm','','','');
                 SiteVisitFormController.createSv('Test Remark', dt, 'Trifecta Vanto', lad3.Id, 'Warm','','','');
            
        }
    }
}