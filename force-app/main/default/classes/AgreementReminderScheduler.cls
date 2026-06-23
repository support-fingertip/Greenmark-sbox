global class AgreementReminderScheduler implements Schedulable {
    global void execute(SchedulableContext context) {
        
        List<Booking__c> bookings = [SELECT Id, Agreement_Extension_Approved_Date__c, CRM_Executive__r.Email, Plot__r.Name,Time_Extension_Requested__c,
                                     Time_Extension_Approval_Status__c, Project1__r.Name, Email__c,Agreement_Execution_Date__c,Block_Name__c,
                                     Company_Name__c,Owner_Phone__c,
                                     Unit_No__c ,First_Applicant_Name__c,Owner_Full_Name__c,CRM_Head__r.Email,Sales_Head__r.Email,COO__r.Email FROM Booking__c 
                                     WHERE Time_Extension_Requested__c = true AND  Disable_Automatic_Agreement_Reminders__c != true AND 
                                     Agreement_Reminder_Date__c = :Date.today() AND Agreement_Status__c = 'Not Scheduled' AND Stage__c NOT IN ('Unit Swap', 'Cancellation')];
        
               // Fetch Templates (Correct Type__c values)
        List<General_Settings__c> allTemplates = [
            SELECT Template_Body__c, Subject__c, Type__c, Project_Name1__c FROM General_Settings__c WHERE Type__c =:'Agreement Remainder'
        ];
        string displayName = label.Default_Email_Address_Label;
        //sender using Org-Wide Email Addres
        OrgWideEmailAddress owea = [
            SELECT Id 
            FROM OrgWideEmailAddress 
            WHERE DisplayName =:displayName 
            LIMIT 1
        ];
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        // Removed unused cancelBookings list
        for (Booking__c booking : bookings) {
            // Null check for recipient email
            if (booking.Email__c == null) {
                continue;
            }
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { booking.Email__c });
            // Null check for CRM_Executive__r
            String EnableOrgWideEmailToMails = Label.EnableOrgWideEmailToMails;
            if (owea != null && EnableOrgWideEmailToMails == 'True') {
                mail.setOrgWideEmailAddressId(owea.Id);
            }
            if (allTemplates.isEmpty()) continue;
            General_Settings__c temp = allTemplates[0];
            String template = temp.Template_Body__c;
            String subject  = temp.Subject__c;
            String projectName = booking.Project1__r != null ? booking.Project1__r.Name : '';
            subject = subject.replace('##PROJECT_NAME##', projectName ?? '');
            subject = subject.replace('##BLOCK_NAME##',  booking.Block_Name__c ?? '');
            subject = subject.replace('##UNIT_NUMBER##',  booking.Unit_No__c ?? '');
            // Replace merge fields
            template = template.replace('##APPLICANT_NAME##', booking.First_Applicant_Name__c ?? '');
            template = template.replace('##PROJECT_NAME##', projectName ?? '');
            template = template.replace('##COMPANY_NAME##', booking.Company_Name__c ?? '');
            template = template.replace('##CRM_PHONE##', booking.Owner_Phone__c ?? '');
            template = template.replace('##UNIT_NUMBER##',  booking.Unit_No__c ?? '');
            
            String cleanHtml = template.unescapeHtml4();
            
            // Remove empty paragraphs like <p>&nbsp;</p> or <p> </p>
            cleanHtml = cleanHtml.replaceAll('(?i)<p>(\\s|&nbsp;)*</p>', '');
            
            // Also normalize multiple <br>
            cleanHtml = cleanHtml.replaceAll('(<br\\s*/?>\\s*){2,}', '<br/>');
        
            String body = '<html><body style="font-family: Arial; font-size:14px;">' + cleanHtml + '</body></html>';
            mail.setSubject(subject);
            mail.setHtmlBody(body);
            emails.add(mail);
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}