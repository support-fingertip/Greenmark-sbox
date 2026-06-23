public with sharing class ProjectStatusReportController {
    @AuraEnabled
    public static BookingWrapper getBookingRecord(Id recordId) {
        
        BookingWrapper bw = new BookingWrapper();
        
        if (recordId == null) {
            return bw;
        }
        
        /* ================= BOOKING ================= */
        List<Booking__c> bookingList = [
            SELECT Id, First_Applicant_Name__c,S__c,Project1__r.Name,Project__c,Owner_Phone__c,Company_Name__c
            FROM Booking__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        
        if (!bookingList.isEmpty()) {
            bw.booking = bookingList[0];
        }
               
        // 2. Get Template Record (project wise)
        General_Settings__c temp = [
            SELECT Template_Body__c,Type__c FROM General_Settings__c WHERE
            Project_Name1__c INCLUDES (: bookingList[0].Project__c) AND
            Type__c ='PSR Mail Template' LIMIT 1
        ];
        bw.template = temp;
        
        /* ================= BOOKING ================= */
        List<Co_Applicant__c> coApplicant = [
            SELECT Name
            FROM Co_Applicant__c
            WHERE Booking__c = :recordId
            LIMIT 1
        ];
        
        if (!coApplicant.isEmpty()) {
            bw.coApplicant = coApplicant[0];
        }
        
        
        
        /* ================= PAYMENT SCHEDULES ================= */
        List<Payment_Schedule__c> allSchedules = [
            SELECT Id, Name, status__c, S_No__c,
            Completed_Date__c, Payment_percent__c
            FROM Payment_Schedule__c
            WHERE Booking__c = :recordId
            ORDER BY S_No__c ASC
        ];
        system.debug('allSchedules==>'+allSchedules);
        
        bw.paymentSchdules = allSchedules;
        
        /* ================= LAST COMPLETED MILESTONE ================= */
        for (Integer i = allSchedules.size() - 1; i >= 0; i--) {
            if (allSchedules[i].status__c == 'Completed') {
                bw.currentMilestone = allSchedules[i];
                break;
            }
        }
        
        return bw;
    }    
    public class BookingWrapper {
        @AuraEnabled
        public Booking__c booking { get; set; }
        @AuraEnabled
        public Payment_Schedule__c currentMilestone { get; set; }
        @AuraEnabled
        public List<Payment_Schedule__c> paymentSchdules { get; set; }
        @AuraEnabled
        public Co_Applicant__c coApplicant { get; set; }
        @AuraEnabled
        public General_Settings__c template { get; set; }
    }
    @AuraEnabled
    public static List<Id> getScheduleFiles(Id paymentScheduleId) {
        
        List<Id> recordIds = new List<Id>();
        
        if(paymentScheduleId == null) {
            return recordIds;
        }
        
        /* ================= Get Payment Schedule ================= */
        Payment_Schedule__c ps = [
            SELECT Id, Master_Payment_Schedule__c
            FROM Payment_Schedule__c
            WHERE Id = :paymentScheduleId
            LIMIT 1
        ];
        
        recordIds.add(ps.Id);
        
        if(ps.Master_Payment_Schedule__c != null) {
            recordIds.add(ps.Master_Payment_Schedule__c);
        }
        
        /* ================= Fetch Files ================= */
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :recordIds
        ];
        
        List<Id> documentIds = new List<Id>();
        for(ContentDocumentLink cdl : links){
            documentIds.add(cdl.ContentDocumentId);
        }
        
        return documentIds;
    }
    
    
    @AuraEnabled
    public static void sendPSREmail(
        Id bookingId, 
        Id paymentScheduleId, 
        String messageBody, 
        List<String> fileDocumentIds
    ) {
        Booking__c booking = [SELECT Email__c,Project__c,Block_Name__c,Unit_No__c, Name,
            CRM_Head__c, CRM_Head__r.Email, CRM_Manager__c, CRM_Manager__r.Email,
            Project_Sales_Head__c, Project_Sales_Head__r.Email,
            Sales_Head__c, Sales_Head__r.Email, OwnerId, Owner.Email
            FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        Payment_Schedule__c schedule = [SELECT Name FROM Payment_Schedule__c WHERE Id = :paymentScheduleId LIMIT 1];
        String email = booking.Email__c;
        
        if(String.isBlank(email)) {
            throw new AuraHandledException('No customer email found.');
        }
        
        
        // 2. Get Template Record (project wise)
        General_Settings__c temp = [
            SELECT Subject__c,Type__c FROM General_Settings__c WHERE    Project_Name1__c INCLUDES (:booking.Project__c)  AND
            Type__c ='PSR Mail Template' LIMIT 1
        ];
        String subject = temp.Subject__c;
        // Project
        subject = subject.replace(
            '##PROJECT_NAME##',
            booking.Project__c != null ? booking.Project__c : ''
        );
        
        // -------- UNIT DETAILS--------
        // BLOCK_NAME
        subject = subject.replace(
            '##BLOCK_NAME##',
            booking.Block_Name__c != null ? String.valueOf(booking.Block_Name__c) : ''
        );
        
        // BLOCK_NAME
        subject = subject.replace(
            '##UNIT_NUMBER##',
            booking.Unit_No__c != null ? String.valueOf(booking.Unit_No__c) : ''
        );
        
        string displayName = label.Default_Email_Address_Label;
        //sender using Org-Wide Email Addres
        OrgWideEmailAddress owea = [
            SELECT Id 
            FROM OrgWideEmailAddress 
            WHERE DisplayName =:displayName 
            LIMIT 1
        ];
 

        // Send Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        List<String> toAddresses = new List<String>{ email };
            List<Co_Applicant__c> coApplicants = [
                SELECT Email__c
                FROM Co_Applicant__c
                WHERE Booking__c = :booking.Id
                ORDER BY CreatedDate ASC
            ];
        for (Co_Applicant__c cpp : coApplicants) {
            if (String.isNotBlank(cpp.Email__c)) {
                toAddresses.add(cpp.Email__c);
            }
        }
        mail.setToAddresses(toAddresses);
        Set<String> ccSet = BookingCCEmailUtil.getCCEmails(booking);
        if (!ccSet.isEmpty()) {
            mail.setCcAddresses(new List<String>(ccSet));
        }
        mail.setSaveAsActivity(true);
        mail.setWhatId(booking.Id);
        String EnableOrgWideEmailToMails = Label.EnableOrgWideEmailToMails;
        if (owea != null && EnableOrgWideEmailToMails == 'True') {
            mail.setOrgWideEmailAddressId(owea.Id);
        }
        else {
            // fallback to default OWA
            mail.setSenderDisplayName(UserInfo.getName());
            mail.setReplyTo(UserInfo.getUserEmail());
        }
        mail.setSubject(subject);
        mail.setHtmlBody(messageBody);
        
        
        // Attach files
        if(fileDocumentIds != null && fileDocumentIds.size() > 0){
            List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
            if (!fileDocumentIds.isEmpty()) {
                List<ContentVersion> contentVersions = [SELECT Title,FileExtension, VersionData FROM ContentVersion WHERE ContentDocumentId IN :fileDocumentIds];
                for (ContentVersion cv : contentVersions) {
                    Messaging.EmailFileAttachment contentAttach = new Messaging.EmailFileAttachment();
                    String fileNameWithExtension = cv.Title + '.' + cv.FileExtension;
                    contentAttach.setFileName(fileNameWithExtension);
                    contentAttach.setBody(cv.VersionData);
                    emailAttachments.add(contentAttach);
                }
            }
            if (!emailAttachments.isEmpty()) {
                mail.setFileAttachments(emailAttachments);
            }
        }
      
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    }
}