@RestResource(urlMapping='/CPLeadInsertionForm/*')
global without sharing class ChannelPartnerLeadInsertAPIController {
    @HttpPost
    global static void createTaskForLead() {
        
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString(); 
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c = 'CPLeadInsertionForm';
        
        try {
            CpWrapper ldData = (CpWrapper) JSON.deserialize(requestBody, CpWrapper.class);
            log.Request__c = requestBody;
            
            // Ensure the required fields are not null
            if (String.isBlank(ldData.lastName) || String.isBlank(ldData.email) || String.isBlank(ldData.CPID) ){
                throw new CustomException('Missing required fields: LastName or Email or CPID');
            }
            
            List<Channel_Partner__c> cpLst = [select id,name,Mobile_Number__c,Approval_Status__c from Channel_Partner__c where name =: ldData.CPID limit 1];
            
            if(cpLst.IsEmpty()){
                throw new CustomException('Channel Partner not found. Please complete your registration and get approval before submitting leads.');
            }
            else{
                if(cpLst[0].Approval_Status__c != 'Approved'){
                    throw new CustomException('Your Channel Partner account is pending approval. You will be able to submit leads once your account is approved.');
                }
            }
            /* ================= Duplicate Check ================= */
            // Detect a duplicate enquiry (same mobile). Queries are wrapped so that limited
            // access contexts (e.g. a Site guest user) degrade gracefully to lead creation
            // instead of hard-failing. The child sub-query on Site Visit is avoided because
            // guest users cannot traverse the Site_visit__r relationship; Site Visit is
            // queried separately and defensively.
            String responseMessage = '';

            try {
                Id existingLeadId = null;

                List<Lead> ldLst = [SELECT Id FROM Lead WHERE Phone__c = :ldData.mobile OR Secondary_Phone__c = :ldData.mobile LIMIT 1];
                if (!ldLst.isEmpty()) {
                    existingLeadId = ldLst[0].Id;
                } else {
                    List<Related_Source__c> rsLst = [SELECT Id, Slead__c FROM Related_Source__c WHERE Phone__c = :ldData.mobile OR Secondary_Phone__c = :ldData.mobile LIMIT 1];
                    if (!rsLst.isEmpty()) {
                        existingLeadId = rsLst[0].Slead__c;
                    }
                }

                if (existingLeadId != null) {
                    Boolean svCompleted = false;
                    try {
                        svCompleted = ![SELECT Id FROM Site_Visit__c WHERE SLead__c = :existingLeadId AND Status__c = 'Completed' LIMIT 1].isEmpty();
                    } catch (Exception svEx) {
                        svCompleted = false; // Site Visit not accessible in this context
                    }

                    if (svCompleted) {
                        responseMessage =
                            'This enquiry already exists in our database. A site visit has already been completed and the lead is currently under follow-up. As this is a duplicate enquiry, no credit will be given.';
                    } else {
                        responseMessage =
                            'This enquiry already exists in our database. A site visit has not yet been conducted and the lead is currently under follow-up. As this is a duplicate enquiry, no credit will be given.';
                    }
                }
            } catch (Exception dupEx) {
                // Duplicate detection could not run in this context - proceed to create the lead.
                responseMessage = '';
            }

            /* ================= Lead Creation ================= */
            // Publish a platform event so the Lead (and its downstream automation:
            // round robin, owner assignment, related source, etc.) is created by the
            // CP_Lead__e subscriber trigger, which runs as the Automated Process system
            // user with full permissions. A public Site guest user cannot perform those
            // cross-object updates itself, so it only publishes the event here.
            CP_Lead__e ev = new CP_Lead__e();
            ev.CP_Record_Id__c = cpLst[0].Id;
            ev.CP_Name__c      = cpLst[0].Name;
            ev.Last_Name__c    = ldData.lastName;
            ev.Email__c        = ldData.email;
            ev.Mobile__c       = ldData.mobile;
            ev.Country_Code__c = ldData.countryCode;
            ev.Project__c      = ldData.project;
            ev.Remarks__c      = ldData.remarks;
            ev.Description__c  = ldData.description;
            ev.Country__c      = ldData.country;
            ev.State__c        = ldData.state;
            ev.City__c         = ldData.city;
            ev.Comments__c     = ldData.comments;
            EventBus.publish(ev);

            /* ================= Final Response ================= */
            if (String.isBlank(responseMessage)) {
                responseMessage = 'The provided enquiry has been successfully registered. Credit for this lead will be given to the Channel Partner if it converts into a booking within 30 days.';
            }
            
            log.Response__c = responseMessage;
            log.Status__c = 'SUCCESS';
            insert log;
            
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(responseMessage);
            
        }
        catch (Exception e) {
            
            log.Response__c = e.getStackTraceString();
            log.Status__c = 'FAIL';
            log.Error_Message__c = e.getMessage();
            insert log;
            
            RestContext.response.statusCode = 400;
            RestContext.response.responseBody = Blob.valueOf(e.getMessage());
        }
    }

    
    public class CpWrapper {
        public String CPID;
        public String remarks;
        public String lastName;
        public String source;
        public String subSource;
        public String mobile;
        public String email;
        public String countryCode;
        public String project;
        public String unitPreference;
        public String campaign;
        public String description;
        public String medium;
        public String residencelocation;
        public String worklocation;
        public String hearaboutus;
        public String sourceType;
        public String keywords;
        
        /* ===== Newly Added Fields ===== */
        //public String project;
        public String country;
        public String state;
        public String city;
        public String channelPartnerName;
        public String executiveName;
        public String executivePhone;
        public String comments;
    }
    
    public class CustomException extends Exception {}
}