global class PendingPaymentReminderScheduler implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    // Priority: first match wins per booking
    private static final List<String> PRIORITY = 
        new List<String>{
            'Demand_3RD_REMINDER',
            'Demand_2ND_REMINDER',
            'Demand_1ST_REMINDER'
        };

    // Stateful Counters
    private Integer totalEmailsSent = 0;
    private Integer customerEmailsSent = 0;
    private Integer internalEmailsSent = 0;
    private Integer bookingsProcessed = 0;
    private Integer bookingsCancelled = 0;

    private Map<String, Integer> emailsByType =  new Map<String, Integer>{ 'Demand_1ST_REMINDER' => 0, 'Demand_2ND_REMINDER' => 0, 'Demand_3RD_REMINDER' => 0 };

    // ================= START =================
    global Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id, Pending_Amount__c, S_No__c, Booking__c,
            Received_Amount1__c, Demanded_Date__c,
            X1st_Reminder_Date__c, X2nd_Reminder_Date__c,
            X3rd_Interest_Reminder_Date__c,
            Booking__r.First_Applicant_Name__c,
            Booking__r.Email__c,
            Booking__r.Plot__r.Name,
            Booking__r.Project1__r.Name,
            Booking__r.Owner_Full_Name__c,
            Booking__r.CRM_Head__r.Email,
            Booking__r.Sales_Head__r.Email,
            Booking__r.COO__r.Email,
            Booking__r.CRM_Executive__r.Email,
            Booking__r.Stage__c,
            Booking__r.CRM_Executive_Contact_No__c,
            Booking__r.Unit_No__c,
            Booking__r.Block_Name__c,
            Booking__r.Disable_Automatic_Payment_Reminders__c,
            Booking__r.Company_Name__c,
            Booking__r.Owner_Phone__c,
            Booking__r.Mobile__c,
            Booking__r.Owner_Email__c
            FROM Payment_Schedule__c
            WHERE Is_Demanded__c = true
            AND Pending_Amount__c > 0
            AND Booking__r.Stage__c NOT IN ('Swapping', 'Cancellation')
            AND Booking__r.Disable_Automatic_Payment_Reminders__c != true
            AND Demanded_Date__c != null
            AND (
                X1st_Reminder_Date__c = TODAY
                OR X2nd_Reminder_Date__c = TODAY
                OR X3rd_Interest_Reminder_Date__c = TODAY
            )
            ORDER BY Booking__c, S_No__c ASC
        ]);
    }
    
    // ================= EXECUTE =================
    global void execute(Database.BatchableContext bc, List<Payment_Schedule__c> scope) {
        
        Date today = Date.today();
        
        // Fetch Templates (Correct Type__c values)
        List<General_Settings__c> allTemplates = [
            SELECT Template_Body__c, Subject__c, Type__c, Project_Name1__c
            FROM General_Settings__c
            WHERE Type__c IN (
                'Demand_1ST_REMINDER',
                'Demand_2ND_REMINDER',
                'Demand_3RD_REMINDER'
            )
        ];
        
        // Set OrgWideEmailAddress
        List<OrgWideEmailAddress> orgWideEmail =
            [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Trifecta Admin' LIMIT 1];
        
        // Build Project → Reminder → Template Map
        Map<String, Map<String, General_Settings__c>> projectTemplateMap =
            new Map<String, Map<String, General_Settings__c>>();
        
        for (General_Settings__c gs : allTemplates) {
            
            if (String.isBlank(gs.Project_Name1__c)) continue;
            
            for (String project : gs.Project_Name1__c.split(';')) {
                
                project = project.trim();
                
                if (!projectTemplateMap.containsKey(project)) {
                    projectTemplateMap.put(project,
                                           new Map<String, General_Settings__c>());
                }
                
                projectTemplateMap.get(project).put(gs.Type__c, gs);
            }
        }
        
        // Group schedules by booking
        Map<Id, List<Payment_Schedule__c>> bookingToSchedules =
            new Map<Id, List<Payment_Schedule__c>>();
        
        for (Payment_Schedule__c ps : scope) {
            System.debug('ps==>' + ps);
            if (ps.Booking__c == null) continue;
            
            if (!bookingToSchedules.containsKey(ps.Booking__c)) {
                bookingToSchedules.put(ps.Booking__c,
                                       new List<Payment_Schedule__c>());
            }
            
            bookingToSchedules.get(ps.Booking__c).add(ps);
        }
        
        List<Messaging.SingleEmailMessage> emails =
            new List<Messaging.SingleEmailMessage>();
        
        Integer batchCustomerEmails = 0;
        Integer batchInternalEmails = 0;
        
        // Track email index → schedule IDs and reminder type for precise success tracking
        Map<Integer, List<Id>> emailIndexToScheduleIds = new Map<Integer, List<Id>>();
        Map<Integer, String> emailIndexToReminderType  = new Map<Integer, String>();

        // Collect bookings to notify via WhatsApp. Batch Apex only allows ONE
        // queueable enqueue per execute(), so we enqueue once after the loop.
        List<Booking__c> bookingsForNotification = new List<Booking__c>();

        for (Id bookingId : bookingToSchedules.keySet()) {

            List<Payment_Schedule__c> schedules =
                bookingToSchedules.get(bookingId);
            System.debug('schedules==>' + schedules);

            if (schedules.isEmpty()) continue;

            Booking__c booking = schedules[0].Booking__r;
            if (booking == null) continue;

            bookingsForNotification.add(booking);

            String reminderType =
                determineReminderTypeForBooking(schedules, today);
            
            if (String.isBlank(reminderType)) continue;
            
            bookingsProcessed++;
            emailsByType.put(reminderType,
                             emailsByType.get(reminderType) + 1);
            
            String projectName =
                booking.Project1__r != null ?
                booking.Project1__r.Name : '';
            
            if (!projectTemplateMap.containsKey(projectName)) continue;
            
            Map<String, General_Settings__c> reminderMap =
                projectTemplateMap.get(projectName);
            
            if (reminderMap == null) continue;
            
            General_Settings__c temp = reminderMap.get(reminderType);
            
            if (temp == null) continue;
            
            String template = temp.Template_Body__c;
            String subject  = temp.Subject__c;
            
            subject = subject.replace('##PROJECT_NAME##', projectName ?? '');
            subject = subject.replace('##BLOCK_NAME##',   booking.Block_Name__c ?? '');
            subject = subject.replace('##UNIT_NUMBER##',  booking.Unit_No__c ?? '');
            
            // Replace merge fields
            template = template.replace('##APPLICANT_NAME##',
                                        booking.First_Applicant_Name__c ?? '');
            
            template = template.replace('##PROJECT_NAME##',
                                        projectName ?? '');
            
            template = template.replace('##COMPANY_NAME##',
                                        booking.Company_Name__c ?? '');
            
            template = template.replace('##CRM_PHONE##',
                                        booking.Owner_Phone__c ?? '');
            
            String cleanHtml = template.unescapeHtml4();
            System.debug('cleanHtml' + cleanHtml);
            
            // Remove empty paragraphs like <p>&nbsp;</p> or <p> </p>
            cleanHtml = cleanHtml.replaceAll('(?i)<p>(\\s|&nbsp;)*</p>', '');
            
            // Normalize multiple <br>
            cleanHtml = cleanHtml.replaceAll('(<br\\s*/?>\\s*){2,}', '<br/>');
            
            String body =
                '<html><body style="font-family: Arial; font-size:14px;">'
                + cleanHtml +
                '</body></html>';
            
            // ========== CUSTOMER EMAIL ==========
            if (!String.isBlank(booking.Email__c)) {
                System.debug('booking.Email__c' + booking.Email__c);
                
                Messaging.SingleEmailMessage mail =
                    new Messaging.SingleEmailMessage();
                
                mail.setToAddresses(new String[] { booking.Email__c });
                mail.setSubject(subject);
                
                if (!orgWideEmail.isEmpty()) {
                    mail.setOrgWideEmailAddressId(orgWideEmail[0].Id);
                }
                
                mail.setHtmlBody(body);
                mail.setSaveAsActivity(false);
                
                // ===== Generate PDF =====
                PageReference pdfPage = Page.DemandNote;
                pdfPage.getParameters().put('Id', booking.Id);
                pdfPage.getParameters().put('reminderType', reminderType);
                
                Blob pdfBlob = pdfPage.getContentAsPDF();
                
                Messaging.EmailFileAttachment attachment =
                    new Messaging.EmailFileAttachment();
                
                attachment.setFileName('DemandNote.pdf');
                attachment.setBody(pdfBlob);
                attachment.setContentType('application/pdf');
                
                mail.setFileAttachments(
                    new Messaging.EmailFileAttachment[] { attachment });
                
                // Track this email's index → schedule IDs + reminderType
                Integer emailIndex = emails.size();
                
                List<Id> psIds = new List<Id>();
                for (Payment_Schedule__c ps : schedules) {
                    psIds.add(ps.Id);
                }
                emailIndexToScheduleIds.put(emailIndex, psIds);
                emailIndexToReminderType.put(emailIndex, reminderType);
                
                emails.add(mail);
                batchCustomerEmails++;
            }
        }
        
        // ========== SEND EMAILS ==========
        if (!emails.isEmpty()) {
            System.debug('Entered to Mails');
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);
            
            List<Payment_Schedule__c> schedulesToUpdate =
                new List<Payment_Schedule__c>();
            
            for (Integer i = 0; i < results.size(); i++) {
                
                if (results[i].isSuccess()) {
                    System.debug('Email Sent Successfully for index: ' + i);
                    
                    String reminder  = emailIndexToReminderType.get(i);
                    List<Id> psIds   = emailIndexToScheduleIds.get(i);
                    
                    if (psIds != null && !String.isBlank(reminder)) {
                        for (Id psId : psIds) {
                            Payment_Schedule__c psUpdate =
                                new Payment_Schedule__c(Id = psId);
                            
                            if (reminder == 'Demand_1ST_REMINDER') {
                                psUpdate.X1st_Reminder_Sent__c = true;
                            } else if (reminder == 'Demand_2ND_REMINDER') {
                                psUpdate.X2nd_Reminder_Sent__c = true;
                            } else if (reminder == 'Demand_3RD_REMINDER') {
                                psUpdate.X3rd_Reminder_Sent__c = true;
                            }
                            
                            schedulesToUpdate.add(psUpdate);
                        }
                    }
                    
                } else {
                    for (Messaging.SendEmailError e : results[i].getErrors()) {
                        System.debug('Email Error at index ' + i + ': ' + e.getMessage());
                    }
                }
            }
            
            // Update reminder flags only for successfully sent emails
            if (!schedulesToUpdate.isEmpty()) {
                update schedulesToUpdate;
            }
            
            totalEmailsSent     += emails.size();
            customerEmailsSent  += batchCustomerEmails;
            internalEmailsSent  += batchInternalEmails;
        }

        // Batch Apex permits only one queueable job per execute(); enqueue once
        // with the full booking list rather than per-booking inside the loop.
        if (!bookingsForNotification.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(
                new WhatsappController(bookingsForNotification, '9'));
        }
    }
    
    // ================= FINISH =================
    global void finish(Database.BatchableContext bc) {
        sendAdminSummaryEmail();
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(
            new PendingPaymentReminderScheduler(), 100);
    }

    // ================= REMINDER LOGIC =================
    private static String determineReminderTypeForBooking(
        List<Payment_Schedule__c> schedules,
        Date today) {

        Set<String> matches = new Set<String>();

        for (Payment_Schedule__c ps : schedules) {

            if (ps.X1st_Reminder_Date__c == today)
                matches.add('Demand_1ST_REMINDER');

            if (ps.X2nd_Reminder_Date__c == today)
                matches.add('Demand_2ND_REMINDER');

            if (ps.X3rd_Interest_Reminder_Date__c == today)
                matches.add('Demand_3RD_REMINDER');
        }

        for (String t : PRIORITY) {
            if (matches.contains(t)) return t;
        }

        return null;
    }

    // -------------------- ADMIN SUMMARY EMAIL --------------------
    private void sendAdminSummaryEmail() {
        System.debug('=== Sending Admin Summary Email ===');
        
        // Get admin email from custom settings or organization-wide email
        // For now, using a placeholder - replace with actual admin email retrieval
        String adminEmail = 'durgaprasad@fingertipplus.com'; // TODO: Replace with actual admin email
        
        System.debug('Admin Email: ' + adminEmail);
        
        String subject = 'Payment Reminder Batch Job Summary - ' + Date.today().format();
        
        String body = ''
            + '<h2>Payment Reminder Batch Job Execution Summary</h2>'
            + '<p><strong>Execution Date:</strong> ' + DateTime.now().format('dd-MMM-yyyy HH:mm:ss') + '</p>'
            + '<hr/>'
            + '<h3>Overall Statistics</h3>'
            + '<table style="border-collapse: collapse; border: 1px solid #ddd; width: 100%;">'
            + '<tr style="background-color: #f2f2f2;"><td style="padding: 8px; border: 1px solid #ddd;"><strong>Total Bookings Processed</strong></td><td style="padding: 8px; border: 1px solid #ddd;">' + bookingsProcessed + '</td></tr>'
            + '<tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>Total Emails Sent</strong></td><td style="padding: 8px; border: 1px solid #ddd;">' + totalEmailsSent + '</td></tr>'
            + '<tr style="background-color: #f2f2f2;"><td style="padding: 8px; border: 1px solid #ddd;"><strong>Customer Emails Sent</strong></td><td style="padding: 8px; border: 1px solid #ddd;">' + customerEmailsSent + '</td></tr>'
            + '<tr><td style="padding: 8px; border: 1px solid #ddd;"><strong>Internal Emails Sent</strong></td><td style="padding: 8px; border: 1px solid #ddd;">' + internalEmailsSent + '</td></tr>'
            + '</table>'
            + '<br/>'
            + '<h3>Email Breakdown by Reminder Type</h3>'
            + '<table style="border-collapse: collapse; border: 1px solid #ddd; width: 100%;">'
            + '<tr style="background-color: #4CAF50; color: white;"><th style="padding: 8px; border: 1px solid #ddd;">Reminder Type</th><th style="padding: 8px; border: 1px solid #ddd;">Count</th></tr>'
            + '<tr><td style="padding: 8px; border: 1px solid #ddd;">1st Reminder</td><td style="padding: 8px; border: 1px solid #ddd;">' + emailsByType.get('Demand_1ST_REMINDER') + '</td></tr>'
            + '<tr style="background-color: #f2f2f2;"><td style="padding: 8px; border: 1px solid #ddd;">2nd Reminder</td><td style="padding: 8px; border: 1px solid #ddd;">' + emailsByType.get('Demand_2ND_REMINDER') + '</td></tr>'
            + '<tr><td style="padding: 8px; border: 1px solid #ddd;">3rd Reminder</td><td style="padding: 8px; border: 1px solid #ddd;">' + emailsByType.get('Demand_3RD_REMINDER') + '</td></tr>'
            + '</table>'
            + '<br/>'
            + '<hr/>'
            + '<p style="color: #666; font-size: 12px;"><em>This is an automated summary generated by the Payment Reminder Scheduler batch job.</em></p>'
            + '<p style="color: #666; font-size: 12px;"><em>For any queries, please contact the CRM Team.</em></p>'
            + '<br/>'
            + '<p>Best Regards,<br/><strong>Trifecta CRM Automation System</strong></p>';
        
        try {
            System.debug('Creating admin summary email...');
            Messaging.SingleEmailMessage summaryEmail = new Messaging.SingleEmailMessage();
            summaryEmail.setToAddresses(new String[] { adminEmail });
            summaryEmail.setSubject(subject);
            summaryEmail.setHtmlBody(body);
            summaryEmail.setSaveAsActivity(false);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { summaryEmail });
            System.debug('Admin summary email sent successfully');
        } catch (Exception e) {
            System.debug('Error sending admin summary email: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
    }
}