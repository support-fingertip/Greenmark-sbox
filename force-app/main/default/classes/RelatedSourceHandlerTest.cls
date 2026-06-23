@isTest
public class RelatedSourceHandlerTest {
    @isTest
    public static  void testmech(){
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
        
        
        
        list<Lead> ldlist = new  list<Lead>();
        list<Lead> ldlist21 = new  list<Lead>();
        list<Lead> Newlist = new  list<Lead>();
        Lead ld22 = new Lead();
        ld22.LastName ='test ld';
        ld22.Phone__c ='9908072233';
        ld22.Email='Test@gmai1l.com';
        ld22.allocated_project__c ='Trifecta Vanto';
        ld22.Secondary_Phone__c='9922332246';
        // ld22.Lead_status__c='Unqualified';
        // ld22.Unqualified_Reason__c='Budget';
        ld22.Source_Type__c = 'Google';
        ld22.Secondary_Country_Code__c = '91';
        ld22.Company='test';
        ld22.Campaign__c = 'test';
        //ld22.Closed_Lost_Reason__c ='Junk Enquiry';
        insert ld22;
        ldlist.add(ld22);
        
        
        Lead ld221 = new Lead();
        ld221.LastName ='test ld';
        ld221.Phone__c ='9908072211';
        //ld221.Secondary_Phone__c='+919922332244';
        ld221.Email ='Test@gmai1l.com';
        ld221.Company='test';
        ld221.Source_Type__c = 'Google';
        ld221.allocated_project__c ='Trifecta Vanto';
        //ld22.Lead_status__c='Closed Lost';
        //insert ld221;
        ldlist21.add(ld221);
        
        Lead lead12 = new Lead();
        lead12.LastName ='test ld';
        lead12.Phone__c ='9908072453';
        lead12.Email ='Test384564@gmai2l.com';
        lead12.Company='test';
        lead12.Source_Type__c = 'Google';
        lead12.allocated_project__c ='Trifecta Vanto';
        lead12.Lead_status__c='Lead Lost';
        insert lead12;
        ldlist21.add(lead12);
        
        
        Lead ld23 = new Lead();
        ld23.LastName ='test ld';
        ld23.Phone__c ='9908072233';
        ld23.Email ='Test3845784@gmai2l.com';
        ld23.Company='test';
        ld23.Source_Type__c = 'Google';
        ld23.allocated_project__c ='Trifecta Vanto';
        insert ld23;
        ldlist21.add(ld23);
        
        
        
        
        list<Lead> ldlist1 = new  list<Lead>();
        
        Lead c2= new Lead();
        c2.LastName ='test ld';
        c2.Phone__c ='9908072211';
        c2.Email ='Test@gmai2l.com';
        c2.allocated_project__c ='Trifecta Vanto';
        c2.Company='Test';
        c2.Source_Type__c = 'Google';
        ldlist1.add(c2);
        
        
        
        list<lead> ldlist2 = new  list<lead>();
        
        Lead c22= new Lead();
        c22.LastName ='test ld';
        c22.Phone__c ='9908072209';
        c22.Email ='Test@gmai2l.com';
        c22.Company='Test';
        c22.Source_Type__c = 'Google';
        c22.allocated_project__c ='Trifecta Vanto';
        
        insert c22;
        ldlist1.add(c22);
        
        Lead lad= new Lead();
        lad.LastName='test';
        lad.Allocated_Project__c = 'Trifecta Vanto';
        lad.Phone = '9182748516';
        lad.Lead_Status__c ='New';
        lad.Company='test';
        lad.Source_Type__c = 'Google';
        insert lad;
        
        
        Newlist.add(lad);
        Lead led= new Lead();
        led.LastName='test1';
        led.Allocated_Project__c = 'Trifecta Vanto';
        led.Phone = '9182748511';
        led.Lead_Status__c ='New';
        led.Company='test';
        led.Source_Type__c = 'Google';
        insert led;
        Newlist.add(led);  
        
        Related_source__c rs = new Related_source__c();
        rs.SLead__c = ld22.Id;                           // MAIN LEAD
        //rs.PhoneProject__c = ld22.Phone__c + ld22.Allocated_Project__c;
        rs.Allocated_Project__c = ld22.Allocated_Project__c;
        insert rs;
        
        Channel_partner__c cp = new Channel_partner__c(
            
            Active__c = true,
            Email__c = 'test54646@gmail.com',
            ContactPerson__c = 'test'
        );
        insert cp;
        
        Lead lead5= new Lead();
        lead5.LastName='test154';
        lead5.Allocated_Project__c = 'Trifecta Vanto';
        lead5.Phone = '9182748011';
        lead5.Lead_Status__c ='New';
        lead5.Company='test';
        lead5.Source_Type__c = 'Google';
        lead5.Channel_Partner__c = cp.Id;
        insert lead5;
        Newlist.add(lead5);  
        
        
        Lead parentLead = new Lead(
            LastName = 'Main Lead',
            Company = 'ABC',
            Phone = '9990001111',
            Lead_Status__c = 'Lead Lost',   // THIS drives the formula
            Source_Type__c = 'Google'
        );
        insert parentLead;
        
        Lead childLead = new Lead(
            LastName = 'Child Lead',
            Company = 'XYZ',
            Phone__c = '9990002222',
            Source_Type__c = 'Google',
            Allocated_Project__c = 'Trifecta Vanto',
            Main_Lead__c = parentLead.Id   // SELF LOOKUP
        );
        insert childLead;
        
        
        
        Map<String, String> countryMap = new Map<String, String>{'91' => 'India'};
            
            RelatedSourceHandler.checkMobileNumber2(ldlist);
        
        RelatedSourceHandler.cpmethod(ldlist);
        RelatedSourceHandler.checkMobileNumber2(ldlist);
        RelatedSourceHandler.processPhoneNumber(led,countryMap, true);
        // RelatedSourceHandler.addCountryCode(ldlist);
        // RelatedSourceHandler.duplicateCheck(ldlist);
        //  RelatedSourceHandler.duplicateCheck(Newlist);
        // RelatedSourceHandler.duplicateCheckOnUpdate(ldlist);
        RelatedSourceHandler.duplicateCheck2(ldlist);
        RelatedSourceHandler.duplicateCheck2(ldlist1 );
        
        RelatedSourceHandler.afterinsertLogic(Newlist);
        RelatedSourceHandler.afterinsertLogic2(Newlist);
        //RelatedSourceHandler.afterinsertLogic2(ldlist2 );
        
        RelatedSourceHandler.addRelatedSource(ld22);
        RelatedSourceHandler.addRelatedSource(ld23);
        RelatedSourceHandler.addRelatedSource(ld23);
        Lead ld = [
            SELECT Id,
            Lead_status__c,
            Lead_Assigned__c,
            Lead_Transfered__c,
            Type_of_lead__c,
            Lead_Type__c,
            Assigment_count__c,
            No_Of_Times_Unqualified__c,
            Allocated_Project__c,
            Last_Re_Opened_Date__c,
            Re_assigned_date__c,
            RNR_date__c,
            status_change_date__c,
            Last_comment__c,
            Site_Visit_Schedule_Date__c,
            Site_visit_Project__c,
            Reassigned_By__c,
            Site_Visit_Feedback__c,
            Followup_Subject__c,
            Next_follow_up_Date__c,
            Next_Site_visit_Date__c,
            Closed_Lost_Reason__c,
            Remark_for_Closed_Lost__c,
            Main_Lead__c,
            Source_Type__c,
            Lead_source__c,
            Phone__c,
            Secondary_Phone__c,
            Email,
            Secondary_Email__c,
            PhoneProject__c,
            Secondary_Phone_Project__c,
            EmailProject__c,
            SecondaryEmailProject__c,
            Channel_Partner__c,
            Country_Code__c,
            Secondary_Country_Code__c,
            Campaign__c,
            Campaign_std__c,
            Tertiary_Source__c,
            Main_lead_status__c,
            Main_Pre_Sales_User__c,
            Sales_User__c,
            Walking_Lead_Form__c
            FROM Lead
            WHERE Id = :childLead.Id
        ];
        
        
        RelatedSourceHandler.addRelatedSource(ld);
        
        
        RelatedSourceHandler.addRelatedSource2(ld22,ld23);
        RelatedSourceHandler.reassignUnqualifiedLead(ldlist);
        // RelatedSourceHandler.ensureCorrectPhoneLength('9908073329','91');
        
        
        
        
        
        
    }
    
    // Helper method to create country code map
    private static Map<String, String> getCountryCodeMap() {
        Map<String, String> countryMap = new Map<String, String>();
        countryMap.put('91', 'India');
        countryMap.put('1', 'United States');
        countryMap.put('44', 'United Kingdom');
        return countryMap;
    }
    
    @IsTest
    static void testPrimaryIndianNumberWithoutPlus() {
        Lead ld = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Phone__c = '98765 43210',
            allocated_project__c ='Trifecta Vanto',
            Source_Type__c = 'Google'
        );
        
        Test.startTest();
        RelatedSourceHandler.processPhoneNumber(ld, getCountryCodeMap(), true);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testPrimaryInternationalNumberWithPlus() {
        Lead ld = new Lead(
            LastName = 'Intl Lead',
            Company = 'Test Company',
            Phone__c = '+14405551234',
            allocated_project__c ='Trifecta Vanto',
            Source_Type__c = 'Google'
        );
        
        Test.startTest();
        RelatedSourceHandler.processPhoneNumber(ld, getCountryCodeMap(), true);
        Test.stopTest();

    }
    
    @IsTest
    static void testSecondaryIndianNumberWithoutPlus() {
        Lead ld = new Lead(
            LastName = 'Secondary Lead',
            Company = 'Test Company',
            Secondary_Phone__c = '91234 56789',
            allocated_project__c ='Trifecta Vanto',
            Source_Type__c = 'Google'
        );
        
        Test.startTest();
        RelatedSourceHandler.processPhoneNumber(ld, getCountryCodeMap(), false);
        Test.stopTest();

    }
    
    @IsTest
    static void testSecondaryInternationalNumberWithPlus() {
        Lead ld = new Lead(
            LastName = 'UK Lead',
            Company = 'Test Company',
            Secondary_Phone__c = '+447911123456',
            allocated_project__c ='Trifecta Vanto',
            Source_Type__c = 'Google'
        );
        
        Test.startTest();
        RelatedSourceHandler.processPhoneNumber(ld, getCountryCodeMap(), false);
        Test.stopTest();

    }
    
    @IsTest
    static void testNullPhoneNumber() {
        Lead ld = new Lead(
            LastName = 'Null Phone',
            Company = 'Test Company',
            allocated_project__c ='Trifecta Vanto',
            Source_Type__c = 'Google'
        );
        
        Test.startTest();
        RelatedSourceHandler.processPhoneNumber(ld, getCountryCodeMap(), true);
        Test.stopTest();
        

    }
    
    @IsTest
    static void testUnknownCountryDefaultsToIndia() {
        Lead ld = new Lead(
            LastName = 'Unknown Country',
            Company = 'Test Company',
            Phone__c = '+999123456789'
        );
        
        Test.startTest();
        RelatedSourceHandler.processPhoneNumber(ld, getCountryCodeMap(), true);
        Test.stopTest();
        

    }
}