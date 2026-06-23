/****************************************************************
* Class Name   : WebhookLeadAPI
* Company      : Fingertipplus
* Created Date : 15-12-2025
* @description : This class is used for Integration with webhook URL in lead forms for Capturing the Lead into Salesforce 
* @author      : Mayuri Patel

* Change Log:
* -----------------------------------------------------------------------------
* Ver | Author 			| 	  Date 		| Description
* -----------------------------------------------------------------------------
* 1.0 | Mayuri Patel 	| 15-12-2025 	| Initial version
* -----------------------------------------------------------------------------
**************************************************************/
@RestResource(urlMapping='/WebhookLead/*')
global without sharing class WebhookLeadAPI {
     @HttpPost
    global static void createLead() {
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString(); // Get the JSON body
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c ='WebhookLeadAPI '+' createLead';
         system.debug('requestBody:' + requestBody);
        
        try {
            // Deserialize the JSON body into the callWrapper class
            leadWrapper ldData = (leadWrapper) JSON.deserialize(requestBody, leadWrapper.class);
            system.debug('Lead:' + ldData);
            log.Request__c=requestBody;
            // Create a new Lead using the deserialized data
            Lead nld = new Lead();
           // nld.FirstName = ldData.f_name;
            nld.LastName = ldData.f_name;
            nld.Source_Type__c = ldData.source == null || ldData.source == '' ? 'Website' : ldData.source;
            nld.Lead_source__c = ldData.subSource == null || ldData.subSource == '' ? 'Website Lead Form' : ldData.subSource;
            nld.Sub_Source__c = nld.Lead_source__c;
            nld.Phone = ldData.phonefax;
            nld.Phone__c = ldData.phonefax;
            nld.Email = ldData.email;
            nld.Allocated_project__c = ldData.project;
            nld.Description = ldData.description;
                           
            insert nld;
            // Return success response
            log.response__c = string.valueof(nld);
            log.Status__c ='SUCCESS';
            insert log;
            
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'success' => true,
                    'Salesforce LeadId' => nld.Id
                    }));
        } catch (Exception e) {
            log.response__c = e.getStackTraceString();
            log.Status__c ='FAIL';
            log.Error_Message__c = e.getMessage();
            insert log;
            
            System.debug('Error creating task: ' + e.getMessage());
            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf('Error: ' + e.getMessage());
        }
    }
    
    // Wrapper class for deserialization
    public class leadWrapper {
        public String f_name;
        public String l_name;
        public String source;
        public String subSource;
        public String mobile;
        public String phonefax;
        public String email;
        public String project;
        public String description;
        
    }
    
         
    
}