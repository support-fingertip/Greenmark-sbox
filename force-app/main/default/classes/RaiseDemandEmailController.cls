public without sharing class RaiseDemandEmailController {
    
    
    public class dataBox {
        @AuraEnabled public string emailContent;
        @AuraEnabled public string subject;
        @AuraEnabled public boolean isDemandRaised;
        @AuraEnabled public boolean lastPymtSchedule;
        @AuraEnabled public String paymentSchduleType;
        @AuraEnabled public boolean isCurrentMileStatusCompleted;
        @AuraEnabled public boolean isVilla;
    }
    @AuraEnabled
    public static dataBox getData(Id bookingId) {
        dataBox dt = new dataBox();
        boolean lastPymtSchedule =false;
        // Query the latest completed Payment_Schedule__c record based on S_No__c
        Payment_Schedule__c lastCompletedPaymentSchedule = [
            SELECT Id, Is_Demanded__c,Type__c,S_No__c,Payment_Schedule_Type__c,status__c
            FROM Payment_Schedule__c
            WHERE Booking__c = :bookingId AND Status__c = 'Completed'
            ORDER BY S_No__c DESC
            LIMIT 1
        ];
        Payment_Schedule__c LastPaymentschedule = [
            SELECT Id, Is_Demanded__c,Type__c,S_No__c,Payment_Schedule_Type__c,status__c
            FROM Payment_Schedule__c
            WHERE Booking__c = :bookingId
            ORDER BY S_No__c DESC
            LIMIT 1
        ];
        Booking__c bk =  [SELECT Id,Name,Franking_Amount__c,First_Applicant_Name__c,Swap_Unit_Status__c,Owner_Phone_Number__c,
                          Application_Amount__c,Unit_No__c,Owner_Phone__c, Project__c,Plot__r.Name,Booking_Amount__c,Owner_Email__c,
                          Project1__r.Company_Name__c,S__c,Super_Built_UpArea__c,Carpet_Area__c,Agreement_Expected_Date__c,Company_Name__c,
                          Block_Name__c,Owner_Full_Name__c,Email__c,Project_Type__c,Block_Id__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        
        Block__c block = bk.Block_Id__c != null ? [SELECT Id, Name, Email__c, Project_Address__c,Company_Name__c,
                                                   Construction_Company_Name__c,Land_Company_Name__c,Project_Name__c,
                                                   Branch__c, Type_of_Account__c, IFSC_Code__c, Account_Number__c, 
                                                   Bank_Name__c FROM Block__c WHERE Id = :bk.Block_Id__c LIMIT 1] : null;
        
        if(lastCompletedPaymentSchedule.S_No__c == LastPaymentschedule.S_No__c){
            lastPymtSchedule =true;
        }
        boolean isDemandRaised = false;
        // Check if the Is_Demanded__c flag is true for the last completed payment schedule
        if (lastCompletedPaymentSchedule != null && lastCompletedPaymentSchedule.Is_Demanded__c) {
            isDemandRaised =  false; // Return true if Is_Demanded__c is true
        } else {
            isDemandRaised =  true; // Return false if Is_Demanded__c is false or no record found
        }
        dt.isDemandRaised = isDemandRaised;
        dt.paymentSchduleType = lastCompletedPaymentSchedule.Payment_Schedule_Type__c;
        dt.isCurrentMileStatusCompleted =   lastCompletedPaymentSchedule.status__c =='Completed' ? true : false;
        dt.lastPymtSchedule = lastPymtSchedule;
        dt.isVilla = bk.Project_Type__c == 'Villas' ? true : false;
        
        String companyName = 'TRIFECTA PROJECTS PVT LTD';
        if(bk.Project_Type__c == 'Villas')
        {
            if(lastCompletedPaymentSchedule.Type__c =='Land')
            {
                companyName =(block.Land_Company_Name__c != null) ? block.Land_Company_Name__c : '';
            }
            else if(lastCompletedPaymentSchedule.Type__c =='Construction')
            {
                companyName =(block.Construction_Company_Name__c != null) ? block.Construction_Company_Name__c: '';
            }
        }
        else
        {
            companyName =(block.Company_Name__c != null ) ? block.Company_Name__c : '';
        }
        
        
        
        
        // 2. Get Template Record (project wise)
        General_Settings__c temp = [
            SELECT Template_Body__c,Type__c FROM General_Settings__c WHERE
            Project_Name1__c INCLUDES (:bk.Project__c) AND
            Type__c ='Demand Note' LIMIT 1
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
            block.Project_Name__c != null ? block.Project_Name__c : ''
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
        
        template = template.replace(
            '##CRM_PHONE##',
            bk.Owner_Phone_Number__c != null ? String.valueOf(bk.Owner_Phone_Number__c) : ''
        );
        
        template = template.replace(
            '##CRM_EMAIL##',
            bk.Owner_Email__c != null ? String.valueOf(bk.Owner_Email__c) : ''
        );
        template = template.replace(
            '##COMAPANY_NAME##', companyName != null ? String.valueOf(companyName) : ''
        );
        
        dt.emailContent = template;
        
        return dt;
        
        
    } 
    
    @AuraEnabled
    public static dataBox getRevisedDemandData(Id bookingId) {
        dataBox dt = new dataBox();
        boolean lastPymtSchedule =false;
        // Query the latest completed Payment_Schedule__c record based on S_No__c
        Payment_Schedule__c lastCompletedPaymentSchedule = [
            SELECT Id, Is_Demanded__c,Type__c,S_No__c
            FROM Payment_Schedule__c
            WHERE Booking__c = :bookingId AND Status__c = 'Completed'
            ORDER BY S_No__c DESC
            LIMIT 1
        ];
        Payment_Schedule__c LastPaymentschedule = [
            SELECT Id, Is_Demanded__c,Type__c,S_No__c,Payment_Schedule_Type__c
            FROM Payment_Schedule__c
            WHERE Booking__c = :bookingId
            ORDER BY S_No__c DESC
            LIMIT 1
        ];
        Booking__c bk =  [SELECT Id,Name,Franking_Amount__c,First_Applicant_Name__c,Swap_Unit_Status__c,Owner_Phone_Number__c,
                          Application_Amount__c,Unit_No__c,Owner_Phone__c, Project__c,Plot__r.Name,Booking_Amount__c,Owner_Email__c,
                          Project1__r.Company_Name__c,S__c,Super_Built_UpArea__c,Carpet_Area__c,Agreement_Expected_Date__c,Company_Name__c,
                          Block_Name__c,Owner_Full_Name__c,Email__c,Project_Type__c,Block_Id__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        
        Block__c block = bk.Block_Id__c != null ? [SELECT Id, Name, Email__c, Project_Address__c,Company_Name__c,
                                                   Construction_Company_Name__c,Land_Company_Name__c,Project_Name__c,
                                                   Branch__c, Type_of_Account__c, IFSC_Code__c, Account_Number__c, 
                                                   Bank_Name__c FROM Block__c WHERE Id = :bk.Block_Id__c LIMIT 1] : null;
        
        if(lastCompletedPaymentSchedule.S_No__c == LastPaymentschedule.S_No__c){
            lastPymtSchedule =true;
        }
        boolean isDemandRaised = false;
        // Check if the Is_Demanded__c flag is true for the last completed payment schedule
        if (lastCompletedPaymentSchedule != null && lastCompletedPaymentSchedule.Is_Demanded__c) {
            isDemandRaised =  false; // Return true if Is_Demanded__c is true
        } else {
            isDemandRaised =  true; // Return false if Is_Demanded__c is false or no record found
        }
        dt.isDemandRaised = isDemandRaised;
        dt.lastPymtSchedule = lastPymtSchedule;
        
        
        String companyName = 'TRIFECTA PROJECTS PVT LTD';
        if(bk.Project_Type__c == 'Villas')
        {
            if(lastCompletedPaymentSchedule.Type__c =='Land')
            {
                companyName =(block.Land_Company_Name__c != null) ? block.Land_Company_Name__c : '';
            }
            else if(lastCompletedPaymentSchedule.Type__c =='Construction')
            {
                companyName =(block.Construction_Company_Name__c != null) ? block.Construction_Company_Name__c: '';
            }
        }
        else
        {
            companyName =(block.Company_Name__c != null ) ? block.Company_Name__c : '';
        }
        
        
        
        
        // 2. Get Template Record (project wise)
        General_Settings__c temp = [
            SELECT Template_Body__c,Type__c,Subject__c FROM General_Settings__c WHERE
            Project_Name1__c INCLUDES (:bk.Project__c) AND
            Type__c ='Revised Demand Note' LIMIT 1
        ];
        
        
        String template = temp.Template_Body__c;
        String subject = temp.Subject__c;
        
        // ================= MERGE LOGIC =================
        
        // Applicant
        template = template.replace(
            '##APPLICANT_NAME##',
            bk.First_Applicant_Name__c != null ? bk.First_Applicant_Name__c : ''
        );
        
        // Project
        template = template.replace(
            '##PROJECT_NAME##',
            block.Project_Name__c!= null ?  block.Project_Name__c : ''
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
        
        template = template.replace(
            '##CRM_PHONE##',
            bk.Owner_Phone_Number__c != null ? String.valueOf(bk.Owner_Phone_Number__c) : ''
        );
        
        template = template.replace(
            '##CRM_EMAIL##',
            bk.Owner_Email__c != null ? String.valueOf(bk.Owner_Email__c) : ''
        );
        template = template.replace(
            '##COMAPANY_NAME##', companyName != null ? String.valueOf(companyName) : ''
        );
        dt.emailContent = template;
        
        // Project
        subject = subject.replace(
            '##PROJECT_NAME##',
            block.Project_Name__c != null ? block.Project_Name__c : ''
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
        
        dt.subject = subject;
        return dt;
        
        
    } 
    
    @AuraEnabled
    public static String sendEmailWithAttachment(Id recId, String typeOfDemand) {
        String returnmessage;
        Booking__c booking;
        if(typeOfDemand == 'Flat'){
            booking = [SELECT Id, Email__c,Email1__c,Funding_Type__c,Bank_Email__c,First_Applicant_Name__c, Demand_Raised__c,Owner.email,OwnerId,CRM_Manager__c,CRM_Manager__r.Email,CRM_Head__c,CRM_Head__r.Email,Project_Sales_Head__c,Project_Sales_Head__r.Email,Sales_Head__c,Sales_Head__r.Email FROM Booking__c WHERE Id = :recId LIMIT 1];
        }
        else if(typeOfDemand == 'AD'){
            Additional_Charges__c adc = [Select Id,Booking__c from Additional_Charges__c where Id=:recId];
            booking = [SELECT Id, Email__c,Email1__c,Funding_Type__c,First_Applicant_Name__c, Demand_Raised__c,Owner.email,OwnerId,CRM_Manager__c,CRM_Manager__r.Email,CRM_Head__c,CRM_Head__r.Email,Project_Sales_Head__c,Project_Sales_Head__r.Email,Sales_Head__c,Sales_Head__r.Email FROM Booking__c WHERE Id = :adc.Booking__c LIMIT 1];
        }
        system.debug(booking);
        List<String> lstCCEmail = new List<String>();
        //  List<Co_Applicant__c> coApps = [select id,name,Email__c,Email_1__c,Booking__c from Co_Applicant__c where Booking__c =: booking.Id];
        List<ContentVersion> contentVersions1 = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        List<OrgWideEmailAddress> owea = new List<OrgWideEmailAddress>();
        owea = [SELECT Id, Address, DisplayName FROM 
                OrgWideEmailAddress WHERE Address=:booking.Owner.email];
        if (booking != null && !String.isBlank(booking.Email__c)) {
            
            PageReference pdfPage;
            pdfPage = Page.Demand_Invoice; 
            pdfPage.getParameters().put('id', recId);
            //pdfPage.getParameters().put('includeInterest', intrest);
            DemandRaisedSave demandRaisedSave = new DemandRaisedSave();
            system.debug(typeOfDemand);
            // Demand_Raised__c dem = demandRaisedSave.RaiseDemandController(recId, typeOfDemand);
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Unit.Test');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> sendTo = new List<String>();
            sendTo.add(booking.Email__c);
            if(booking.Email1__c != null){
                sendTo.add(booking.Email1__c);
            }
            
            if(booking.Funding_Type__c == 'Loan' && typeOfDemand == 'Flat'){
                sendTo.add(booking.Bank_Email__c);
            }
            String EnableOrgWideEmailToMails = Label.EnableOrgWideEmailToMails;
            if (owea.size()>0 && EnableOrgWideEmailToMails == 'True') {
                email.setOrgWideEmailAddressId(owea[0].Id);
            }
            else {
                // fallback to default OWA
                email.setSenderDisplayName(UserInfo.getName());
                email.setReplyTo(UserInfo.getUserEmail());
            }
            Set<String> ccSet = new Set<String>(lstCCEmail);
            ccSet.addAll(BookingCCEmailUtil.getCCEmails(booking));
            if(!ccSet.isEmpty()){
                email.setCcAddresses(new List<String>(ccSet));
            }
            email.setToAddresses(sendTo);
            email.setSaveAsActivity(true);
            email.setWhatId(booking.Id);
            email.setSubject('Demand Letter');
            email.setHtmlBody('Dear '+booking.First_Applicant_Name__c+',<br/>Please find the attached Demand Letter.<br/><br/>' +
                              'We are pleased to inform you that your booking has been confirmed. ' +
                              'Attached is the Demand Letter for your reference.<br/><br/>' +
                              'If you have any questions or need further assistance, please do not hesitate to contact us.<br/><br/>' +
                              'Thank you for choosing EIPL.<br/><br/>' +
                              'Best regards,<br/>' +
                              'EIPL Pvt Ltd');
            
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('DemandLetter.pdf'); 
            attachment.setBody(pdfBlob);
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            if(typeOfDemand == 'Flat'){
                booking.Demand_Raised__c = true;
                update booking;
            }
            returnmessage = 'Demand raise email sent Successfully';
        } else {
            returnmessage = 'Email address not specified in the Booking record.';
        }
        
        return returnmessage;
    }
    
    @AuraEnabled
    public static void updatePaymentSchedules(String recordId){
        Id recId = (Id) recordId;
        List<payment_schedule__c> payList = new List<payment_schedule__c>();
        Booking__c book = [select id,name from Booking__c where Id=: recId];
        payList = [
            SELECT Id, S_No__c, Name,Pending_Amount__c,Payment_Due_Date__c,Received_Amount1__c,Is_Demanded__c, Payment_percent__c, AmountB__c,
            Master_Payment_Schedule__r.Completed_date__c, Booking__c
            FROM Payment_Schedule__c
            WHERE Master_Payment_Schedule__r.Status__c = 'Completed' and Pending_Amount__c != 0
            AND Booking__c = :recId
        ];
        
        List<payment_schedule__c> toUpdate = new List<payment_schedule__c>();
        for(payment_schedule__c p : payList){
            p.Is_Demanded__c = true;
            if(p.Payment_Due_Date__c == null){
                p.Payment_Due_Date__c = System.today() + 15;
            }
            toUpdate.add(p);
        }
        if(toUpdate.size()>0){
            update toUpdate;
            system.debug('after updated   '+toUpdate);
        }
    }
    
    @AuraEnabled
    public Static String RaiseDemand(String bookingId, String emailContent,List<Id> contentIds) {
        return DemandRaisedSave.raiseNewCustomDemand(bookingId,emailContent,contentIds);
    }
    
    
    
    /**
* Main method that executes the revised demand use case.
* Sends email (as before) and enqueues WhatsApp notification.
*/
    @AuraEnabled
    public static String revisedDemand(String bookingId, String emailContent, List<Id> contentIds, String subject) {
        try {
            // 1. Get the latest completed Payment Schedule and Booking
            Payment_Schedule__c psRecord = getLatestCompletedSchedule(bookingId);
            if (psRecord == null) throw new AuraHandledException('No completed Payment Schedule found.');
            
            Booking__c book = [
                SELECT Id, Applicant_Name__c, First_Applicant_Name__c, Plot__r.Name, Total__c, Name,
                Project__c, Project1__r.Name, GST__c, RecordType.DeveloperName,Mobile__c,Project_Block_Name__c,
                Quote__r.Agreement_Value_Before_GST__c, Total_Amount__c, Block_Name__c,CRM_Executive_Contact_No__c,
                Unit_No__c, Owner_Phone_Number__c, Company_Name__c,
                Email__c, Owner.Email, CRM_Head_Manager_Email__c,
                CRM_Head__c, CRM_Head__r.Email, CRM_Manager__c, CRM_Manager__r.Email,
                Project_Sales_Head__c, Project_Sales_Head__r.Email,
                Sales_Head__c, Sales_Head__r.Email, OwnerId
                FROM Booking__c
                WHERE Id = :psRecord.Booking__c
                LIMIT 1
            ];

            // 2. Get email template and fill merge fields
            String cleanHtml = String.isBlank(emailContent)
                ? getDemandEmailTemplate(book)
                : emailContent;
            
            // 3. Prepare email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> toList = new List<String>();
            if (!String.isBlank(book.Email__c)) {
                toList.add(book.Email__c);
            }
            List<Co_Applicant__c> coApplicants = [
                SELECT Email__c
                FROM Co_Applicant__c
                WHERE Booking__c = :book.Id
                ORDER BY CreatedDate ASC
            ];
            for (Co_Applicant__c cpp : coApplicants) {
                if (String.isNotBlank(cpp.Email__c)) {
                    toList.add(cpp.Email__c);
                }
            } 
            email.setToAddresses(toList);
            
            // CCs
            Set<String> ccList = new Set<String>();
            if (!String.isBlank(book.Owner.Email)) ccList.add(book.Owner.Email);
            if (!String.isBlank(book.CRM_Head_Manager_Email__c)) ccList.add(book.CRM_Head_Manager_Email__c);
            ccList.addAll(BookingCCEmailUtil.getCCEmails(book));
            if (!ccList.isEmpty()) email.setCcAddresses(new List<String>(ccList));
            
            // Subject
            String rawSubject = (String.isNotBlank(subject))
                ? subject
                : 'Revised Demand Note for Completion of ' + psRecord.Name +
                    ' In ' + (book.Project1__r != null ? book.Project1__r.Name : '');
            
            email.setSubject(rawSubject);
            
            cleanHtml = cleanHtml.replaceAll('(?i)<p[^>]*>(\\s|&nbsp;)*</p>', '');
            
            // Step 2: Unescape
            cleanHtml = cleanHtml.unescapeHtml4();
            
            // Step 3: Remove empty paragraphs AGAIN after unescaping
            cleanHtml = cleanHtml.replaceAll('(?i)<p[^>]*>(\\s|&nbsp;)*</p>', '');
            
            // Step 4: Strip ALL existing <p> styles first to avoid double nesting
            cleanHtml = cleanHtml.replaceAll('(?i)<p[^>]*>', '<p>');
            
            // Step 5: Collapse multiple breaks
            cleanHtml = cleanHtml.replaceAll('(<br\\s*/?>\\s*){2,}', '<br/>');
            
            // Step 6: Merge footer 3 separate <p> into one tight block
            cleanHtml = cleanHtml.replaceAll(
                '(?i)<p>\\s*<strong>Thanks\\s*&\\s*Regards,</strong>\\s*</p>\\s*<p>([\\s\\S]*?)</p>\\s*<p>([\\s\\S]*?)</p>',
                '<p style="margin:0; padding:0; line-height:1.8;"><strong>Thanks &amp; Regards,</strong><br/>$1<br/>$2</p>'
            );
            
            // Step 7: Add spacing to remaining <p> tags (without style only)
            cleanHtml = cleanHtml.replaceAll('(?i)<p(?!\\s*style)', '<p style="margin:0 0 10px 0; padding:0;"');
            
            String htmlBody =
                '<html><body style="font-family:Arial; font-size:14px; color:#000; line-height:1.6;">'
                + cleanHtml +
                '</body></html>';
                    
            email.setHtmlBody(htmlBody);
            
            // Attach PDF and any ContentVersion files
            List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
            
            // Attach PDF (simulate in test mode)
            PageReference vfPage = Page.DemandNote;
            vfPage.getParameters().put('id', book.Id);
            vfPage.getParameters().put('reminderType', 'REVISED DEMAND NOTE');
            Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
            Messaging.EmailFileAttachment pdfAttach = new Messaging.EmailFileAttachment();
            pdfAttach.setFileName('Revised Demand Note.pdf');
            pdfAttach.setBody(pdfBlob);
            emailAttachments.add(pdfAttach);
            
            // Attach ContentVersion files
            if (contentIds != null && !contentIds.isEmpty()) {
                for (ContentVersion cv : [SELECT Title, FileExtension, VersionData
                                          FROM ContentVersion
                                          WHERE ContentDocumentId IN :contentIds
                                          AND IsLatest = true]) {
                                              Messaging.EmailFileAttachment contentAttach = new Messaging.EmailFileAttachment();
                                              contentAttach.setFileName(cv.Title + '.' + cv.FileExtension);
                                              contentAttach.setBody(cv.VersionData);
                                              emailAttachments.add(contentAttach);
                                          }
            }
            email.setFileAttachments(emailAttachments);
            String displayName = Label.Default_Email_Address_Label;
            String EnableOrgWideEmailToMails = Label.EnableOrgWideEmailToMails;
            // Set OrgWideEmailAddress
            if (!Test.isRunningTest() && !String.isBlank(psRecord.CreatedBy.Email)) {
                List<OrgWideEmailAddress> orgWideEmail =
                    [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName =: displayName LIMIT 1];
                if (!orgWideEmail.isEmpty() && EnableOrgWideEmailToMails == 'True') {
                    email.setOrgWideEmailAddressId(orgWideEmail[0].Id);
                }
                else {
                    // fallback to default OWA
                    email.setSenderDisplayName(UserInfo.getName());
                    email.setReplyTo(UserInfo.getUserEmail());
                }
            }
            
            email.setSaveAsActivity(true);
            email.setWhatId(book.Id);
            try {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { email });
                System.debug('Email sent successfully.');
            } catch (Exception ex) {
                System.debug('Error sending email: ' + ex.getMessage());
                // If in Aura/LWC context, you may want to throw for client-side display:
                // throw new AuraHandledException('Error sending email: ' + ex.getMessage());
            }
            // WhatsApp notification
            Decimal Amount = calculateGrandTotal(psRecord, book);
            system.debug('Amount'+Amount);
            WhatsappController controller = new WhatsappController(book, Amount, psRecord.PaymentDueDate__c, '10');
            System.enqueueJob(controller);
            
            
            SMSHandler smsctrl = new SMSHandler(book, Amount, psRecord.PaymentDueDate__c, '10');
            System.enqueueJob(smsctrl);
            
            
            return 'Revised Demand sent successfully.';
            
        } catch (Exception e) {
            throw new AuraHandledException('Error sending Revised Demand: ' + e.getMessage());
        }
    }
    
    /** Returns the latest completed Payment Schedule for a Booking */
    private static Payment_Schedule__c getLatestCompletedSchedule(String bookingId) {
        List<Payment_Schedule__c> schedules = [
            SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c,
            Booking__c, Master_Payment_Schedule__r.S_No__c, Master_Payment_Schedule__c,
            CreatedBy.Email, PaymentDueDate__c
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' AND Booking__c = :bookingId
            ORDER BY S_No__c DESC
            LIMIT 1
        ];
        return schedules.isEmpty() ? null : schedules[0];
    }
    
    /** Performs the grand total calculation per business rules */
    private static Decimal calculateGrandTotal(Payment_Schedule__c psRecord, Booking__c book) {
        // Use master or own S_No
        Decimal currentSNo = 0;
        if (psRecord.Master_Payment_Schedule__c != null) {
            Master_Payment_Schedule__c msRecord = [
                SELECT Id, S_No__c
                FROM Master_Payment_Schedule__c
                WHERE Id = :psRecord.Master_Payment_Schedule__c
                LIMIT 1
            ];
            currentSNo = msRecord.S_No__c;
        } else {
            currentSNo = psRecord.S_No__c;
        }
        
        // Previous Milestone Aggregates
        AggregateResult prev = [
            SELECT SUM(Pending_Amount__c) totalPending,
            SUM(Interest_Up_to_Date__c) totalInterest,
            SUM(Interest_Paid__c) totalInterestPaid
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed'
            AND Booking__c = :book.Id
            AND S_No__c < :currentSNo
        ];
        Decimal prevDue = (Decimal)prev.get('totalPending')    ?? 0;
        Decimal prevInt = (Decimal)prev.get('totalInterest')   ?? 0;
        Decimal prevIntPaid = (Decimal)prev.get('totalInterestPaid') ?? 0;
        Decimal prevBalanceInt = prevInt - prevIntPaid;
        
        // Current Milestone Due
        AggregateResult curr = [
            SELECT SUM(Pending_Amount__c) due,
            SUM(Interest_Up_to_Date__c) interest,
            SUM(Interest_Paid__c) interestPaid
            FROM Payment_Schedule__c
            WHERE S_No__c = :currentSNo
            AND Booking__c = :book.Id
        ];
        Decimal currDue = (Decimal)curr.get('due') ?? 0;
        Decimal currInt = (Decimal)curr.get('interest') ?? 0;
        Decimal currIntPaid = (Decimal)curr.get('interestPaid') ?? 0;
        Decimal currBalanceInt = currInt - currIntPaid;
        
        // Total
        Decimal balanceTotalInterest = currBalanceInt + prevBalanceInt;
        Decimal grandTotal = currDue + prevDue + balanceTotalInterest;
        return grandTotal;
    }
    
    /** Loads and merges the Demand Note email template */
    private static String getDemandEmailTemplate(Booking__c book) {
        List<General_Settings__c> temps = [
            SELECT Template_Body__c
            FROM General_Settings__c
            WHERE Project_Name1__c INCLUDES (:book.Project__c)
            AND Type__c = 'Demand Note'
            LIMIT 1
        ];
        String template = temps.isEmpty() ? '' : temps[0].Template_Body__c;
        
        if (!String.isBlank(template)) {
            template = template.replace('##APPLICANT_NAME##', book.First_Applicant_Name__c ?? '');
            template = template.replace('##PROJECT_NAME##', book.Project__c ?? '');
            template = template.replace('##BLOCK_NAME##', String.valueOf(book.Block_Name__c ?? ''));
            template = template.replace('##UNIT_NUMBER##', String.valueOf(book.Unit_No__c ?? ''));
            template = template.replace('##CRM_PHONE##', String.valueOf(book.Owner_Phone_Number__c ?? ''));
            template = template.replace('##COMAPANY_NAME##', String.valueOf(book.Company_Name__c ?? ''));
        }
        return template;
    }
    @AuraEnabled
    public static dataBox getPenaltyDemandData(Id bookingId) {
        dataBox dt = new dataBox();
        Boolean lastPymtSchedule = false;
        
        Payment_Schedule__c lastCompletedPaymentSchedule = [
            SELECT Id, Is_Demanded__c, Type__c, S_No__c
            FROM Payment_Schedule__c
            WHERE Booking__c = :bookingId AND Status__c = 'Completed'
            ORDER BY S_No__c DESC
            LIMIT 1
        ];
        
        Payment_Schedule__c LastPaymentschedule = [
            SELECT Id, Is_Demanded__c, Type__c, S_No__c
            FROM Payment_Schedule__c
            WHERE Booking__c = :bookingId
            ORDER BY S_No__c DESC
            LIMIT 1
        ];
        
        Booking__c bk = [
            SELECT Id, Name, Franking_Amount__c, First_Applicant_Name__c, Swap_Unit_Status__c, Owner_Phone_Number__c,
            Application_Amount__c, Unit_No__c, Owner_Phone__c, Project__c, Plot__r.Name, Booking_Amount__c, Owner_Email__c,
            Project1__r.Company_Name__c, S__c, Super_Built_UpArea__c, Carpet_Area__c, Agreement_Expected_Date__c, Company_Name__c,
            Block_Name__c, Owner_Full_Name__c, Email__c, Project_Type__c, Block_Id__c
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];
        
        Block__c block = bk.Block_Id__c != null
            ? [
                SELECT Id, Name, Email__c, Project_Address__c, Company_Name__c,
                Construction_Company_Name__c, Land_Company_Name__c,Project_Name__c,
                Branch__c, Type_of_Account__c, IFSC_Code__c, Account_Number__c,
                Bank_Name__c
                FROM Block__c
                WHERE Id = :bk.Block_Id__c
                LIMIT 1
            ]
            : null;
        
        if (lastCompletedPaymentSchedule.S_No__c == LastPaymentschedule.S_No__c) {
            lastPymtSchedule = true;
        }
        
        Boolean isDemandRaised = false;
        if (lastCompletedPaymentSchedule != null && lastCompletedPaymentSchedule.Is_Demanded__c) {
            isDemandRaised = false;
        } else {
            isDemandRaised = true;
        }
        
        dt.isDemandRaised = isDemandRaised;
        dt.lastPymtSchedule = lastPymtSchedule;
        
        String companyName = 'TRIFECTA PROJECTS PVT LTD';
        if (bk.Project_Type__c == 'Villas') {
            if (lastCompletedPaymentSchedule.Type__c == 'Land') {
                companyName = (block != null && block.Land_Company_Name__c != null) ? block.Land_Company_Name__c : '';
            } else if (lastCompletedPaymentSchedule.Type__c == 'Construction') {
                companyName = (block != null && block.Construction_Company_Name__c != null) ? block.Construction_Company_Name__c : '';
            }
        } else {
            companyName = (block != null && block.Company_Name__c != null) ? block.Company_Name__c : '';
        }
        
        General_Settings__c temp = [
            SELECT Template_Body__c, Type__c, Subject__c
            FROM General_Settings__c
            WHERE Project_Name1__c INCLUDES (:bk.Project__c)
            AND Type__c = 'Penalty Demand Note'
            LIMIT 1
        ];
        
        String template = temp.Template_Body__c;
        String subject = temp.Subject__c;
        
        template = template.replace('##APPLICANT_NAME##', bk.First_Applicant_Name__c != null ? bk.First_Applicant_Name__c : '');
        template = template.replace('##PROJECT_NAME##',block.Project_Name__c != null ? block.Project_Name__c : '');
        template = template.replace('##BLOCK_NAME##', bk.Block_Name__c != null ? String.valueOf(bk.Block_Name__c) : '');
        template = template.replace('##UNIT_NUMBER##', bk.Unit_No__c != null ? String.valueOf(bk.Unit_No__c) : '');
        template = template.replace('##CRM_PHONE##', bk.Owner_Phone_Number__c != null ? String.valueOf(bk.Owner_Phone_Number__c) : '');
        template = template.replace('##CRM_EMAIL##', bk.Owner_Email__c != null ? String.valueOf(bk.Owner_Email__c) : '');
        template = template.replace('##COMAPANY_NAME##', companyName != null ? String.valueOf(companyName) : '');
        
        dt.emailContent = template;
        
        subject = subject.replace('##PROJECT_NAME##',block.Project_Name__c != null ? block.Project_Name__c : '');
        subject = subject.replace('##BLOCK_NAME##', bk.Block_Name__c != null ? String.valueOf(bk.Block_Name__c) : '');
        subject = subject.replace('##UNIT_NUMBER##', bk.Unit_No__c != null ? String.valueOf(bk.Unit_No__c) : '');
        
        dt.subject = subject;
        
        return dt;
    }
    @AuraEnabled
    public static String penaltyDemand(String bookingId, String emailContent, List<Id> contentIds, String subject) {
        try {
            Payment_Schedule__c psRecord = getLatestCompletedSchedule(bookingId);
            if (psRecord == null) {
                throw new AuraHandledException('No completed Payment Schedule found.');
            }
            
            Booking__c book = [
                SELECT Id, Applicant_Name__c, First_Applicant_Name__c, Plot__r.Name, Total__c, Name,
                Project__c, Project1__r.Name, GST__c, RecordType.DeveloperName, Mobile__c, Project_Block_Name__c,
                Quote__r.Agreement_Value_Before_GST__c, Total_Amount__c, Block_Name__c, CRM_Executive_Contact_No__c,
                Unit_No__c, Owner_Phone_Number__c, Company_Name__c,Default_Interest_Percentage__c,
                Email__c, Owner.Email, CRM_Head_Manager_Email__c,
                CRM_Head__c, CRM_Head__r.Email, CRM_Manager__c, CRM_Manager__r.Email,
                Project_Sales_Head__c, Project_Sales_Head__r.Email,
                Sales_Head__c, Sales_Head__r.Email, OwnerId
                FROM Booking__c
                WHERE Id = :psRecord.Booking__c
                LIMIT 1
            ];
            
            String cleanHtml = String.isBlank(emailContent)
                ? getPenaltyDemandEmailTemplate(book)
                : emailContent;
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> toList = new List<String>();
            if (!String.isBlank(book.Email__c)) {
                toList.add(book.Email__c);
            }
            
            List<Co_Applicant__c> coApplicants = [
                SELECT Email__c
                FROM Co_Applicant__c
                WHERE Booking__c = :book.Id
                ORDER BY CreatedDate ASC
            ];
            for (Co_Applicant__c cpp : coApplicants) {
                if (String.isNotBlank(cpp.Email__c)) {
                    toList.add(cpp.Email__c);
                }
            }
            email.setToAddresses(toList);
           
            
            Set<String> ccList = new Set<String>();
            if (!String.isBlank(book.Owner.Email)) {
                ccList.add(book.Owner.Email);
            }
            if (!String.isBlank(book.CRM_Head_Manager_Email__c)) {
                ccList.add(book.CRM_Head_Manager_Email__c);
            }
            ccList.addAll(BookingCCEmailUtil.getCCEmails(book));
            if (!ccList.isEmpty()) {
                email.setCcAddresses(new List<String>(ccList));
            }
            
            String rawSubject = String.isNotBlank(subject)
                ? subject
                : 'Penalty Demand Note for Completion of ' + psRecord.Name +
                    ' In ' + (book.Project1__r != null ? book.Project1__r.Name : '');
            
            email.setSubject(rawSubject);
            
            cleanHtml = cleanHtml.replaceAll('(?i)<p[^>]*>(\\s|&nbsp;)*</p>', '');
            
            // Step 2: Unescape
            cleanHtml = cleanHtml.unescapeHtml4();
            
            // Step 3: Remove empty paragraphs AGAIN after unescaping
            cleanHtml = cleanHtml.replaceAll('(?i)<p[^>]*>(\\s|&nbsp;)*</p>', '');
            
            // Step 4: Strip ALL existing <p> styles first to avoid double nesting
            cleanHtml = cleanHtml.replaceAll('(?i)<p[^>]*>', '<p>');
            
            // Step 5: Collapse multiple breaks
            cleanHtml = cleanHtml.replaceAll('(<br\\s*/?>\\s*){2,}', '<br/>');
            
            // Step 6: Merge footer 3 separate <p> into one tight block
            cleanHtml = cleanHtml.replaceAll(
                '(?i)<p>\\s*<strong>Thanks\\s*&\\s*Regards,</strong>\\s*</p>\\s*<p>([\\s\\S]*?)</p>\\s*<p>([\\s\\S]*?)</p>',
                '<p style="margin:0; padding:0; line-height:1.8;"><strong>Thanks &amp; Regards,</strong><br/>$1<br/>$2</p>'
            );
            
            // Step 7: Add spacing to remaining <p> tags (without style only)
            cleanHtml = cleanHtml.replaceAll('(?i)<p(?!\\s*style)', '<p style="margin:0 0 10px 0; padding:0;"');
            
            String htmlBody =
                '<html><body style="font-family:Arial; font-size:14px; color:#000; line-height:1.6;">'
                + cleanHtml +
                '</body></html>';
            
            email.setHtmlBody(htmlBody);
            
            List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
            
            PageReference vfPage = Page.PenaltyDemandNote;
            vfPage.getParameters().put('id', book.Id);
            vfPage.getParameters().put('reminderType', 'PENALTY DEMAND NOTE');
            
            Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
            
            Messaging.EmailFileAttachment pdfAttach = new Messaging.EmailFileAttachment();
            pdfAttach.setFileName('Penalty Demand Note.pdf');
            pdfAttach.setBody(pdfBlob);
            emailAttachments.add(pdfAttach);
            
            if (contentIds != null && !contentIds.isEmpty()) {
                for (ContentVersion cv : [
                    SELECT Title, FileExtension, VersionData
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :contentIds
                    AND IsLatest = true
                ]) {
                    Messaging.EmailFileAttachment contentAttach = new Messaging.EmailFileAttachment();
                    contentAttach.setFileName(cv.Title + '.' + cv.FileExtension);
                    contentAttach.setBody(cv.VersionData);
                    emailAttachments.add(contentAttach);
                }
            }
            
            email.setFileAttachments(emailAttachments);
            String displayName = Label.Default_Email_Address_Label;
            String EnableOrgWideEmailToMails = Label.EnableOrgWideEmailToMails;
            if (!Test.isRunningTest() && !String.isBlank(psRecord.CreatedBy.Email)) {
                List<OrgWideEmailAddress> orgWideEmail = [
                    SELECT Id
                    FROM OrgWideEmailAddress
                    WHERE DisplayName =: displayName
                    LIMIT 1
                ];
                if (!orgWideEmail.isEmpty() && EnableOrgWideEmailToMails == 'True') {
                    email.setOrgWideEmailAddressId(orgWideEmail[0].Id);
                }
                else {
                    // fallback to default OWA
                    email.setSenderDisplayName(UserInfo.getName());
                    email.setReplyTo(UserInfo.getUserEmail());
                }
            }
            
            email.setSaveAsActivity(true);
            email.setWhatId(book.Id);
            
            try {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
                System.debug('Penalty email sent successfully.');
            } catch (Exception ex) {
                System.debug('Error sending penalty email: ' + ex.getMessage());
            }
            
            Decimal Amount = calculateGrandTotal(psRecord, book);
            WhatsappController controller = new WhatsappController(book, Amount, psRecord.PaymentDueDate__c, '12');
            System.enqueueJob(controller);
            
            return 'Penalty Demand sent successfully.';
        } catch (Exception e) {
            throw new AuraHandledException('Error sending Penalty Demand: ' + e.getMessage());
        }
    }
    private static String getPenaltyDemandEmailTemplate(Booking__c book) {
        List<General_Settings__c> temps = [
            SELECT Template_Body__c
            FROM General_Settings__c
            WHERE Project_Name1__c INCLUDES (:book.Project__c)
            AND Type__c = 'Penalty Demand Note'
            LIMIT 1
        ];
        
        String template = temps.isEmpty() ? '' : temps[0].Template_Body__c;
        
        if (!String.isBlank(template)) {
            template = template.replace('##APPLICANT_NAME##', book.First_Applicant_Name__c != null ? book.First_Applicant_Name__c : '');
            template = template.replace('##PROJECT_NAME##', book.Project__c != null ? book.Project__c : '');
            template = template.replace('##BLOCK_NAME##', book.Block_Name__c != null ? String.valueOf(book.Block_Name__c) : '');
            template = template.replace('##UNIT_NUMBER##', book.Unit_No__c != null ? String.valueOf(book.Unit_No__c) : '');
            template = template.replace('##CRM_PHONE##', book.Owner_Phone_Number__c != null ? String.valueOf(book.Owner_Phone_Number__c) : '');
            template = template.replace('##COMAPANY_NAME##', book.Company_Name__c != null ? String.valueOf(book.Company_Name__c) : '');
        }
        
        return template;
    }
}