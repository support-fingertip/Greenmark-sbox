@isTest
public class RoundRobinHandlerTest {
    @isTest
    public static void method1() {
        
        // Create Users first (Setup objects)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Pre Sales' LIMIT 1];

        User u = new User(
            ProfileId = p.Id,
            LastName = 'RH23',
            Email = 'RH@gm1ail.com',
            Username = 'RH@1gmail.com' + System.currentTimeMillis(),
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
        insert u;

        User u1 = new User(
            ProfileId = p.Id,
            LastName = 'RH23',
            Email = 'RH@gm2ail.com',
            Username = 'RH2@1gmail.com' + System.currentTimeMillis(),
            CompanyName = 'RH1',
            Title = 'titletitl1e',
            Alias = 'lokma2n',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Availability__c = false,
            
            IsActive = true,
            is_working__c = true
        );
        insert u1;

        // ✅ Separate context for non-setup objects
        System.runAs(u1) {
            Round_Robin__c r = new Round_Robin__c(
                Active__c = true,
                Project_Assigned__c = 'Trifecta Vanto',
                Lead_Source_Type__c = 'Digital Marketing',
                Project_Head__c = u.Id
            );
            insert r;

            Round_Robin_member__c rrm = new Round_Robin_member__c(
                Round_Robin__c = r.Id,
                Active__c = true,
                User__c = u.Id,
                User_Type__c = 'Pre Sales'
            );
            insert rrm;

            Round_Robin_member__c rrm1 = new Round_Robin_member__c(
                Round_Robin__c = r.Id,
                Active__c = true,
                User__c = u1.Id,
                User_Type__c = 'Sales'
            );
            insert rrm1;

            List<Lead> conlst = new List<Lead>();
            Lead c = new Lead(
                LastName = 'test',
                Allocated_Project__c = 'Trifecta Vanto',
                Phone__c = '9194949494',
                Secondary_Phone__c = '9849594049',
                Secondary_Email__c = 'cc@gmail.com',
                Source_Type__c = 'Google',
                Company = 'Test Company'
            );
            conlst.add(c);
            
            
              // LEAD FOR NOT AVAILABLE QUEUE
            Lead L2 = new Lead(
                LastName = 'L2',
                Company = 'BBB',
                Allocated_Project__c = 'Trifecta Vanto',
                Source_Type__c = 'Google'
            );
            conlst.add(L2);
            
            // LEAD FOR PROJECT HEAD
            Lead L3 = new Lead(
                LastName = 'L3',
                Company = 'CCC',
                Allocated_Project__c = 'Trifecta Retto',    
                Source_Type__c = 'Google'
            );
             conlst.add(L3);

            RoundRobinHandler.assignLead(conlst, false, 'Pre Sales');
            RoundRobinHandler.assignLead(conlst, false, 'Sales');

            List<Site_Visit__c> svlist = new List<Site_Visit__c>{
                new Site_Visit__c(
                    Date__c = System.now() + 3,
                    Status__c = 'Scheduled',
                    Go_For_Round_Robin__c = true,
                    Source_Type__c = 'Google',
                    Project__c = 'Trifecta Vanto'
                )
            };

            RoundRobinHandler.siteVisitRoundRobin(svlist);

            // Cover method
            System.runAs(u) {
                User us = [SELECT Id, Name, Availability__c FROM User WHERE Id = :UserInfo.getUserId()];
                us.Availability__c = true;
                update us;
               // RoundRobinHandler.testcover();
            }
        }
    }
    
        @isTest
    public static void method2() {
        
        // Create Users first (Setup objects)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Pre Sales' LIMIT 1];

        User u = new User(
            ProfileId = p.Id,
            LastName = 'RH23',
            Email = 'RH@gm1ail.com',
            Username = 'RH@1gmail.com' + System.currentTimeMillis(),
            CompanyName = 'RH1',
            Title = 'titletitl1e',
            Alias = 'lokma1n',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Availability__c = false,
            IsActive = true,
            is_working__c = true
        );
        insert u;

        User u1 = new User(
            ProfileId = p.Id,
            LastName = 'RH23',
            Email = 'RH@gm2ail.com',
            Username = 'RH2@1gmail.com' + System.currentTimeMillis(),
            CompanyName = 'RH1',
            Title = 'titletitl1e',
            Alias = 'lokma2n',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Availability__c = false,
            
            IsActive = true,
            is_working__c = true
        );
        insert u1;

        //  Separate context for non-setup objects
        System.runAs(u1) {
            Round_Robin__c r = new Round_Robin__c(
                Active__c = true,
                Project_Assigned__c = 'Trifecta Vanto',
                Lead_Source_Type__c = 'Digital Marketing',
                Project_Head__c = u.Id
            );
            insert r;

            Round_Robin_member__c rrm = new Round_Robin_member__c(
                Round_Robin__c = r.Id,
                Active__c = true,
                User__c = u.Id,
                User_Type__c = 'Pre Sales'
            );
            insert rrm;

            Round_Robin_member__c rrm1 = new Round_Robin_member__c(
                Round_Robin__c = r.Id,
                Active__c = true,
                User__c = u1.Id,
                User_Type__c = 'Sales'
            );
            insert rrm1;

            List<Lead> conlst = new List<Lead>();
            Lead c = new Lead(
                LastName = 'test',
                Allocated_Project__c = 'Trifecta Vanto',
                Phone__c = '9194949494',
                Secondary_Phone__c = '9849594049',
                Secondary_Email__c = 'cc@gmail.com',
                Source_Type__c = 'Google',
                Company = 'Test Company'
            );
            conlst.add(c);
            
            
              // LEAD FOR NOT AVAILABLE QUEUE
            Lead L2 = new Lead(
                LastName = 'L2',
                Company = 'BBB',
                Allocated_Project__c = 'Trifecta Vanto',
                Source_Type__c = 'Google'
            );
            conlst.add(L2);
            
            // LEAD FOR PROJECT HEAD
            Lead L3 = new Lead(
                LastName = 'L3',
                Company = 'CCC',
                Allocated_Project__c = 'Trifecta Retto',    
                Source_Type__c = 'Google'
            );
             conlst.add(L3);

            RoundRobinHandler.assignLead(conlst, false, 'Pre Sales');
            RoundRobinHandler.assignLead(conlst, false, 'Sales');

            List<Site_Visit__c> svlist = new List<Site_Visit__c>{
                new Site_Visit__c(
                    Date__c = System.now() + 3,
                    Status__c = 'Scheduled',
                    Go_For_Round_Robin__c = true,
                    Source_Type__c = 'Google',
                    Project__c = 'Trifecta Vanto'
                )
            };

            RoundRobinHandler.siteVisitRoundRobin(svlist);

     
        }
    }
}