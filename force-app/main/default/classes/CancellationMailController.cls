public class CancellationMailController {
    public class DataBox {
        @auraEnabled public Booking__c bookingRecord;
        @auraEnabled public String emailTemplate;
        @auraEnabled public boolean isAggementDateExisted;
    }
    /**
    * Method Name  : getRecordData
    * Description  : Fetches Booking data and prepares merged Welcome Email template.
    *
    * Functionality:
    * 1. Retrieves Booking__c record based on provided recordId.
    * 2. Fetches project-specific email template from General_Settings__c 
    *    where Type__c = 'Welcome Email Template'.
    * 3. Performs merge operation by replacing placeholders with Booking values:
    *      ##APPLICANT_NAME##
    *      ##PROJECT_NAME##
    *      ##BLOCK_NAME##
    *      ##UNIT_NUMBER##
    *      ##SALEABLE_AREA##
    *      ##CARPET_AREA##
    *      ##AGREEMENT_DATE##
    *      ##CRM_NAME##
    *      ##CRM_PHONE##
    *      ##CRM_EMAIL##
    *      ##SIGNATURE##
    * 4. Prepares final HTML content and wraps it inside DataBox object.
    *
    * Parameters:
    * @param recordId - Id of Booking__c record
    *
    * Returns:
    * @return DataBox - Wrapper containing:
    *         - bookingRecord : Booking__c record
    *         - emailTemplate : Merged HTML email body
    *
    * Used From:
    * - LWC component for previewing Welcome Email
    * - Email send screen before confirmation
    */
    @AuraEnabled
    public static DataBox getRecordData(Id recordId) {
        DataBox db = new DataBox();
        // 1. Get Booking Data
        Booking__c bk =  [SELECT Id,Name,Franking_Amount__c,First_Applicant_Name__c,Swap_Unit_Status__c,Owner_Phone_Number__c,
                          Application_Amount__c,Unit_No__c,Owner_Phone__c, Project__c,Plot__r.Name,Booking_Amount__c,Owner_Email__c,
                          Project1__r.Company_Name__c,S__c,Super_Built_UpArea__c,Carpet_Area__c,Agreement_Expected_Date__c,Company_Name__c,
                          Block_Name__c,Owner_Full_Name__c,Email__c FROM Booking__c WHERE Id = :recordId LIMIT 1];
        db.bookingRecord = bk;
        
        // 2. Get Template Record (project wise)
        General_Settings__c temp = [
            SELECT Template_Body__c,Type__c FROM General_Settings__c WHERE
            Project_Name1__c INCLUDES (:bk.Project__c) AND
            Type__c ='Cancellation Mail Template' LIMIT 1
        ];
        
        
        String template = temp.Template_Body__c;
        
        // ================= MERGE LOGIC =================
        
        // Applicant
        template = template.replace(
            '##APPLICANT_NAME##',
            bk.First_Applicant_Name__c != null ? bk.First_Applicant_Name__c : ''
        );
        
        // Project
        template = template.replace(
            '##PROJECT_NAME##',
            bk.Project__c != null ? bk.Project__c : ''
        );
        
        // -------- UNIT DETAILS (YOU CAN CHANGE THIS LINE ANYTIME) --------
        // BLOCK_NAME
        template = template.replace(
            '##BLOCK_NAME##',
            bk.Block_Name__c != null ? String.valueOf(bk.Block_Name__c) : ''
        );
        
        // BLOCK_NAME
        template = template.replace(
            '##UNIT_NUMBER##',
            bk.Unit_No__c != null ? String.valueOf(bk.Unit_No__c) : ''
        );
        

        
        // Agreement Date
        template = template.replace(
            '##AGREEMENT_DATE##',
            bk.Agreement_Expected_Date__c != null ? String.valueOf(bk.Agreement_Expected_Date__c) : ''
        );
        
        // CRM
        template = template.replace(
            '##CRM_NAME##',
            bk.Owner_Full_Name__c != null ? String.valueOf(bk.Owner_Full_Name__c) : ''
        );
        
        template = template.replace(
            '##CRM_PHONE##',
            bk.Owner_Phone_Number__c != null ? String.valueOf(bk.Owner_Phone_Number__c) : ''
        );
        
        template = template.replace(
            '##CRM_EMAIL##',
            bk.Owner_Email__c != null ? String.valueOf(bk.Owner_Email__c) : ''
        );
        template = template.replace(
            '##COMAPANY_NAME##',
            bk.Company_Name__c != null ? String.valueOf(bk.Company_Name__c) : ''
        );
        
        // Signature – controlled from system
        String sign =
            '<p>Warm Regards,<br/>' +
            '<strong>' + (bk.Owner_Full_Name__c != null ? bk.Owner_Full_Name__c : '') + '</strong><br/>' +
            (bk.Owner_Phone__c != null ? bk.Owner_Phone__c : '') +
            '</p>';
        
        template = template.replace('##SIGNATURE##', sign);
        db.emailTemplate = template;
        return db;
    }
    
     
    /**
    * Method Name  : sendWelcomeEmail
    * Description  : Generates and sends Welcome Email for a Booking record.
    *
    * Functionality:
    * 1. Fetches Booking__c record based on recordId.
    * 2. Fetches project-specific email template from General_Settings__c 
    *    where Type__c = 'Welcome Email Template'.
    * 3. Performs merge logic by replacing placeholders like:
    *      ##APPLICANT_NAME##
    *      ##PROJECT_NAME##
    *      ##BLOCK_NAME##
    *      ##UNIT_NUMBER##
    *      ##SALEABLE_AREA##
    *      ##CARPET_AREA##
    *      ##AGREEMENT_DATE##
    *      ##SIGNATURE##
    * 4. Prepares final HTML email body.
    * 5. Sends email to provided recipients with inline attachments if any.
    *
    * Parameters:
    * @param recordId     - Id of Booking__c record
    * @param toAddresses  - List of recipient email addresses
    * @param contentIds   - List of ContentDocumentIds for attachments (optional)
    *
    * Used From:
    * - LWC Welcome Email component
    * - Manual email send action from Booking record
    *
    * Template Source:
    * - General_Settings__c.Template_Body__c
    * - Filter: Project_Name__c = Booking.Project__c
    *           AND Type__c = 'Welcome Email Template'
    **/
    @AuraEnabled
    public static void sendWelcomeEmail(Id recordId, String emailContent, List<String> toAddresses, List<String> contentIds) {
        system.debug('Content IDs: ' + contentIds);
        Booking__c bk = [SELECT Id, Quote__c,Name, CRM_Manager__c,Project1__r.Name, Owner_Phone__c,CRM_Head__c,
                         Project_Sales_Head__c, Project_Sales_Head__r.Email,Sales_Head__c, Sales_Head__r.Email,
                         CRM_Head__r.Email, CRM_Manager__r.Email, First_Applicant_Name__c, Email__c, 
                         Project__c,Block_Name__c,Unit_No__c,Project_Type__c,
                         (SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks 
                          WHERE ContentDocumentId IN :contentIds) 
                         FROM Booking__c 
                         WHERE Id = :recordId 
                         LIMIT 1];
        Payment_Schedule__c ps = [select id from Payment_Schedule__c where Booking__c =: bk.Id AND S_No__c = 1];
        List<String> lstCCEmail = new List<String>();
        
        if (bk != null && bk.Email__c != null) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            string displayName = label.Default_Email_Address_Label;
            //sender using Org-Wide Email Addres
            OrgWideEmailAddress owea = [
                SELECT Id 
                FROM OrgWideEmailAddress 
                WHERE DisplayName =:displayName 
                LIMIT 1
            ];
            
            String EnableOrgWideEmailToMails = Label.EnableOrgWideEmailToMails;
            if (owea != null && EnableOrgWideEmailToMails == 'True') {
                mail.setOrgWideEmailAddressId(owea.Id);
            }
            else {
                // fallback to default OWA
                mail.setSenderDisplayName(UserInfo.getName());
                mail.setReplyTo(UserInfo.getUserEmail());
            }
            mail.setSaveAsActivity(true);
            mail.setWhatId(bk.Id);
            
            

            
            List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
            Set<Id> contentDocumentIds = new Set<Id>();
            
            for (ContentDocumentLink docLink : bk.ContentDocumentLinks) {
                contentDocumentIds.add(docLink.ContentDocumentId);
            }
            
            if (!contentDocumentIds.isEmpty()) {
                List<ContentVersion> contentVersions = [SELECT Title,FileExtension, VersionData FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds];
                for (ContentVersion cv : contentVersions) {
                    Messaging.EmailFileAttachment contentAttach = new Messaging.EmailFileAttachment();
                    String fileNameWithExtension = cv.Title + '.' + cv.FileExtension;
                    contentAttach.setFileName(fileNameWithExtension);
                    contentAttach.setBody(cv.VersionData);
                    emailAttachments.add(contentAttach);
                }
            }
            
            if(bk.CRM_Head__c!= null){
                lstCCEmail.add(bk.CRM_Head__r.Email);
            }
            if(bk.CRM_Manager__c != null){
                lstCCEmail.add(bk.CRM_Manager__r.Email);
            }
            
            if(bk.Project_Sales_Head__c != null){
                lstCCEmail.add(bk.Project_Sales_Head__r.Email);
            }
            if(bk.Sales_Head__c != null){
                lstCCEmail.add(bk.Sales_Head__r.Email);
            }
            
            // Getting the CC Emails from Custom Label
            String ccEmailLabel = Label.CCEmailIds; // e.g., "durgaprasad@fingertipplus.com,durgaprasadrgukt99@gmail.com"
            
            if(String.isNotBlank(ccEmailLabel)) {
                List<String> labelEmails = ccEmailLabel.split(',');
                for(String email : labelEmails) {
                    lstCCEmail.add(email.trim());
                }
            }
            
            // 2. Get Template Record (project wise)
            General_Settings__c temp = [
                SELECT Subject__c,Type__c FROM General_Settings__c WHERE    Project_Name1__c INCLUDES (:bk.Project__c)  AND
                Type__c ='Cancellation Mail Template' LIMIT 1
            ];
            String subject = temp.Subject__c;
            // Project
            subject = subject.replace(
                '##PROJECT_NAME##',
                bk.Project__c != null ? bk.Project__c : ''
            );
            
            // -------- UNIT DETAILS--------
            // BLOCK_NAME
            subject = subject.replace(
                '##BLOCK_NAME##',
                bk.Block_Name__c != null ? String.valueOf(bk.Block_Name__c) : ''
            );
            
            // BLOCK_NAME
            subject = subject.replace(
                '##UNIT_NUMBER##',
                bk.Unit_No__c != null ? String.valueOf(bk.Unit_No__c) : ''
            );
            
            
            
            mail.setToAddresses(toAddresses);
            if(lstCCEmail.size()>0){
                mail.setCcAddresses(lstCCEmail);
            }
            mail.setSubject(subject);
            mail.setHtmlBody(emailContent);
            if (!emailAttachments.isEmpty()) {
                mail.setFileAttachments(emailAttachments);
            }
            
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            system.debug(results);           
            
            bk.Cancellation_Email_Sent_Time__c = system.now();
            bk.Cancellation_Email_Sent__c = true;
            update bk;
        }
    }
}