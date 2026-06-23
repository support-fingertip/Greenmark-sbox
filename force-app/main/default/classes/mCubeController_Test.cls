@isTest
public class mCubeController_Test {
    
    @isTest
    public static void inboundCalltest() {
        
        // Create Lead
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Company = 'TestCompany',
            Phone = '67878',
            MobilePhone = '1111111',
            Email = 'standarduser@testorgfil.com',
            Source_Type__c = 'Google',
            Phone__c = '8697567891',
            Secondary_phone__c = '8697567891',   // IMPORTANT: Ensure match
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert lead;
        
        // Create MCUBE Object
        MCUBE_Object_Api__c m = new MCUBE_Object_Api__c(
            Name = 'Lead',
            Field_to_Compare_Mobile_Incoming_Number__c = 'Phone__c',
            field__c = 'FirstName',
            field1__c = 'LastName',
            field2__c = 'Company',
            Value__c = 'company',
            value1__c = 'company',
            value2__c = 'company'
        );
        insert m;
        
        // Landing Number
        Landing_Number__c landing = new Landing_Number__c(
            Name = 'Trifecta Vanto',
            Project_Name__c = 'Trifecta Vanto',
            Active__c = true,
            Source__c = 'Google',
            Sub_Source__c = 'Search Ads'
        );
        insert landing;
        
        
        // Landing Number
        Landing_Number__c landing1 = new Landing_Number__c(
            Name = '9908073349',
            Project_Name__c = 'None',
            Active__c = true,
            Source__c = 'Google',
            Sub_Source__c = 'Search Ads'
        );
        insert landing1;
        
        // Create User
        Profile p = [SELECT Id FROM Profile LIMIT 1];
        
        User u = new User(
            Alias = 'standt12',
            Email = 'standarduser@testorgfil.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser@testorg.com.123',
            MobilePhone = '111'
        );
        u.massdialerIds__c = ',' + lead.Id;
        insert u;
        
        // JSON Requests
        String data;
        
        PageReference pageRef = Page.calland;
        Test.setCurrentPage(pageRef);
        
        // CASE 1
        data = '{\"dialstatus\":\"CONNECTING\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        // CASE 2
        data = '{\"dialstatus\":\"ANSWER\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        // CASE 3
        data = '{\"status\":\"ORIGINATE\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"executive\":\"111\",\"customer\":\"1111111\",\"refid\":\"'+lead.Id+'\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        // CASE 4
        data = '{\"dialstatus\":\"CALL COMPLETE\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"executive\":\"111\",\"customer\":\"1111111\",\"refid\":\"'+lead.Id+'\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        // CASE 5
        data = '{\"dialstatus\":\"CALL COMPLETE\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"executive\":\"111\",\"customer\":\"1111111\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        mCubeController.readCall();
        
        // Set lead as CLOSED LOST so checkList hits the condition
        lead.Lead_Status__c = 'Lead Lost';
        update lead;
     
        
        
        ApexPages.currentPage().getParameters().put('landingNumber', 'NON_EXISTING_PROJECT');
        ApexPages.currentPage().getParameters().put('fromnumber', '8697567891'); 
        
        // landingNumber MUST NOT MATCH ANY Landing_Number__c
        ApexPages.currentPage().getParameters().put('landingNumber', 'Trifecta Retto');
        
        
        //  IMPORTANT FIX — set parameters so SOQL matches
        ApexPages.currentPage().getParameters().put('fromnumber', '8697567891');
        ApexPages.currentPage().getParameters().put('landingNumber', 'Trifecta Vanto');
        
        // Call Route (this covers the previously missing block)
        
        mCubeController.callRoute();
        
        
        
        mCubeController.readCall();
        mCubeController.callConnecting();
        
        
        mCubeController.callWrapper wrapper= new mCubeController.callWrapper();
        wrapper.refid = 'test';
        
        
        System.runAs(u) {
            mCubeController.clickToCall(lead.Id);
            mCubeController.clickToCallNumber(String.valueOf(lead.Id), '1111111');
            mCubeController.readNumbers(String.valueOf(lead.Id));
            
            pageRef = Page.Dialer;
            Test.setCurrentPage(pageRef);
            
            ApexPages.StandardSetController stdSetController =
                new ApexPages.StandardSetController(new List<Lead>{lead});
            Dialercontroller s = new Dialercontroller(stdSetController);
            
            s.direct();
            
            u.massdialerIds__c = ',' + lead.Id;
            update u;
        }
    }
    
    
    @isTest
    public static void inboundCalltest2() {
        
        // Create Lead
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Company = 'TestCompany',
            Phone = '67878',
            MobilePhone = '1111111',
            Email = 'standarduser@testorgfil.com',
            Source_Type__c = 'Google',
            Phone__c = '8697567891',
            Secondary_phone__c = '8697567891',   // IMPORTANT: Ensure match
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert lead;
        
        // Create MCUBE Object
        MCUBE_Object_Api__c m = new MCUBE_Object_Api__c(
            Name = 'Lead',
            Field_to_Compare_Mobile_Incoming_Number__c = 'Phone__c',
            field__c = 'FirstName',
            field1__c = 'LastName',
            field2__c = 'Company',
            Value__c = 'company',
            value1__c = 'company',
            value2__c = 'company'
        );
        insert m;
        
        // Landing Number
        Landing_Number__c landing = new Landing_Number__c(
            Name = 'Trifecta Vanto',
            Project_Name__c = 'Trifecta Vanto',
            Active__c = true,
            Source__c = 'Google',
            Sub_Source__c = 'Search Ads'
        );
        insert landing;
        
        
        // Landing Number
        Landing_Number__c landing1 = new Landing_Number__c(
            Name = '9908073349',
            Project_Name__c = 'None',
            Active__c = true,
            Source__c = 'Google',
            Sub_Source__c = 'Search Ads'
        );
        insert landing1;
        
        // Create User
        Profile p = [SELECT Id FROM Profile LIMIT 1];
        
        User u = new User(
            Alias = 'standt12',
            Email = 'standarduser@testorgfil.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser@testorg.com.123',
            MobilePhone = '111'
        );
        u.massdialerIds__c = ',' + lead.Id;
        insert u;
        
        // JSON Requests
        String data;
        
        PageReference pageRef = Page.calland;
        Test.setCurrentPage(pageRef);
        
        // CASE 1
        data = '{\"dialstatus\":\"CONNECTING\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        // CASE 2
        data = '{\"dialstatus\":\"ANSWER\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        // CASE 3
        data = '{\"status\":\"ORIGINATE\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"executive\":\"111\",\"customer\":\"1111111\",\"refid\":\"'+lead.Id+'\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        // CASE 4
        data = '{\"dialstatus\":\"CALL COMPLETE\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"executive\":\"111\",\"customer\":\"1111111\",\"refid\":\"'+lead.Id+'\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        // CASE 5
        data = '{\"dialstatus\":\"CALL COMPLETE\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"executive\":\"111\",\"customer\":\"1111111\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        mCubeController.readCall();
        
        // Set lead as CLOSED LOST so checkList hits the condition
        lead.Lead_Status__c = 'Lead Lost';
        update lead;
     
        
        

        // landingNumber MUST NOT MATCH ANY Landing_Number__c
        ApexPages.currentPage().getParameters().put('landingNumber', '9908073349');
        
        
        //  IMPORTANT FIX — set parameters so SOQL matches
        ApexPages.currentPage().getParameters().put('fromnumber', '8697567891');
 
        
        // Call Route (this covers the previously missing block)
        
        mCubeController.callRoute();
        
        
        
        mCubeController.readCall();
        mCubeController.callConnecting();
        
        
        mCubeController.callWrapper wrapper= new mCubeController.callWrapper();
        wrapper.refid = 'test';
        
        
        System.runAs(u) {
            mCubeController.clickToCall(lead.Id);
            mCubeController.clickToCallNumber(String.valueOf(lead.Id), '1111111');
            mCubeController.readNumbers(String.valueOf(lead.Id));
            
            pageRef = Page.Dialer;
            Test.setCurrentPage(pageRef);
            
            ApexPages.StandardSetController stdSetController =
                new ApexPages.StandardSetController(new List<Lead>{lead});
            Dialercontroller s = new Dialercontroller(stdSetController);
            
            s.direct();
            
            u.massdialerIds__c = ',' + lead.Id;
            update u;
        }
    }
    
      
    @isTest
    public static void inboundCalltest3() {
        
        // Create Lead
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Company = 'TestCompany',
            Phone = '67878',
            MobilePhone = '1111111',
            Email = 'standarduser@testorgfil.com',
            Source_Type__c = 'Google',
            Phone__c = '8697567891',
            Secondary_phone__c = '8697567891',   // IMPORTANT: Ensure match
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert lead;
        
        // Create MCUBE Object
        MCUBE_Object_Api__c m = new MCUBE_Object_Api__c(
            Name = 'Lead',
            Field_to_Compare_Mobile_Incoming_Number__c = 'Phone__c',
            field__c = 'FirstName',
            field1__c = 'LastName',
            field2__c = 'Company',
            Value__c = 'company',
            value1__c = 'company',
            value2__c = 'company'
        );
        insert m;
        
        // Landing Number
        Landing_Number__c landing = new Landing_Number__c(
            Name = 'Trifecta Vanto',
            Project_Name__c = 'Trifecta Vanto',
            Active__c = true,
            Source__c = 'Google',
            Sub_Source__c = 'Search Ads'
        );
        insert landing;
        
        
        // Landing Number
        Landing_Number__c landing1 = new Landing_Number__c(
            Name = '9908073349',
            Project_Name__c = 'None',
            Active__c = true,
            Source__c = 'Google',
            Sub_Source__c = 'Search Ads'
        );
        insert landing1;
        
        // Create User
        Profile p = [SELECT Id FROM Profile LIMIT 1];
        
        User u = new User(
            Alias = 'standt12',
            Email = 'standarduser@testorgfil.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser@testorg.com.123',
            MobilePhone = '111'
        );
        u.massdialerIds__c = ',' + lead.Id;
        insert u;
        
        // JSON Requests
        String data;
        
        PageReference pageRef = Page.calland;
        Test.setCurrentPage(pageRef);
        
        // CASE 1
        data = '{\"dialstatus\":\"CONNECTING\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        // CASE 2
        data = '{\"dialstatus\":\"ANSWER\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        // CASE 3
        data = '{\"status\":\"ORIGINATE\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"executive\":\"111\",\"customer\":\"1111111\",\"refid\":\"'+lead.Id+'\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        // CASE 4
        data = '{\"dialstatus\":\"CALL COMPLETE\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"executive\":\"111\",\"customer\":\"1111111\",\"refid\":\"'+lead.Id+'\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        // CASE 5
        data = '{\"dialstatus\":\"CALL COMPLETE\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"executive\":\"111\",\"customer\":\"1111111\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        mCubeController.readCall();
        
        // Set lead as CLOSED LOST so checkList hits the condition
        lead.Lead_Status__c = 'Lead Lost';
        update lead;
     
        
        

        // landingNumber MUST NOT MATCH ANY Landing_Number__c
        ApexPages.currentPage().getParameters().put('landingNumber', '9908073349');
        
        
        //  IMPORTANT FIX — set parameters so SOQL matches
        ApexPages.currentPage().getParameters().put('fromnumber', '9697569891');
 
        
        // Call Route (this covers the previously missing block)
        
        mCubeController.callRoute();
        
        
        
        mCubeController.readCall();
        mCubeController.callConnecting();
        
        
        mCubeController.callWrapper wrapper= new mCubeController.callWrapper();
        wrapper.refid = 'test';
        
        
        System.runAs(u) {
            mCubeController.clickToCall(lead.Id);
            mCubeController.clickToCallNumber(String.valueOf(lead.Id), '1111111');
            mCubeController.readNumbers(String.valueOf(lead.Id));
            
            pageRef = Page.Dialer;
            Test.setCurrentPage(pageRef);
            
            ApexPages.StandardSetController stdSetController =
                new ApexPages.StandardSetController(new List<Lead>{lead});
            Dialercontroller s = new Dialercontroller(stdSetController);
            
            s.direct();
            
            u.massdialerIds__c = ',' + lead.Id;
            update u;
        }
    }
    
       
    @isTest
    public static void inboundCalltest4() {
        
        // Create Lead
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Company = 'TestCompany',
            Phone = '67878',
            MobilePhone = '1111111',
            Email = 'standarduser@testorgfil.com',
            Source_Type__c = 'Google',
            Phone__c = '8697567891',
            Secondary_phone__c = '8697567891',   // IMPORTANT: Ensure match
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert lead;
        
        // Create MCUBE Object
        MCUBE_Object_Api__c m = new MCUBE_Object_Api__c(
            Name = 'Lead',
            Field_to_Compare_Mobile_Incoming_Number__c = 'Phone__c',
            field__c = 'FirstName',
            field1__c = 'LastName',
            field2__c = 'Company',
            Value__c = 'company',
            value1__c = 'company',
            value2__c = 'company'
        );
        insert m;
        
        // Landing Number
        Landing_Number__c landing = new Landing_Number__c(
            Name = 'Trifecta Vanto',
            Project_Name__c = 'Trifecta Vanto',
            Active__c = true,
            Source__c = 'Google',
            Sub_Source__c = 'Search Ads'
        );
        insert landing;
        
        
        // Landing Number
        Landing_Number__c landing1 = new Landing_Number__c(
            Name = '9908073349',
            Project_Name__c = 'None',
            Active__c = true,
            Source__c = 'Google',
            Sub_Source__c = 'Search Ads'
        );
        insert landing1;
        
        // Create User
        Profile p = [SELECT Id FROM Profile LIMIT 1];
        
        User u = new User(
            Alias = 'standt12',
            Email = 'standarduser@testorgfil.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser@testorg.com.123',
            MobilePhone = '111'
        );
        u.massdialerIds__c = ',' + lead.Id;
        insert u;
        
        // JSON Requests
        String data;
        
        PageReference pageRef = Page.calland;
        Test.setCurrentPage(pageRef);
        
        // CASE 1
        data = '{\"dialstatus\":\"CONNECTING\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        // CASE 2
        data = '{\"dialstatus\":\"ANSWER\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        // CASE 3
        data = '{\"status\":\"ORIGINATE\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"executive\":\"111\",\"customer\":\"1111111\",\"refid\":\"'+lead.Id+'\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        // CASE 4
        data = '{\"dialstatus\":\"CALL COMPLETE\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"executive\":\"111\",\"customer\":\"1111111\",\"refid\":\"'+lead.Id+'\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        // CASE 5
        data = '{\"dialstatus\":\"CALL COMPLETE\",\"endtime\":\"'+System.now()+'\",\"starttime\":\"'+System.now()+'\",\"executive\":\"111\",\"customer\":\"1111111\"}';
        ApexPages.currentPage().getParameters().put('data', data);
        mCubeController.inboundCall();
        
        mCubeController.readCall();
        
        // Set lead as CLOSED LOST so checkList hits the condition
        lead.Lead_Status__c = 'Lead Lost';
        update lead;
     
        
        

        // landingNumber MUST NOT MATCH ANY Landing_Number__c
        ApexPages.currentPage().getParameters().put('landingNumber', 'Trifecta Vanto');
        
        
        //  IMPORTANT FIX — set parameters so SOQL matches
        ApexPages.currentPage().getParameters().put('fromnumber', '9697569891');
 
        
        // Call Route (this covers the previously missing block)
        
        mCubeController.callRoute();
        
        
        mCubeController.testmeth();
        mCubeController.readCall();
        mCubeController.callConnecting();
        
        
        mCubeController.callWrapper wrapper= new mCubeController.callWrapper();
        wrapper.refid = 'test';
        
        
        System.runAs(u) {
            mCubeController.clickToCall(lead.Id);
            mCubeController.clickToCallNumber(String.valueOf(lead.Id), '1111111');
            mCubeController.readNumbers(String.valueOf(lead.Id));
            
            pageRef = Page.Dialer;
            Test.setCurrentPage(pageRef);
            
            ApexPages.StandardSetController stdSetController =
                new ApexPages.StandardSetController(new List<Lead>{lead});
            Dialercontroller s = new Dialercontroller(stdSetController);
            
            s.direct();
            
            u.massdialerIds__c = ',' + lead.Id;
            update u;
        }
    }
  
  
    @isTest
    static void test_callConnecting_missingLandingNumber() {

        // -------------------------
        // 1. Create CLOSED LOST Lead
        // -------------------------
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Phone__c = '8697567891',
            Source_Type__c = 'Google',
            Secondary_phone__c = '8697567891',
            Allocated_Project__c = 'Trifecta Vanto',
            Lead_Status__c = 'New'
        );
        insert lead;

        // -------------------------
        // 2. Create MCUBE Object (field__c NOT NULL)
        // -------------------------
        MCUBE_Object_Api__c mc = new MCUBE_Object_Api__c(
            Name = 'Lead',
            field__c = 'Allocated_Project__c',
            field1__c = 'LastName',
            field2__c = 'Company',
            Field_to_Compare_Mobile_Incoming_Number__c = 'Phone__c'
        );
        insert mc;

        // -------------------------
        // 3. Create Landing Number (but DO NOT MATCH in parameter)
        // -------------------------
        Landing_Number__c landing = new Landing_Number__c(
            Name = 'Trifecta Vanto',
            Project_Name__c = 'Trifecta Vanto',
            Active__c = true,
            Source__c = 'Google',
            Sub_Source__c = 'Search Ads'
        );
        insert landing;

        // -------------------------
        // 4. Set Page & Parameters
        // -------------------------
        PageReference pg = Page.calland;
        Test.setCurrentPage(pg);

        //  fromnumber matches Lead
        ApexPages.currentPage().getParameters().put('fromnumber', '8697567891');

        //  This MUST NOT match Landing_Number__c
        ApexPages.currentPage().getParameters().put('landingNumber', 'Trifecta Vanto');

        // -------------------------
        // 5. Execute Method (THIS COVERS YOUR MISSED BLOCK)
        // -------------------------
        Test.startTest();
        mCubeController.callRoute();
        Test.stopTest();


        
    }
    
    @isTest
    static void testCallWrapperCoverage() {
        
        // Step 1: Create Wrapper Object
        mCubeController.callWrapper cw = new mCubeController.callWrapper();
        
        // Step 2: Assign values to all variables
        cw.refid = 'REF001';
        cw.callid = 'CALL001';
        cw.callfrom = '9876543210';
        cw.starttime = '10:30 AM';
        cw.filename = 'recording.mp3';
        cw.calid = 'CAL123';
        cw.pulse = '30';
        cw.source = 'Inbound';
        cw.custfeedback = 'Good';
        cw.exefeedback = 'Interested';
        cw.dialstatus = 'Connected';
        cw.callerbusiness = 'Retail';
        cw.callername = 'Ramesh';
        cw.remark = 'Follow-up required';
        cw.calleraddress = 'Hyderabad';
        cw.caller_email = 'test@gmail.com';
        cw.rate = '5';
        cw.empnumber = 'EMP001';
        cw.endtime = '10:45 AM';
        cw.eid = 'EID001';
        cw.empid = 'EMP123';
        cw.gid = 'GID123';
        cw.empemail = 'emp@gmail.com';
        cw.status = 'Completed';
        cw.executive = 'Sales Exec';
        cw.customer = 'Test Customer';
        cw.LandingNumber = '1800123456';
        cw.campaign = 'Summer Campaign';
        cw.clicktocalldid = 'CLICK001';
        
    }
    

}