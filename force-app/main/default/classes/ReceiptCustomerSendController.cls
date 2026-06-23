public with sharing class ReceiptCustomerSendController {

    public class ReceiptOptionWrapper {
        @AuraEnabled public Id receiptId;
        @AuraEnabled public String receiptName;
    }

    public class ReceiptEmailPreviewWrapper {
        @AuraEnabled public String subject;
        @AuraEnabled public String emailContent;
        @AuraEnabled public String previewUrl;
    }

    @AuraEnabled
    public static List<ReceiptOptionWrapper> getReceiptsForBooking(Id bookingId) {
        List<ReceiptOptionWrapper> result = new List<ReceiptOptionWrapper>();

        if (bookingId == null) {
            return result;
        }

        List<Receipt__c> receipts = [
            SELECT Id, Name, Receipt_Date__c, Receipt_Payment_Type__c
            FROM Receipt__c
            WHERE Booking__c = :bookingId
            ORDER BY CreatedDate DESC
        ];
        
        for (Receipt__c rec : receipts) {
            ReceiptOptionWrapper wrap = new ReceiptOptionWrapper();
            wrap.receiptId = rec.Id;
            
            String formattedDate = rec.Receipt_Date__c != null 
                ? String.valueOf(rec.Receipt_Date__c.day()).leftPad(2,'0') + '-' +
                String.valueOf(rec.Receipt_Date__c.month()).leftPad(2,'0') + '-' +
                String.valueOf(rec.Receipt_Date__c.year())
                : '';
            
            wrap.receiptName = rec.Name + ' / ' + formattedDate + ' / ' + rec.Receipt_Payment_Type__c;
            result.add(wrap);
        }
        return result;
    }

    @AuraEnabled
    public static ReceiptEmailPreviewWrapper getReceiptEmailPreview(Id receiptId) {
        try {
            return buildReceiptEmailPreview(receiptId);
        } catch (Exception e) {
            throw new AuraHandledException('Error loading receipt preview: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String sendReceiptToCustomer(Id receiptId, String emailContent, List<Id> extraFileIds) {
        try {
            return sendReceiptInternal(receiptId, emailContent, extraFileIds);
        } catch (Exception e) {
            throw new AuraHandledException('Error sending receipt: ' + e.getMessage());
        }
    }

    public static ReceiptEmailPreviewWrapper buildReceiptEmailPreview(Id receiptId) {
        if (receiptId == null) {
            throw new AuraHandledException('Please select a receipt.');
        }

        Receipt__c receipt = [
            SELECT Id, Booking__c, Name, Receipt_Date__c, Total_Received_Amount__c,
            Receipt_Amount_Without_Tds__c, Project_Block_Name__c,Type__c
            FROM Receipt__c
            WHERE Id = :receiptId
            LIMIT 1
        ];

        if (receipt.Booking__c == null) {
            throw new AuraHandledException('Booking not found for selected receipt.');
        }

        Decimal totalAmount = 0;
        List<Receipt_Line_Item__c> receiptItems = [
            SELECT Id, Name, Bank_Name__c, Mode_of_Payment__c, Received_Amount__c, Payment_Type__c
            FROM Receipt_Line_Item__c
            WHERE Receipt__c = :receipt.Id
            AND Payment_Type__c != 'TDS'
        ];

        Set<String> bankSet = new Set<String>();
        Set<String> paymentModeSet = new Set<String>();
        Set<String> paymentForSet = new Set<String>();

        for (Receipt_Line_Item__c item : receiptItems) {
            if (item.Received_Amount__c != null) {
                totalAmount += item.Received_Amount__c;
            }
            if (String.isNotBlank(item.Bank_Name__c)) {
                bankSet.add(item.Bank_Name__c);
            }
            if (String.isNotBlank(item.Mode_of_Payment__c)) {
                paymentModeSet.add(item.Mode_of_Payment__c);
            }
            if (String.isNotBlank(item.Name)) {
                paymentForSet.add(item.Name);
            }
        }

        String BANK_NAME = String.join(new List<String>(bankSet), ', ');
        String PAYMENT_MODE = String.join(new List<String>(paymentModeSet), ', ');
        String PAYMENT_FOR = String.join(new List<String>(paymentForSet), ', ');

        Booking__c booking = [
            SELECT Id,
            Email__c,
            Email1__c,
            First_Applicant_Name__c,
            Owner.Email,
            Project__c,
            Block_Name__c,
            Block_Id__c,
            Unit_No__c,
            Owner_Phone_Number__c,
            Company_Name__c,
            Mobile__c,
            CRM_Executive_Contact_No__c
            FROM Booking__c
            WHERE Id = :receipt.Booking__c
            LIMIT 1
        ];

        List<General_Settings__c> settingList = [
            SELECT Template_Body__c, Subject__c
            FROM General_Settings__c
            WHERE Project_Name1__c INCLUDES (:booking.Project__c)
            AND Type__c = 'Payment Receipt'
            LIMIT 1
        ];
        
        Block__c block = [select Id,Name,Land_Company_Name__c,Construction_Company_Name__c,Company_Name__c from Block__c where Id =:booking.Block_Id__c];

        string companyName = 'TRIFECTA PROJECTS PVT LTD';
        if(receipt.Type__c =='Land')
        {
            companyName = block.Land_Company_Name__c;
        }
        else if(receipt.Type__c =='Construction')
        {
            companyName = block.Construction_Company_Name__c;
        }
        else if(receipt.Type__c =='Apartments' || receipt.Type__c =='Row House')
        {
            companyName = block.Company_Name__c;
        }
        String template = '';
        String subject = 'Receipt for Your Payment';

        if (!settingList.isEmpty()) {
            template = settingList[0].Template_Body__c != null ? settingList[0].Template_Body__c : '';
            subject = settingList[0].Subject__c != null ? settingList[0].Subject__c : subject;
        }

        template = template.replace('##APPLICANT_NAME##', booking.First_Applicant_Name__c != null ? booking.First_Applicant_Name__c : '');
        template = template.replace('##PROJECT_NAME##', booking.Project__c != null ? booking.Project__c : '');
        template = template.replace('##BLOCK_NAME##', booking.Block_Name__c != null ? String.valueOf(booking.Block_Name__c) : '');
        template = template.replace('##UNIT_NUMBER##', booking.Unit_No__c != null ? String.valueOf(booking.Unit_No__c) : '');
        template = template.replace('##CRM_PHONE##', booking.Owner_Phone_Number__c != null ? String.valueOf(booking.Owner_Phone_Number__c) : '');
        template = template.replace('##COMAPANY_NAME##', companyName != null ? String.valueOf(companyName) : '');

        NumberTOWordConvertion conversion = new NumberTOWordConvertion();
        String amountInWords = totalAmount != null ? conversion.getNumberTOWordConvertion(totalAmount) : '';

        template = template.replace('##AMOUNT_IN_WORDS##', amountInWords != null ? amountInWords : '');
        template = template.replace('##AMOUNT##', String.valueOf(totalAmount != null ?  totalAmount.setScale(2).format() : '0.00'));
        // Date in dd-MM-yyyy format
        String formattedDate = '';
        if (receipt.Receipt_Date__c != null) {
            Date d = receipt.Receipt_Date__c;
            String day   = String.valueOf(d.day()).leftPad(2, '0');
            String month = String.valueOf(d.month()).leftPad(2, '0');
            String year  = String.valueOf(d.year());
            formattedDate = day + '-' + month + '-' + year;
        }
        template = template.replace('##TRANSACTION_DATE##', formattedDate);
        template = template.replace('##TRANSACTION_NO##', receipt.Name != null ? receipt.Name : '');
        template = template.replace('##BANK_NAME##', BANK_NAME != null ? BANK_NAME : '');
        template = template.replace('##PAYMENT_MODE##', PAYMENT_MODE != null ? PAYMENT_MODE : '');
        template = template.replace('##PAYMENT_FOR##', PAYMENT_FOR != null ? PAYMENT_FOR : '');

        subject = subject.replace('##PROJECT_NAME##', booking.Project__c != null ? booking.Project__c : '');
        subject = subject.replace('##BLOCK_NAME##', booking.Block_Name__c != null ? String.valueOf(booking.Block_Name__c) : '');
        subject = subject.replace('##UNIT_NUMBER##', booking.Unit_No__c != null ? String.valueOf(booking.Unit_No__c) : '');

        ReceiptEmailPreviewWrapper wrap = new ReceiptEmailPreviewWrapper();
        wrap.subject = subject;
        wrap.emailContent = template;
        wrap.previewUrl = '/apex/Receipt?id=' + receipt.Id;
        return wrap;
    }

    public static String sendReceiptInternal(Id receiptId, String emailContent, List<Id> extraFileIds) {
        ReceiptEmailPreviewWrapper preview = buildReceiptEmailPreview(receiptId);
        
        Receipt__c receipt = [
            SELECT Id, Booking__c, Name, Receipt_Date__c, Total_Received_Amount__c,
            Receipt_Amount_Without_Tds__c, Project_Block_Name__c
            FROM Receipt__c
            WHERE Id = :receiptId
            LIMIT 1
        ];

        Booking__c booking = [
            SELECT Id,
                   Email__c,
                   Email1__c,
                   First_Applicant_Name__c,
                   Owner.Email,
                   Mobile__c,
                   Unit_No__c,
                   CRM_Executive_Contact_No__c,
                   CRM_Head__c, CRM_Head__r.Email, CRM_Manager__c, CRM_Manager__r.Email,
                   Project_Sales_Head__c, Project_Sales_Head__r.Email,
                   Sales_Head__c, Sales_Head__r.Email, OwnerId
            FROM Booking__c
            WHERE Id = :receipt.Booking__c
            LIMIT 1
        ];

        List<Co_Applicant__c> coApps = [
            SELECT Id, Email__c
            FROM Co_Applicant__c
            WHERE Booking__c = :booking.Id
        ];

        List<String> toList = new List<String>();

        if (String.isNotBlank(booking.Email__c)) {
            toList.add(booking.Email__c);
        }
        if (String.isNotBlank(booking.Email1__c)) {
            toList.add(booking.Email1__c);
        }
        for (Co_Applicant__c ca : coApps) {
            if (String.isNotBlank(ca.Email__c)) {
                toList.add(ca.Email__c);
            }
        }

        toList = DocumentandEmailController.validateEmails(toList);

        if (toList.isEmpty()) {
            return 'No valid email addresses found for customer.';
        }

        Set<String> ccSet = new Set<String>();
        if (String.isNotBlank(booking.Owner.Email)) {
            ccSet.add(booking.Owner.Email);
        }
        ccSet.addAll(BookingCCEmailUtil.getCCEmails(booking));
        List<String> ccList = new List<String>(ccSet);

        PageReference receiptPage = Page.Receipt;
        receiptPage.getParameters().put('id', receiptId);
        Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('testblob') : receiptPage.getContentAsPDF();

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toList);

        if (!ccList.isEmpty()) {
            email.setCcAddresses(ccList);
        }
        String displayName = Label.Default_Email_Address_Label;
        if (!Test.isRunningTest()) {
            List<OrgWideEmailAddress> orgWideEmail = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE DisplayName =: displayName
                LIMIT 1
            ];
            if (!orgWideEmail.isEmpty()) {
                email.setOrgWideEmailAddressId(orgWideEmail[0].Id);
            }
        }
        String cleanHtml = String.isNotBlank(emailContent) ? emailContent : preview.emailContent;
        
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
        
        system.debug(htmlBody);
        
        email.setSubject(preview.subject);
        email.setHtmlBody(htmlBody);
        email.setSaveAsActivity(true);
        email.setWhatId(booking.Id);

        List<Messaging.EmailFileAttachment> allAttachments = new List<Messaging.EmailFileAttachment>();

        Messaging.EmailFileAttachment receiptAttachment = new Messaging.EmailFileAttachment();
        receiptAttachment.setFileName('Receipt.pdf');
        receiptAttachment.setBody(pdfBlob);
        receiptAttachment.setContentType('application/pdf');
        allAttachments.add(receiptAttachment);

        if (extraFileIds != null && !extraFileIds.isEmpty()) {
            for (ContentVersion cv : [
                SELECT Id, Title, FileExtension, VersionData
                FROM ContentVersion
                WHERE ContentDocumentId IN :extraFileIds
                AND IsLatest = true
            ]) {
                Messaging.EmailFileAttachment extraAttachment = new Messaging.EmailFileAttachment();
                String fileName = cv.Title;

                if (String.isNotBlank(cv.FileExtension)) {
                    fileName += '.' + cv.FileExtension;
                }

                extraAttachment.setFileName(fileName);
                extraAttachment.setBody(cv.VersionData);
                extraAttachment.setContentType(getContentTypeFromExtension(cv.FileExtension));
                allAttachments.add(extraAttachment);
            }
        }

        email.setFileAttachments(allAttachments);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

        if (Label.Enable_whatsapp_notifications == 'TRUE') {
            List<Receipt__c> receipts = [
                SELECT Id,
                Booking__r.First_Applicant_Name__c,
                Booking__r.Mobile__c,
                Total_Received_Amount__c,
                Receipt_Amount_Without_Tds__c,
                Booking__r.Unit_No__c,
                Project_Block_Name__c,
                Booking__r.CRM_Executive_Contact_No__c,
                Booking__r.Owner_Email__c
                FROM Receipt__c
                WHERE Id = :receiptId
            ];

            if (!receipts.isEmpty()) {
                WhatsappController wactrl = new WhatsappController(receipts, '7');
                System.enqueueJob(wactrl);
            }
        }

        return 'Receipt Document Email and WhatsApp notifications Sent to customer successfully.';
    }

    private static String getContentTypeFromExtension(String ext) {
        if (String.isBlank(ext)) {
            return 'application/octet-stream';
        }

        ext = ext.toLowerCase();

        if (ext == 'pdf') return 'application/pdf';
        if (ext == 'png') return 'image/png';
        if (ext == 'jpg' || ext == 'jpeg') return 'image/jpeg';
        if (ext == 'doc') return 'application/msword';
        if (ext == 'docx') return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        if (ext == 'xls') return 'application/vnd.ms-excel';
        if (ext == 'xlsx') return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

        return 'application/octet-stream';
    }
}