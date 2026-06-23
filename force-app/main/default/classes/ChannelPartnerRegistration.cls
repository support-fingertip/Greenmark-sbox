Public  class ChannelPartnerRegistration {
    public string status{get;set;}
    
    public void captureLead(){
        string CPType = apexpages.currentpage().getparameters().get('Type');
        string Name =   apexpages.currentpage().getparameters().get('Name');
        string Email = apexpages.currentpage().getparameters().get('Email'); 
        string Phone = apexpages.currentpage().getparameters().get('Phone'); 
        string AlternateNumber = apexpages.currentpage().getparameters().get('AlternateNumber');
        string PANNumber = apexpages.currentpage().getparameters().get('PANNumber'); 
        string AashaarNumber = apexpages.currentpage().getparameters().get('AadhaarNumber'); 
        string GstNumber = apexpages.currentpage().getparameters().get('GstNumber');
        string ReraNumber = apexpages.currentpage().getparameters().get('ReraNumber');
       // string WebsiteCPID = apexpages.currentpage().getparameters().get('WebsiteCPID'); 
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'Channel Partner Lead';
        Channel_Partner__c cp = new Channel_Partner__c();
        cp.ContactPerson__c	 = Name;
        cp.Type_of_CP__c = CPType;
        cp.PAN__c = PANNumber;
        cp.Aadhaar_No__c = AashaarNumber;
        cp.Mobile_Number__c = Phone;
        cp.Alternate_number__c = AlternateNumber;
        cp.RERA__c = GstNumber;
        cp.GST__c = ReraNumber;
        cp.Email__c = Email;
        try{
            insert cp;  
            
           
            Channel_Partner__c cplist =[Select Name From Channel_Partner__c Where Id=:cp.Id];
            
            status = 'Channel Partner has been created Successfully, Pending for Approval ';
            log.status__c='SUCCESS'; 
        }catch(exception e){
            status = 'FAIL '+e.getMessage();
            log.status__c='FAILED';
            log.Error_Message__c = e.getMessage();
        } 
        insert log;
    }
}