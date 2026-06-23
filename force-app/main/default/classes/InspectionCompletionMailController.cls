public class InspectionCompletionMailController {

    @AuraEnabled
    public static Map<String, Object> getEmailData(Id recordId) {
        Map<String, Object> result = new Map<String, Object>();

        Inspection__c ins = [
            SELECT Id, Name, Status__c, Customer_Name__c, Customer_Email__c,
                   Booking__c, Booking__r.Name, Booking__r.First_Applicant_Name__c,
                   Booking__r.Project__c, Booking__r.Block_Name__c, Booking__r.Unit_No__c
            FROM Inspection__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        result.put('customerEmail', ins.Customer_Email__c);
        result.put('customerName', ins.Customer_Name__c);

        String subject = 'Inspection Completed – All Issues Resolved';
        result.put('subject', subject);

        String customerName = ins.Customer_Name__c != null ? ins.Customer_Name__c : 'Sir/Madam';

        String template =
            '<p>Dear ' + customerName + ',</p>' +
            '<p>We are pleased to inform you that the inspection of your property has been successfully completed.</p>' +
            '<p>All the issues (snags) that were reported have been carefully reviewed and resolved.</p>' +
            '<p>If you have any further concerns or require additional assistance, please feel free to reach out to us.</p>' +
            '<p>Thank you for your time and cooperation.</p>' +
            '<p><br/>Warm Regards,<br/>' +
            'CRM Team,<br/>' +
            'Trifecta Projects Pvt Ltd</p>';

        result.put('emailContent', template);

        return result;
    }

    @AuraEnabled
    public static void sendInspectionEmail(Id inspectionId, String emailContent, List<String> contentIds, String subject) {

        Inspection__c ins = [
            SELECT Id, Name, Customer_Name__c, Customer_Email__c,
                   Booking__c, Booking__r.Name, Booking__r.Project__c,
                   Booking__r.Block_Name__c, Booking__r.Unit_No__c,
                   Booking__r.CRM_Head__c, Booking__r.CRM_Head__r.Email,
                   Booking__r.CRM_Manager__c, Booking__r.CRM_Manager__r.Email,
                   Booking__r.Project_Sales_Head__c, Booking__r.Project_Sales_Head__r.Email,
                   Booking__r.Sales_Head__c, Booking__r.Sales_Head__r.Email,
                   Booking__r.OwnerId, Booking__r.Owner.Email
            FROM Inspection__c
            WHERE Id = :inspectionId
            LIMIT 1
        ];

        if (ins.Customer_Email__c == null) {
            throw new AuraHandledException('No customer email address found on this inspection.');
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        String displayName = Label.Default_Email_Address_Label;
        String EnableOrgWideEmailToMails = Label.EnableOrgWideEmailToMails;
        OrgWideEmailAddress owea = [
            SELECT Id
            FROM OrgWideEmailAddress
            WHERE DisplayName = :displayName
            LIMIT 1
        ];
        if (owea != null && EnableOrgWideEmailToMails == 'True') {
            mail.setOrgWideEmailAddressId(owea.Id);
        }  else {
            // fallback to default OWA
            mail.setSenderDisplayName(UserInfo.getName());
            mail.setReplyTo(UserInfo.getUserEmail());
        }

        list<String> toEmails = new  list<String>();
        // Recipients in To
        if (ins.Customer_Email__c!= null) {
            toEmails.add(ins.Customer_Email__c);
        }
        List<Co_Applicant__c> coApplicants = [
            SELECT Id, Name, Email__c, Booking__c
            FROM Co_Applicant__c
            WHERE Booking__c = :ins.Booking__c
        ];
        
        
        for (Co_Applicant__c coApp : coApplicants) {
            if (coApp.Email__c != null) {
                toEmails.add(coApp.Email__c);
            }
        }
        
        mail.setToAddresses(toEmails);

        Set<String> ccSet = BookingCCEmailUtil.getCCEmails(ins.Booking__r);
        if (!ccSet.isEmpty()) {
            mail.setCcAddresses(new List<String>(ccSet));
        }

        mail.setSubject(subject);
        mail.setHtmlBody(emailContent);
        mail.setSaveAsActivity(true);
        mail.setWhatId(ins.Booking__c);

        if (contentIds != null && !contentIds.isEmpty()) {
            Set<Id> contentDocumentIds = new Set<Id>();
            for (String cId : contentIds) {
                contentDocumentIds.add(Id.valueOf(cId));
            }

            List<ContentVersion> contentVersions = [
                SELECT Title, FileExtension, VersionData
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocumentIds
                AND IsLatest = true
            ];

            List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
            for (ContentVersion cv : contentVersions) {
                Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                attach.setFileName(cv.Title + '.' + cv.FileExtension);
                attach.setBody(cv.VersionData);
                emailAttachments.add(attach);
            }

            if (!emailAttachments.isEmpty()) {
                mail.setFileAttachments(emailAttachments);
            }
        }

        List<Messaging.SendEmailResult> results = Messaging.sendEmail(
            new Messaging.SingleEmailMessage[] { mail }
        );
        ins.Snags_Completion_Email_Sent_Date__c = system.today();
        ins.Snags_Completion_Email_Sent__c = true;
        update ins;
        System.debug('Inspection Email Results: ' + results);
    }
}