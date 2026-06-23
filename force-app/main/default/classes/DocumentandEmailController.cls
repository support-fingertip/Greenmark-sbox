public class DocumentandEmailController {
    
    public class BookingDataWrapper {
        @AuraEnabled public Booking__c booking;
        @AuraEnabled public String customerNames;
    }
    
    @AuraEnabled
    public static BookingDataWrapper getBookingDetails(Id recordId) {
        
        Booking__c booking = [SELECT Id,First_Applicant_Name__c,S__c, Plot__r.Name, Project1__r.Name,Funding_Type__c,
                              Agreement_Expected_Date__c,Agreement_Executed_Date__c,Possession_Date__c,Total_received_Amount__c,Agreement_Execution_Amount1__c
                              /*(SELECT Salutation__c, Name FROM Co_Applicant__r)*/
                              FROM Booking__c WHERE Id = :recordId LIMIT 1];
        
        String customerNames = (String.isEmpty(booking.S__c) ? '' : booking.S__c) + ' ' +
            (String.isEmpty(booking.First_Applicant_Name__c) ? '' : booking.First_Applicant_Name__c);
        
        BookingDataWrapper wrapper = new BookingDataWrapper();
        wrapper.booking = booking;
        wrapper.customerNames =  customerNames;
        return wrapper;
    }
    
    @AuraEnabled
    public static String sendEmailGenerateReceipt(Id receiptId) {
        System.debug('Called From Trigger');
        String returnMessage;
        try {
            // Retrieve the Receipt record
            Receipt__c receipt = [SELECT Id, Booking__c, CreatedBy.Email FROM Receipt__c WHERE Id = :receiptId LIMIT 1];
            System.debug(receipt);
            if (receipt == null || receipt.Booking__c == null) {
                return 'Receipt or associated Booking record not found.';
            }
            
            // Retrieve the related Booking record
            Booking__c booking = [SELECT Id, Email__c,First_Applicant_Name__c,Email1__c,Owner.Email,
                                  CRM_Head__c, CRM_Head__r.Email, CRM_Manager__c, CRM_Manager__r.Email,
                                  Project_Sales_Head__c, Project_Sales_Head__r.Email,
                                  Sales_Head__c, Sales_Head__r.Email, OwnerId
                                  FROM Booking__c WHERE Id = :receipt.Booking__c LIMIT 1];
            System.debug(booking);
            
            if (booking != null && !String.isBlank(booking.Email__c)) {
                List<String> lstCCEmail = new List<String>();
                
                // Retrieve co-applicants associated with the Booking
                List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
                
                PageReference receiptPage;
                receiptPage = Page.Receipt;
                // Generate the PDF for the receipt
                receiptPage.getParameters().put('id', receiptId);
                Blob pdfBlob = !Test.isRunningTest() ? receiptPage.getContentAsPDF() : Blob.valueOf('testblob');
                
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                sendTo.add(booking.Email__c);
                System.debug(booking.Email__c);
                // Include Co-Applicant emails
                for (Co_Applicant__c ca : coApps) {
                    if (ca.Email__c != null) {
                        sendTo.add(ca.Email__c);
                    }
                }
                
                // Include CC addresses
                Set<String> ccSet = new Set<String>(lstCCEmail);
                ccSet.addAll(BookingCCEmailUtil.getCCEmails(booking));
                if (!ccSet.isEmpty()) {
                    email.setCcAddresses(new List<String>(ccSet));
                }

                email.setToAddresses(sendTo);
                email.setSubject('Receipt for Your Payment');
                email.setHtmlBody('Dear ' + booking.First_Applicant_Name__c + ',<br/><br/>Please find the attached receipt for your payment.<br/><br/>Thank you.');

                // Attach the PDF to the email
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('Receipt.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

                email.setSaveAsActivity(true);
                email.setWhatId(booking.Id);
                
                // Send the email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        return returnMessage;
    }
    @future(callout = true)
    public static void sendEmailGenerateReceiptfromTrigger(Id receiptId) {
        System.debug('Called From Trigger');
        String returnMessage;
        try {
            // Retrieve the Receipt record
            Receipt__c receipt = [SELECT Id, Booking__c,Name, CreatedBy.Email,Receipt_Date__c,Total_Received_Amount__c
                                  FROM Receipt__c WHERE Id = :receiptId LIMIT 1];
            decimal totalAmount = 0;
            List<Receipt_Line_Item__c> receiptItem = [SELECT Id, Name, Bank_Name__c, Mode_of_Payment__c,Received_Amount__c FROM Receipt_Line_Item__c
                                                      where Receipt__c =:receipt.Id AND Payment_Type__c != 'TDS'];
            if(!receiptItem.isEmpty())
            {
                for(Receipt_Line_Item__c rec : receiptItem)
                {
                    if(rec.Received_Amount__c != null)
                    {
                        totalAmount += rec.Received_Amount__c;
                    }
                }
                
                Set<String> bankSet = new Set<String>();
                Set<String> paymentModeSet = new Set<String>();
                Set<String> paymentFor = new Set<String>();
                
                for (Receipt_Line_Item__c rectItem : receiptItem) {
                    if (String.isNotBlank(rectItem.Bank_Name__c)) {
                        bankSet.add(rectItem.Bank_Name__c);
                    }
                    if (String.isNotBlank(rectItem.Mode_of_Payment__c)) {
                        paymentModeSet.add(rectItem.Mode_of_Payment__c);
                    }
                    if (String.isNotBlank(rectItem.Name)) {
                        paymentFor.add(rectItem.Name);
                    }
                }
                
                // Convert to comma separated string
                String BANK_NAME = String.join(new List<String>(bankSet), ', ');
                String PAYMENT_MODE = String.join(new List<String>(paymentModeSet), ', ');
                String PAYMENT_FOR = String.join(new List<String>(paymentFor), ', ');
                
                System.debug(receipt);
                if (receipt == null || receipt.Booking__c == null) {
                    // return 'Receipt or associated Booking record not found.';
                }
                
                // Retrieve the related Booking record
                Booking__c booking = [SELECT Id, Email__c,First_Applicant_Name__c,Email1__c,Owner.Email,Project__c,Block_Name__c,
                                      Unit_No__c,Owner_Phone_Number__c,Company_Name__c,
                                      CRM_Head__c, CRM_Head__r.Email, CRM_Manager__c, CRM_Manager__r.Email,
                                      Project_Sales_Head__c, Project_Sales_Head__r.Email,
                                      Sales_Head__c, Sales_Head__r.Email, OwnerId
                                      FROM Booking__c WHERE Id = :receipt.Booking__c LIMIT 1];
                System.debug(booking);
                
                if (booking != null && !String.isBlank(booking.Email__c)) {
                    List<String> lstCCEmail = new List<String>();
                    
                    // Retrieve co-applicants associated with the Booking
                    List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
                    
                    PageReference receiptPage;
                    receiptPage = Page.Receipt;
                    // Generate the PDF for the receipt
                    receiptPage.getParameters().put('id', receiptId);
                    Blob pdfBlob = !Test.isRunningTest() ? receiptPage.getContentAsPDF() : Blob.valueOf('testblob');
                    
                    // Prepare email details
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    List<String> sendTo = new List<String>();
                    sendTo.add(booking.Email__c);
                    System.debug(booking.Email__c);
                    // Include Co-Applicant emails
                    for (Co_Applicant__c ca : coApps) {
                        if (ca.Email__c != null) {
                            sendTo.add(ca.Email__c);
                        }
                    }
                    String displayName = Label.Default_Email_Address_Label;
                    String EnableOrgWideEmailToMails = Label.EnableOrgWideEmailToMails;
                    // Set OrgWideEmailAddress
                    if (!Test.isRunningTest()) {
                        List<OrgWideEmailAddress> orgWideEmail =
                            [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName =:displayName LIMIT 1];
                        if (!orgWideEmail.isEmpty() && EnableOrgWideEmailToMails == 'True') {
                            email.setOrgWideEmailAddressId(orgWideEmail[0].Id);
                        }
                        else {
                            // fallback to default OWA
                            email.setSenderDisplayName(UserInfo.getName());
                            email.setReplyTo(UserInfo.getUserEmail());
                        }
                    }
                    
                    // Include CC addresses
                    Set<String> ccSet = new Set<String>(lstCCEmail);
                    ccSet.addAll(BookingCCEmailUtil.getCCEmails(booking));
                    if (!ccSet.isEmpty()) {
                        email.setCcAddresses(new List<String>(ccSet));
                    }

                    email.setToAddresses(sendTo);
                    
                    General_Settings__c temp = [SELECT Template_Body__c, Type__c,Subject__c  FROM General_Settings__c WHERE
                                                Project_Name1__c INCLUDES (:booking.Project__c)
                                                AND Type__c = 'Payment Receipt' LIMIT 1];
                    
                    String template = temp.Template_Body__c; 
                    String subject = temp.Subject__c; 
                    template = template.replace('##APPLICANT_NAME##', booking.First_Applicant_Name__c ?? '');
                    template = template.replace('##PROJECT_NAME##', booking.Project__c ?? '');
                    template = template.replace('##BLOCK_NAME##', String.valueOf(booking.Block_Name__c ?? ''));
                    template = template.replace('##UNIT_NUMBER##', String.valueOf(booking.Unit_No__c ?? ''));
                    template = template.replace('##CRM_PHONE##', String.valueOf(booking.Owner_Phone_Number__c ?? ''));
                    template = template.replace('##COMAPANY_NAME##', String.valueOf(booking.Company_Name__c ?? ''));
                    template = template.replace('##COMAPANY_NAME##', String.valueOf(booking.Company_Name__c ?? ''));
                    
                    
                    NumberTOWordConvertion conversion = new NumberTOWordConvertion();
                    String amountInWords = totalAmount != null ?conversion.getNumberTOWordConvertion(totalAmount) : null;
                    template = template.replace('##AMOUNT_IN_WORDS##', amountInWords ?? '');
                    template = template.replace('##AMOUNT##', String.valueOf(totalAmount ?? 0));
                    template = template.replace('##TRANSACTION_DATE##', String.valueOf(receipt.Receipt_Date__c ?? null));
                    template = template.replace('##TRANSACTION_NO##', String.valueOf(receipt.Name ?? ''));
                    template = template.replace('##BANK_NAME##', BANK_NAME ?? '');
                    template = template.replace('##PAYMENT_MODE##', PAYMENT_MODE ?? '');
                    template = template.replace('##PAYMENT_FOR##', PAYMENT_FOR ?? '');
                    
                    subject = subject.replace('##PROJECT_NAME##', booking.Project__c ?? '');
                    subject = subject.replace('##BLOCK_NAME##', String.valueOf(booking.Block_Name__c ?? ''));
                    subject = subject.replace('##UNIT_NUMBER##', String.valueOf(booking.Unit_No__c ?? ''));
                    
                    
                    
                    String cleanHtml = template.unescapeHtml4();
                    cleanHtml = cleanHtml.replaceAll('(?i)<p>(\\s|&nbsp;)*</p>', '');
                    cleanHtml = cleanHtml.replaceAll('(<br\\s*/?>\\s*){2,}', '<br/>');
                    String htmlBody =
                        '<html><body style="font-family: Arial; font-size:14px; color:#000; line-height:1.4;">'
                        + cleanHtml +
                        '</body></html>';
                    
                    email.setSubject(subject);
                    email.setHtmlBody(htmlBody);
                    
                    // Attach the PDF to the email
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    attachment.setFileName('Receipt.pdf');
                    attachment.setBody(pdfBlob);
                    email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

                    email.setSaveAsActivity(true);
                    email.setWhatId(booking.Id);

                    // Send the email
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                }
                else {
                    returnMessage = 'Email address not specified in the Booking record.';
                }
                // returnMessage = 'Email sent successfully';
            }
        } catch (Exception e) {
            system.debug('error'+e.getMessage());
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        //return returnMessage;
    }
    
    
    @AuraEnabled
    public static String sendEmailGenerateSA(Id recId, String emailContent) {
        system.debug('emailContent: ' + emailContent);
        String returnMessage = 'Unknown error';
        set<string> conDocId = new set<string>();
        list<Messaging.EmailFileAttachment> attachments =  new list<Messaging.EmailFileAttachment>(); 
        try {
            // Retrieve the Booking record
            Booking__c booking = [ SELECT Id, Project__c, Email__c,Plot__c,plot__r.Name,Agreement_Execution_Date__c,Project1__r.Name, First_Applicant_Name__c, CRM_Manager__c, CRM_Manager__r.Email,
                                  CRM_Head__c, CRM_Head__r.Email, Project_Sales_Head__c, Project_Sales_Head__r.Email,
                                  Sales_Head__c, Sales_Head__r.Email, OwnerId, Owner.Email
                                  FROM Booking__c  WHERE Id = :recId   LIMIT 1 ];
            if (booking.Email__c == null) {
                return 'Email address not specified in the Booking record.';
            }
            
            PageReference vfPage = Page.SaleAgreement;
            vfPage.getParameters().put('id', recId);
            
            vfPage.setRedirect(true);
            Blob pdfBlob = Test.isRunningTest() 
                ? Blob.valueOf('testblob') 
                : vfPage.getContentAsPDF();
            
            // Prepare the email
            Set<String> sendTo = new Set<String>();
            sendTo.add(booking.Email__c);
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>(sendTo));
            
            email.setSubject('Sale Agreement for Plot/Unit No. ' + booking.plot__r.Name + ' at Zuari ' + booking.Project1__r.Name);
            email.setHtmlBody(emailContent);
            email.setSaveAsActivity(true);
            email.setWhatId(booking.Id);
            
            //CC to veegaland customercare
            Set<String> lstCCEmail = BookingCCEmailUtil.getCCEmails(booking);
            if (!lstCCEmail.isEmpty()) {
                email.setCcAddresses(new List<String>(lstCCEmail));
            }
            
            // Add PDF as attachment
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('Sale Agreement.pdf');
            attachment.setBody(pdfBlob);
            attachment.setContentType('application/pdf');
            attachments.add(attachment);
            
            email.setFileAttachments( attachments );
            
            // Send email
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { email });
            
            returnMessage = 'Email sent successfully';
            
        } catch (Exception e) {
            system.debug('Error sending email: ' + e.getMessage());
            //ExceptionHandler.addLog(e,emailContent,'GenerateDocumnetController',recId);  /*Add Exception to error log*/
            returnMessage = 'Error sending email: ' + e.getMessage();
        }
        
        return returnMessage;
    }
    
    public static void sendEmailGenerateDemand(List<Id> recIds,List<Id> contentIds) {
        try {
            
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            // Fetch the Demand_Raised__c records for the given recIds
            List<Demand_Raised__c> demandRecords = [
                SELECT Id, Demand_Email_Content__c,CreatedBy.Email, Booking__r.Email__c, Demand_Name__c,Project__c,Booking__r.Owner_Email__c,
                Booking__r.Owner.Email,Booking__r.Total__c,booking__c, booking__r.CRM_Manager__r.Email,booking__r.Project1__r.Name,booking__r.CRM_Head_Manager_Email__c,
                Booking__r.CRM_Head__c, Booking__r.CRM_Head__r.Email, Booking__r.CRM_Manager__c,
                Booking__r.Project_Sales_Head__c, Booking__r.Project_Sales_Head__r.Email,
                Booking__r.Sales_Head__c, Booking__r.Sales_Head__r.Email, Booking__r.OwnerId,
                (SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks WHERE LinkedEntityId IN :recIds)
                FROM Demand_Raised__c 
                WHERE Id IN :recIds
            ];
            
            if (demandRecords.isEmpty()) {
                return;
            }
            system.debug('contentIds'+ contentIds);
            List<Co_Applicant__c> coApplicants = [
                SELECT Name, Salutation__c ,Email__c
                FROM Co_Applicant__c 
                WHERE Booking__c = :demandRecords[0].booking__c 
                ORDER BY CreatedDate ASC 
            ];
            List<String> emailList = new List<String>();
            if (!coApplicants.isEmpty()) {
                for(Co_Applicant__c cpp : coApplicants)
                {
                    if(cpp.Email__c != null)
                    {
                        emailList.add(cpp.Email__c );
                    }               
                }
            }
            
            
            for (Demand_Raised__c demand : demandRecords) {
                // Convert comma-separated string of content IDs to Set<Id>
                List<String> contentDocumentIds = new List<String>();
                List<String> lstCCEmail = new List<String>();
                Booking__c booking = demand.Booking__r;
                
                if (booking != null && !String.isBlank(booking.Email__c)) {
                    // Generate the PDF for the Agreement Amount Request
                    PageReference vfPage = Page.Demand_Note_Send;          
                    vfPage.getParameters().put('id', demand.Id);
                    Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
                    
                    // Prepare email details
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    List<String> sendTo = new List<String>();
                    sendTo.add(booking.Email__c);
                    Set<String> ccSet = new Set<String>(lstCCEmail);
                    if (String.isNotBlank(booking.Owner.Email)) {
                        ccSet.add(booking.Owner.Email);
                    }
                    if (booking.CRM_Head_Manager_Email__c != null) {
                        ccSet.add(booking.CRM_Head_Manager_Email__c);
                    }
                    ccSet.addAll(BookingCCEmailUtil.getCCEmails(booking));
                    if (!ccSet.isEmpty()) {
                        email.setCcAddresses(new List<String>(ccSet));
                    }
                    if (!emailList.isEmpty()) {
                        sendTo.addAll(emailList);
                    }
                    email.setToAddresses(sendTo);
                    email.setSubject('Demand Note for Completion of '+demand.Demand_Name__c +' In '+demand.Booking__r.Project1__r.name);
                    
                    String cleanHtml = demand.Demand_Email_Content__c.unescapeHtml4();
                    system.debug('cleanHtml'+cleanHtml);
                    // Step 1: Remove empty paragraphs BEFORE unescaping
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
                    
                    
                    // Retrieve Content Versions for attachments
                    List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                    if (!contentDocumentIds.isEmpty()) {
                        List<ContentVersion> contentVersions = [
                            SELECT Title, FileExtension, VersionData 
                            FROM ContentVersion 
                            WHERE ContentDocumentId IN :contentDocumentIds
                        ];
                        
                        for (ContentVersion cv : contentVersions) {
                            Messaging.EmailFileAttachment contentAttach = new Messaging.EmailFileAttachment();
                            contentAttach.setFileName(cv.Title + '.' + cv.FileExtension);
                            contentAttach.setBody(cv.VersionData);
                            emailAttachments.add(contentAttach);
                        }
                    }
                    system.debug('contentIds'+ contentIds);
                    system.debug('contentIds Entered ===================>');
                    // Query attachments once
                    List<ContentVersion> contentVersionsMain  = new List<ContentVersion>();
                    if (contentIds != null && !contentIds.isEmpty()) {
                        contentVersionsMain  = [
                            SELECT Title, FileExtension, VersionData
                            FROM ContentVersion
                            WHERE ContentDocumentId IN :contentIds
                            AND IsLatest = true
                        ];
                        
                        for (ContentVersion cv : contentVersionsMain) {
                            Messaging.EmailFileAttachment contentAttach = new Messaging.EmailFileAttachment();
                            contentAttach.setFileName(cv.Title + '.' + cv.FileExtension);
                            contentAttach.setBody(cv.VersionData);
                            emailAttachments.add(contentAttach);
                        }
                    }
                    system.debug('contentIds completed ===================>');
                    // Attach the Demand PDF
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    attachment.setFileName('DemandNote.pdf');
                    attachment.setBody(pdfBlob);
                    emailAttachments.add(attachment);
                    
                    if (!emailAttachments.isEmpty()) {
                        email.setFileAttachments(emailAttachments);
                    }
                    String displayName = Label.Default_Email_Address_Label;
                    // Set OrgWideEmailAddress
                    if (!Test.isRunningTest()) {
                        List<OrgWideEmailAddress> orgWideEmail =
                            [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName =:displayName LIMIT 1];
                        if (!orgWideEmail.isEmpty()) {
                            email.setOrgWideEmailAddressId(orgWideEmail[0].Id);
                        }
                    }
                    
                    
                    
                    email.setSaveAsActivity(true);
                    email.setWhatId(booking.Id);
                    // Send the email
                    emails.add(email);
                } 
                if (!emails.isEmpty()) {
                    Messaging.sendEmail(emails);
                }
            }
        } catch (Exception e) {
            // ExceptionHandler.addLog(e,string.valueof(recIds),'DocumentandEmailController','');  /*Add Exception to error log*/
            System.debug('Exception occurred: ' + e.getMessage());
            throw e;
        }
    }
    
    public static List<String> validateEmails(List<String> emailAddresses) {
        List<String> validEmails = new List<String>();
        for (String email : emailAddresses) {
            if (email != null && Pattern.matches('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$', email)) {
                validEmails.add(email);
            }
        }
        return validEmails;
    }
    @AuraEnabled
    public static Booking__c getBookingRecordViaReciept(Id recordId) {
        Receipt__c receipt = [SELECT Id, Booking__c FROM Receipt__c WHERE id = :recordId LIMIT 1];
        Booking__c booking = [SELECT Id,Project1__r.Name, Total_received_Amount__c,First_Applicant_Name__c
                              FROM Booking__c 
                              WHERE Id = :receipt.Booking__c 
                              LIMIT 1];
        //if (booking.Agreement_Cost__c <= booking.Total_received_Amount__c) {
        //system.debug(booking.Name);
        return booking;
        //} else {
        //return null;
        //}
    }
    
    @AuraEnabled
    public static String sendAgreementRequestMail(Id recId,String emailContent) {
        system.debug('emailContent'+emailContent);
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        String returnMessage;
        try {
            // Retrieve the Booking record
            List<Booking__c> bookings = [SELECT Id, Project__c, Email__c, Applicant_Name__c,Plot__r.Name, Project1__r.Name,
                                         CRM_Head__c, CRM_Head__r.Email, CRM_Manager__c, CRM_Manager__r.Email,
                                         Project_Sales_Head__c, Project_Sales_Head__r.Email,
                                         Sales_Head__c, Sales_Head__r.Email, OwnerId, Owner.Email
                                         FROM Booking__c WHERE Id = :recId LIMIT 1];
            
            // Retrieve co-applicants associated with the Booking
            //List<Co_Applicant__c> coApps = [SELECT Id, Name, Email__c, Booking__c FROM Co_Applicant__c WHERE Booking__c = :booking.Id];
            
            // Retrieve Org Wide Email Address
            //List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = :booking.Owner.Email];
            
            if (!bookings.isEmpty()) {
                Booking__c booking = bookings[0];
                // Prepare email details
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                if (booking.Email__c != null) {
                    sendTo.add(booking.Email__c);
                }
                
                email.setToAddresses(sendTo);
                email.setSubject('Agreement Execution Confirmation for '+booking.Plot__r.Name+'-'+booking.Project1__r.Name);
                email.setHtmlBody(emailContent);

                Set<String> lstCCEmail = BookingCCEmailUtil.getCCEmails(booking);
                if (!lstCCEmail.isEmpty()) {
                    email.setCcAddresses(new List<String>(lstCCEmail));
                }

                email.setSaveAsActivity(true);
                email.setWhatId(booking.Id);
                emailsToSend.add(email);
                // Send the email
                
                if (!emailsToSend.isEmpty()) {
                    Messaging.sendEmail(emailsToSend);
                }
                
                returnMessage = 'Email sent successfully';
            } else {
                returnMessage = 'Email address not specified in the Booking record.';
            }
        } catch (Exception e) {
            //ExceptionHandler.addLog(e,emailContent,'GenerateDocumnetController',recId);  /*Add Exception to error log*/
            returnMessage = 'Error sending email: ' + e.getMessage();
            system.debug('returnMessage'+e);
        }
        return returnMessage;
    }
    @AuraEnabled
    public static String sendHandoverEmail(Id bookingId) {
        
        System.debug('Handover Email Triggered for Booking: ' + bookingId);
        String result;
        
        try {
            // Fetch Booking + Owner Email
            Booking__c booking = [
                SELECT Id, Email__c, First_Applicant_Name__c, Email1__c,
                Owner.Email,
                CRM_Head__c, CRM_Head__r.Email, CRM_Manager__c, CRM_Manager__r.Email,
                Project_Sales_Head__c, Project_Sales_Head__r.Email,
                Sales_Head__c, Sales_Head__r.Email, OwnerId
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];

            if (booking == null || String.isBlank(booking.Email__c)) {
                return 'Customer Email missing on Booking.';
            }
            
            // Fetch Co-Applicants
            List<Co_Applicant__c> coApps = [
                SELECT Id, Email__c, Name, Booking__c
                FROM Co_Applicant__c
                WHERE Booking__c = :booking.Id
            ];
            
            // ===== 1. Generate PDF from VF Page =====
            PageReference pdfPage = Page.Key_Handover_Letter;
            pdfPage.getParameters().put('id', bookingId);
            
            Blob pdfBlob = !Test.isRunningTest()
                ? pdfPage.getContentAsPDF()
                : Blob.valueOf('testblob');
            
            // ===== 2. Prepare Email =====
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            // TO Addresses
            List<String> sendTo = new List<String>();
            sendTo.add(booking.Email__c);
            
            // Co-applicants
            for (Co_Applicant__c ca : coApps) {
                if (!String.isBlank(ca.Email__c)) {
                    sendTo.add(ca.Email__c);
                }
            }
            
            // CC Addresses
            Set<String> ccList = new Set<String>();
            if (!String.isBlank(booking.Owner.Email)) {
                ccList.add(booking.Owner.Email);
            }
            ccList.addAll(BookingCCEmailUtil.getCCEmails(booking));

            email.setToAddresses(sendTo);
            if (!ccList.isEmpty()) {
                email.setCcAddresses(new List<String>(ccList));
            }

            email.setSaveAsActivity(true);
            email.setWhatId(booking.Id);

            email.setSubject('Key Handover Confirmation – Zuari Garden City');
            
            // ===== 3. Email Body (HTML) =====
            String body = ''
                + '<p>Dear ' + booking.First_Applicant_Name__c + ',</p>'
                + '<p>We are delighted to inform you that the keys for your unit at '
                + '<strong>Zuari Garden City</strong>, located at KRS Road, Hulikere, '
                + 'Sreerangapatna Taluk, Mandya Dist-571606, have been handed over to you.</p>'
                
                + '<p>Please find the attached letter for your reference.</p>'
                
                + '<p>Kindly acknowledge receipt by signing the attached document, confirming that '
                + 'you have inspected all the keys and verified their working condition prior to the handover.</p>'
                
                + '<p>Thank you for choosing <strong>Zuari Infraworld India Limited</strong>. '
                + 'We look forward to serving you.</p>'
                
                + '<br/>'
                + '<p>Best regards,<br/>'
                + 'CRM Representative<br/>'
                + 'Zuari Infraworld India Limited</p>';
            
            email.setHtmlBody(body);
            
            // ===== 4. Attach PDF =====
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('Handover-' + booking.Id + '.pdf');
            attachment.setBody(pdfBlob);
            email.setFileAttachments(
                new Messaging.EmailFileAttachment[] { attachment }
            );
            
            // ===== 5. Send Email =====
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            
            result = 'Handover email sent successfully.';
        }
        catch (Exception e) {
            System.debug('Error Sending Handover Email: ' + e.getMessage());
            result = 'Error: ' + e.getMessage();
        }
        
        return result;
    }
    @AuraEnabled
    public static String sendKeyHandoverEmail(Id bookingId) {
        try {
            Booking__c booking = [
                SELECT Id,
                First_Applicant_Name__c,
                Email__c,
                Email1__c,
                Owner.Email,
                Project_Type__c,
                CRM_Head__c, CRM_Head__r.Email, CRM_Manager__c, CRM_Manager__r.Email,
                Project_Sales_Head__c, Project_Sales_Head__r.Email,
                Sales_Head__c, Sales_Head__r.Email, OwnerId
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];
            
            if (booking == null || String.isBlank(booking.Email__c)) {
                return 'Error: The primary email field (Email__c) is empty. Please provide a recipient email.';
            }
            
            PageReference pr;
            String pType = booking.Project_Type__c;
            
            if (pType == 'Villas') {
                pr = Page.VillasKeyHandoverVfp;
            } else if (pType == 'Row House') {
                pr = Page.RowHouseKeyHandoverVfp;
            } else if (pType == 'Apartments' || pType == 'Plots') {
                pr = Page.FlatKeyHandoverVfp;
            } else {
                return 'Error: No Key Handover document exists for Project Type: ' + pType;
            }
            
            pr.getParameters().put('id', String.valueOf(bookingId));
            Blob pdfBlob = Test.isRunningTest()
                ? Blob.valueOf('Test PDF Content')
                : pr.getContentAsPDF();
            
            List<String> toList = new List<String>();
            toList.add(booking.Email__c);
            
            if (String.isNotBlank(booking.Email1__c)) {
                toList.add(booking.Email1__c);
            }
            
            for (Co_Applicant__c ca : [
                SELECT Email__c
                FROM Co_Applicant__c
                WHERE Booking__c = :bookingId
            ]) {
                if (String.isNotBlank(ca.Email__c)) {
                    toList.add(ca.Email__c);
                }
            }
            
            toList = validateEmails(toList);
            
            if (toList.isEmpty()) {
                return 'Error: No valid email addresses found in the Booking or Co-Applicants.';
            }
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(toList);

            Set<String> ccSet = BookingCCEmailUtil.getCCEmails(booking);
            if (!ccSet.isEmpty()) {
                email.setCcAddresses(new List<String>(ccSet));
            }

            email.setSubject('Key Handover Confirmation – Zuari Garden City');
            
            String custName = String.isNotBlank(booking.First_Applicant_Name__c)
                ? booking.First_Applicant_Name__c
                : 'Customer';
            
            String body = ''
                + '<p>Dear ' + custName + ',</p>'
                + '<p>We are delighted to inform you that the keys for your unit at '
                + '<strong>Zuari Garden City</strong>, located at KRS Road, Hulikere, '
                + 'Sreerangapatna Taluk, Mandya Dist-571606, have been handed over to you.</p>'
                + '<p>Please find the attached letter for your reference.</p>'
                + '<p>Kindly acknowledge receipt by signing the attached document, confirming that '
                + 'you have inspected all the keys and verified their working condition prior to the handover.</p>'
                + '<p>Thank you for choosing <strong>Zuari Infraworld India Limited</strong>. '
                + 'We look forward to serving you.</p>'
                + '<br/>'
                + '<p>Best regards,<br/>'
                + 'CRM Representative<br/>'
                + 'Zuari Infraworld India Limited</p>';
            
            email.setHtmlBody(body);
            email.setWhatId(bookingId);
            email.setSaveAsActivity(true);
            
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            attach.setFileName('Key Handover Document.pdf');
            attach.setBody(pdfBlob);
            attach.setContentType('application/pdf');
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attach });
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            
            return 'Success: Key Handover email sent to ' + String.join(toList, ', ');
            
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
    @AuraEnabled
    public static String sendPossessionLetterViaProjectType(Id bookingId) {
        try {
            // Fetch Booking details including Project_Type__c
            Booking__c booking = [
                SELECT Id, First_Applicant_Name__c, Email__c, Email1__c, Owner.Email, Project_Type__c, Project__c, Unit_No__c,Possession_Date__c,
                CRM_Head__c, CRM_Head__r.Email, CRM_Manager__c, CRM_Manager__r.Email,
                Project_Sales_Head__c, Project_Sales_Head__r.Email,
                Sales_Head__c, Sales_Head__r.Email, OwnerId
                FROM Booking__c WHERE Id = :bookingId LIMIT 1
            ];
            
            if (booking == null || String.isBlank(booking.Email__c)) {
                return 'Error: The primary email field (Email__c) is empty. Please provide a recipient email.';
            }
            
            // Select appropriate Possession Letter page
            PageReference pr;
            String pType = booking.Project_Type__c;
            
            if (pType == 'Villas') {
                pr = Page.VillaPossessionLetter;
            } else if (pType == 'Row House') {
                pr = Page.RowHousePossessionLetter;
            } else if (pType == 'Apartments' || pType == 'Plots') {
                pr = Page.FlatPossessionLetter;
            } else {
                return 'Error: Unknown Project Type for Possession Letter: ' + pType;
            }
            pr.getParameters().put('id', String.valueOf(bookingId));
            Blob pdfBlob = Test.isRunningTest()
                ? Blob.valueOf('Test PDF Content')
                : pr.getContentAsPDF();
            
            // Prepare list of recipients
            List<String> toList = new List<String>();
            toList.add(booking.Email__c);
            
            if (String.isNotBlank(booking.Email1__c)) {
                toList.add(booking.Email1__c);
            }
            
            // Add Co-Applicant emails
            for (Co_Applicant__c ca : [
                SELECT Email__c FROM Co_Applicant__c WHERE Booking__c = :bookingId
            ]) {
                if (String.isNotBlank(ca.Email__c)) {
                    toList.add(ca.Email__c);
                }
            }
            // Validate emails
            toList = validateEmails(toList);
            if (toList.isEmpty()) {
                return 'Error: No valid email addresses found in Booking or Co-Applicants.';
            }
            
            // Compose email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(toList);
            
            // CC Booking Owner + team if present
            Set<String> ccSet = BookingCCEmailUtil.getCCEmails(booking);
            if (!ccSet.isEmpty()) {
                email.setCcAddresses(new List<String>(ccSet));
            }

            email.setSubject('Your Possession Letter from Zuari/Trifecta');
            
            String custName = String.isNotBlank(booking.First_Applicant_Name__c)
                ? booking.First_Applicant_Name__c
                : 'Customer';
            
            String body = ''
                + '<p>Dear ' + custName + ',</p>'
                + '<p>We are delighted to inform you the possession of your unit at <strong>' + (booking.Project__c != null ? booking.Project__c : '') + '</strong> is now ready.</p>'
                + '<p><b>Unit Number:</b> ' + (booking.Unit_No__c != null ? booking.Unit_No__c : '') + '</p>'
                + '<p>Please find the attached Possession Letter for your kind reference.</p>'
                + '<p>For any queries, feel free to reach out.<br/><br/>Thank you for choosing us!</p>'
                + '<br/><p>Best regards,<br/>CRM Representative</p>';
            
            email.setHtmlBody(body);
            email.setSaveAsActivity(true);
            email.setWhatId(booking.Id);
            
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            attach.setFileName('PossessionLetter.pdf');
            attach.setBody(pdfBlob);
            attach.setContentType('application/pdf');
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attach });
            
            // Send email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            return 'Success: Possession Letter sent successfully.'/* + String.join(toList, ', ')*/;
            
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
    
}