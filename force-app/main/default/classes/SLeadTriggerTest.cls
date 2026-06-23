@isTest
public class SLeadTriggerTest {
    
    public static testMethod void getSLeadTriggerTest() {
        // Create System Administrator User
        User u = new User();
        u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        u.LastName = 'RH23';
        u.Email = 'RH@gm1ail.com';
        u.Username = 'RH' + System.currentTimeMillis() + '@gmail.com';
        u.CompanyName = 'RH1';
        u.Title = 'titletitl1e';
        u.Alias = 'lokman1';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.Availability__c = false;
        u.IsActive = true;
        u.is_working__c = true;
        insert u;
        User u1 = new User();
        u1.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Pre Sales'].Id;
        u1.LastName = 'RH23';
        u1.Email = 'RH@gm1ail.com';
        u1.Username = 'RHp' + System.currentTimeMillis() + '@gmail.com';
        u1.CompanyName = 'RH1';
        u1.Title = 'titletitl1e';
        u1.Alias = 'lokman1';
        u1.TimeZoneSidKey = 'America/Los_Angeles';
        u1.EmailEncodingKey = 'UTF-8';
        u1.LanguageLocaleKey = 'en_US';
        u1.LocaleSidKey = 'en_US';
        u1.Availability__c = false;
        u1.IsActive = true;
        u1.is_working__c = true;
        insert u1;
        
        User u11 = new User();
        u11.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales'].Id;
        u11.LastName = 'RH23';
        u11.Email = 'RH@gm1ail.com';
        u11.Username = 'RHpp' + System.currentTimeMillis() + '@gmail.com';
        u11.CompanyName = 'RH1';
        u11.Title = 'titletitl1e';
        u11.Alias = 'lokman1';
        u11.TimeZoneSidKey = 'America/Los_Angeles';
        u11.EmailEncodingKey = 'UTF-8';
        u11.LanguageLocaleKey = 'en_US';
        u11.LocaleSidKey = 'en_US';
        u11.Availability__c = false;
        u11.IsActive = true;
        u11.is_working__c = true;
        insert u11;
        
        
        System.runAs(u) {
            // -------- BEFORE INSERT paths --------
            Lead lad = new Lead(
                LastName = 'test',
                Allocated_Project__c = 'Trifecta Vanto',
                Phone__c = '9182748514',
                Secondary_Phone__c = '9182748513',
                Lead_Status__c = 'New',
                Source_Type__c = 'Google',
                Company='Trifecta'
            );
            insert lad;
            
            // PreSales branch (normal new lead, not walkin)
            Lead preLead = new Lead(
                LastName = 'PreSales',
                Allocated_Project__c = 'Trifecta Vanto',
                Phone__c = '8111111111',
                Lead_Status__c = 'New',
                Source_Type__c = 'Google',
                Company='Trifecta'
            );
            insert preLead;
            
            // Walk-in lead (covers walkin branch)
            Lead walkinLead = new Lead(
                LastName = 'WalkIn',
                Allocated_Project__c = 'Trifecta Vanto',
                Phone__c = '9999999999',
                Walking_Lead_Form__c = true,
                Source_Type__c = 'Google',
                Company='Trifecta'
            );
            insert walkinLead;
            
            // -------- Related Records --------
            Site_Visit__c sv = new Site_Visit__c(
                Date__c = System.now() + 3,
                Status__c = 'Scheduled',
                Project__c = 'Trifecta Vanto',
                SLead__c = lad.Id
            );
            insert sv;
            
            Follow_up__c fp = new Follow_up__c(
                Scheduled_Date__c = system.today() + 2,
                SLead__c = lad.Id,
                Status__c = 'Scheduled',
                Subject__c = 'test'
            );
            insert fp;
            
            // -------- BEFORE UPDATE paths --------
            lad.OwnerId = u.Id;
            update lad; // owner change branch
            
            lad.Phone__c = '9182748515'; // duplicate check branch
            update lad;
            
            lad.Secondary_Phone__c = '9182748512';
            update lad;
            
            lad.Lead_status__c = 'Lead Lost';
           // lad.Unqualified_Reason__c = 'Budget';
            update lad; // lostWinLeads branch
            
            
           // lad.Lead_status__c = 'Allocated';
           // lad.Closed_Lost_Reason__c = 'Location';
            update lad;
            
            // -------- DELETE + UNDELETE path --------
            delete sv;
            delete fp;
           // delete lad;
            
        }
        
        System.runAs(u1) {
            Lead preLead = new Lead(
                LastName = 'PreSales',
                Allocated_Project__c = 'Trifecta Vanto',
                Phone__c = '8111111111',
                Lead_Status__c = 'New',
                Source_Type__c = 'Google',
                Company='Trifecta'
            );
            insert preLead;
            
        }
        Lead preLead1 = new Lead(
            LastName = 'PreSales',
            Allocated_Project__c = 'Trifecta Vanto',
            Phone__c = '8111111112',
            Lead_Status__c = 'New',
            Source_Type__c = 'Google',
            Company='Trifecta'
        );
        insert preLead1;
        
        Site_Visit__c sv = new Site_Visit__c(
            Date__c = System.now() + 3,
            Status__c = 'Scheduled',
            Project__c = 'Trifecta Vanto',
            SLead__c = preLead1.Id
        );
        insert sv;
       // preLead1.Lead_Status__c = 'New sales enquiry';
        preLead1.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        
        update preLead1;
        
        preLead1.Lead_Status__c = 'SV Scheduled';
        update preLead1;
        preLead1.OwnerId=u11.Id;
        update preLead1;
        Lead preLead2 = new Lead(
            LastName = 'PreSales',
            Allocated_Project__c = 'Trifecta Vanto',
            Phone__c = '8111111112',
            Lead_Status__c = 'New',
            Company='Trifecta',
            Source_Type__c = 'Google'
        );
        insert preLead2;
        
        
        System.runAs(u11) {
            Lead preLead = new Lead(
                LastName = 'PreSales',
                Allocated_Project__c = 'Trifecta Vanto',
                Phone__c = '8111111111',
                Lead_Status__c = 'New',
                Company='Trifecta',
                Source_Type__c = 'Google'
            );
          insert preLead;
            
        }
    }
}