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
            Lead nld = new Lead();
            nld.LastName = ldData.lastName;
            nld.Lead_source__c = 'Channel Partner';
            nld.Channel_Partner__c = cpLst[0].Id;
            nld.Source_Type__c = 'Channel Partner';
            nld.Sub_Source__c = cpLst[0].Name;
            
            nld.Country_Code__c = ldData.countryCode;
            nld.Phone = (ldData.mobile != null && ldData.mobile.length() > 10)? ldData.mobile.substring(ldData.mobile.length() - 10): ldData.mobile;
            nld.Phone__c = nld.Phone;
            
            nld.Email = ldData.email;
            nld.Allocated_project__c = ldData.project;
            nld.Last_Note__c = ldData.remarks;
            nld.Description = ldData.description;
            nld.Company = 'Greenmark Developers';
            
            /* ===== Newly Added Fields ===== */
            nld.Country__c = ldData.country;
            nld.State__c = ldData.state;
            nld.City__c = ldData.city;
            nld.Comments__c = ldData.comments;
            
            insert nld;
            
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