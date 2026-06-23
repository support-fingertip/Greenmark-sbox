public class ChannelPartnerLeadInsert {
public string status{get;set;}
    public void captureLead(){
        string cpName =   apexpages.currentpage().getparameters().get('cpId');
        string LeadName = apexpages.currentpage().getparameters().get('leadName'); 
        string email = apexpages.currentpage().getparameters().get('email'); 
        string countryCode = apexpages.currentpage().getparameters().get('countryCode');
        string mobile = apexpages.currentpage().getparameters().get('mobile');
        string mobile2 = apexpages.currentpage().getparameters().get('mobile2');
        string countryCode2 = apexpages.currentpage().getparameters().get('countryCode2');
        string project = apexpages.currentpage().getparameters().get('project');
     
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'Channel Partner Lead';
       
        List<Channel_Partner__c> cplist = [Select Id, Name, ContactPerson__c From Channel_Partner__c where Name =: cpName or ContactPerson__c =: cpName];
        Lead l = new Lead();
        l.LastName = LeadName;
        l.Phone__c = mobile;
        l.Secondary_Phone__c = mobile2;
        if(countryCode != null){
            l.Country_Code__c = countryCode;
        }
        if(cplist != null && cplist.size()>0){
            l.Channel_Partner__c = cplist[0].id;
        }
        l.Secondary_Country_Code__c = countryCode2;
        if(email != null && email != ''){
            Pattern emailPattern = Pattern.compile('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$');
            Matcher emailMatcher = emailPattern.matcher(email);
            if (emailMatcher.matches()) {
                l.Email = email;
            } else {
                l.Email = null; 
            }
        }
        
        l.CP_Id__c = cpName;
        l.Lead_source__c = 'Channel Partner';
     l.Source_Type__c = 'Channel Partner';
        l.Sub_Source__c = cpName;
        l.Allocated_Project__c = project;
       // l.Notes__c = notes;
      //  l.Submitter_Name__c = submitName;
      //  l.Submitter_Phone__c = submitterphoneNumber;
      //  l.Submitter_Email__c = submitemail;
        try{
            insert l;  
            List<Lead> ldList = [Select Id,Name from Lead where Id =: l.Id];
            if(ldList.size() == 1){
                status = 'Lead has been created and Salesforce Lead Id is ' +l.id;
            }else{
               status = 'Lead already exists in the system';
            }
            log.status__c='SUCCESS'; 

        }catch(exception e){
            status = 'FAIL '+e.getMessage();
            log.status__c='FAILED';
            log.Error_Message__c = e.getMessage();
        } 
        insert log;
    }
}