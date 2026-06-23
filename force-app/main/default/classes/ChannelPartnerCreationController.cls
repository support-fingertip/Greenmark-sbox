@RestResource(urlMapping='/ChannelPartner/*')
global with sharing class ChannelPartnerCreationController {
     @HttpPost
    global static void createChannelparnter() {
         RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString(); // Get the JSON body
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c ='ChannelPartnerCreationController';
        
        try {
            // Deserialize the JSON body into the callWrapper class
            CpWrapper ldData = (CpWrapper) JSON.deserialize(requestBody, CpWrapper.class);
            log.Request__c=requestBody;
             String cpName = ldData.cpName;
            String contactPerson = ldData.contactPerson;
             String registration = ldData.registration;
            String mobile = ldData.mobile;
             String email = ldData.email;
            String rera = ldData.rera;
             String pan = ldData.pan;
            String gst = ldData.gst;
            
            if (String.isBlank(cpName) || String.isBlank(registration)|| String.isBlank(mobile)|| String.isBlank(rera)|| String.isBlank(pan)|| String.isBlank(gst)) {
                log.response__c = 'Check CP Name, Registration, Mobile, RERA, PAN and GST Vailid.';
                log.Status__c ='SUCCESS';
                insert log;
                
                sendErrorResponse('Please Check CP Name, Registration, Mobile, RERA, PAN and GST Vailid.');
                return;
            }
            
            Channel_Partner__c cp =new Channel_Partner__c();
            //cp.Name= cpName;
            cp.Registraction_No__c=registration;
            cp.ContactPerson__c =contactPerson;
            cp.Mobile_Number__c = mobile;
            cp.RERA__c=rera;
            cp.PAN__c = pan;
            cp.GST__c = gst;
            cp.Email__c = email;
            
            insert cp;
            
            
            log.response__c = string.valueof(cp);
            log.Status__c ='SUCCESS';
            insert log;
            
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                'success' => true,
                    'Salesforce LeadId' => cp.Id
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
    public class CpWrapper {
        public String cpName;
        public String contactPerson;
        public String registration;
        public String mobile;
        public String email;
        public String rera;
        public String pan;
        public String gst;
    }
    private static void sendErrorResponse(String message) {
        RestContext.response.statusCode = 400;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'status' => false,
                'message' => message
                }));
    }

}