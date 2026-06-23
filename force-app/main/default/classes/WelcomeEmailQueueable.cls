public class WelcomeEmailQueueable implements Queueable, Database.AllowsCallouts {

    private Id bookingId;
    private String demandId1;
    private String demandId2;
    private String projectType;
    private Id quoteId;
    private String emailContent;
    private List<String> toAddresses;
    private List<String> contentIds;
    private List<String> ccEmails;
    private String subject;

    public WelcomeEmailQueueable(Id bookingId, String demandId1, String demandId2,
            String projectType, Id quoteId, String emailContent,
            List<String> toAddresses, List<String> contentIds,
            List<String> ccEmails, String subject) {
        this.bookingId = bookingId;
        this.demandId1 = demandId1;
        this.demandId2 = demandId2;
        this.projectType = projectType;
        this.quoteId = quoteId;
        this.emailContent = emailContent;
        this.toAddresses = toAddresses;
        this.contentIds = contentIds;
        this.ccEmails = ccEmails;
        this.subject = subject;
    }

    public void execute(QueueableContext context) {
        List<Messaging.EmailFileAttachment> emailAttachments =
                new List<Messaging.EmailFileAttachment>();

        // ── Content-document attachments (user-selected files) ──
        if (contentIds != null && !contentIds.isEmpty()) {
            Set<Id> docIds = new Set<Id>();
            for (String cid : contentIds) { docIds.add(cid); }
            for (ContentVersion cv : [SELECT Title, FileExtension, VersionData
                                      FROM ContentVersion
                                      WHERE ContentDocumentId IN :docIds]) {
                Messaging.EmailFileAttachment a = new Messaging.EmailFileAttachment();
                a.setFileName(cv.Title + '.' + cv.FileExtension);
                a.setBody(cv.VersionData);
                emailAttachments.add(a);
            }
        }
        system.debug('toAddresses'+toAddresses);
        // ── Booking-form attachment (project-type specific) ──
        String quotePdf = 'TrifectaCostsheet';
        Messaging.EmailFileAttachment bookingFormAttach;
        system.debug('projectType'+projectType);
        if (projectType == 'Apartments') {
            system.debug('bookingId'+bookingId);
            bookingFormAttach = generatePdf('Trifecta_Booking_Form', bookingId);
            system.debug('bookingId1'+bookingId);
            quotePdf = 'TrifectaCostsheet';
        } else if (projectType == 'Row House') {
            bookingFormAttach = generatePdf('TrifectaRowHouseBookingForm', bookingId);
            quotePdf = 'TrifectaRowHouseCostSheet';
        } else if (projectType == 'Villas') {
            system.debug('bookingId'+bookingId);
            
            try {
                bookingFormAttach = generatePdf('LandVillaBookingForm', bookingId);
                system.debug('LandVillaBookingForm generated: ' + (bookingFormAttach != null));
            } catch (Exception e) {
                system.debug('ERROR generating LandVillaBookingForm: ' + e.getMessage() + ' | ' + e.getStackTraceString());
            }
            
            try {
                Messaging.EmailFileAttachment villaConst = generatePdf('ConstructionVillaBookingForm', bookingId);
                system.debug('bookingId2'+bookingId);
                system.debug('ConstructionVillaBookingForm generated: ' + (villaConst != null));
                if (villaConst != null) { emailAttachments.add(villaConst); }
            } catch (Exception e) {
                system.debug('ERROR generating ConstructionVillaBookingForm: ' + e.getMessage() + ' | ' + e.getStackTraceString());
            }
            
            system.debug('bookingId3'+bookingId);
            quotePdf = 'trifectaVillaCostSheet';
        }
        system.debug('projectType1'+projectType);
        // ── Cost-sheet attachment ──
        Messaging.EmailFileAttachment costSheet = generatePdf(quotePdf, quoteId);

        // ── Demand-note attachments via Demand_Note_Send (Demand_Raised__c Id) ──
        Messaging.EmailFileAttachment demandNote1;
        if (String.isNotBlank(demandId1) && !demandId1.startsWith('Error')) {
            demandNote1 = generatePdf('Demand_Note_Send', demandId1);
            if (projectType == 'Villas' && demandNote1 != null) {
                demandNote1.setFileName('Land Agreement Demand Note.pdf');
            }
            else
            {
                demandNote1.setFileName('Demand Note.pdf');
            }
        }
        system.debug('toAddresses1'+toAddresses);
        Messaging.EmailFileAttachment demandNote2;
        if (projectType == 'Villas' &&
            String.isNotBlank(demandId2) && !demandId2.startsWith('Error')) {
            demandNote2 = generatePdf('Demand_Note_Send', demandId2);
            if (demandNote2 != null) {
                demandNote2.setFileName('Construction Agreement Demand Note.pdf');
            }
        }

        // ── Consolidated-receipt attachment ──
        Messaging.EmailFileAttachment consolidated =
                generatePdf('ConsolidatedReceipt', bookingId);

        // ── Assemble attachment list ──
        if (bookingFormAttach != null) { emailAttachments.add(bookingFormAttach); }
        if (costSheet != null)         { emailAttachments.add(costSheet); }
        if (demandNote1 != null)       { emailAttachments.add(demandNote1); }
        if (demandNote2 != null)       { emailAttachments.add(demandNote2); }
        if (consolidated != null)      { emailAttachments.add(consolidated); }
        system.debug('toAddresses2'+toAddresses);
        // ── Build and send email ──
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        if (!Test.isRunningTest()) {
            String displayName = Label.Default_Email_Address_Label;
            String EnableOrgWideEmailToMails = Label.EnableOrgWideEmailToMails;
            
            List<OrgWideEmailAddress> orgWide = [
                SELECT Id FROM OrgWideEmailAddress
                WHERE DisplayName = :displayName LIMIT 1];
            if (!orgWide.isEmpty() && EnableOrgWideEmailToMails == 'True') {
                mail.setOrgWideEmailAddressId(orgWide[0].Id);
            }
            else {
                // fallback to default OWA
                mail.setSenderDisplayName(UserInfo.getName());
                mail.setReplyTo(UserInfo.getUserEmail());
            }
            system.debug('displayName'+displayName);
            system.debug('orgWide'+orgWide[0].Id);
        }  

        mail.setToAddresses(toAddresses);

        // Build the CC list: any addresses passed in plus the Booking team / label CCs
        Set<String> ccSet = new Set<String>();
        if (ccEmails != null) {
            ccSet.addAll(ccEmails);
        }
        List<Booking__c> bks = [
            SELECT Id, CRM_Head__c, CRM_Head__r.Email, CRM_Manager__c, CRM_Manager__r.Email,
                   Project_Sales_Head__c, Project_Sales_Head__r.Email,
                   Sales_Head__c, Sales_Head__r.Email, OwnerId, Owner.Email
            FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        if (!bks.isEmpty()) {
            ccSet.addAll(BookingCCEmailUtil.getCCEmails(bks[0]));
        }
        if (!ccSet.isEmpty()) {
            mail.setCcAddresses(new List<String>(ccSet));
        }
        mail.setSaveAsActivity(true);
        mail.setWhatId(bookingId);

        system.debug('emailContent'+emailContent);
        mail.setSubject(subject);
        // Remove stray blank paragraphs / zero-width chars before setting body
        emailContent = sanitizeEmailHtml(emailContent);
        mail.setHtmlBody(emailContent);
        if (!emailAttachments.isEmpty()) {
            mail.setFileAttachments(emailAttachments);
        }

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }

    /**
     * Strips stray characters that survive the editor cleanup and can render as
     * an extra blank line (e.g. a zero-width / BOM character left in the saved
     * template before an empty paragraph), and removes blank paragraphs.
     *
     * Uses possessive quantifiers (*+) throughout so the matcher never
     * backtracks — this avoids Apex's "Regex too complicated" LimitException on
     * large, richly-formatted bodies (e.g. after the user applies a font size,
     * which wraps content in <span> tags). The empty-paragraph match also
     * tolerates empty <span> wrappers so styled-but-blank spacer paragraphs
     * (<p><span style="font-size:14px;"><br></span></p>) are removed, while
     * paragraphs that contain real text are left untouched.
     */
    @TestVisible
    private static String sanitizeEmailHtml(String html) {
        if (String.isBlank(html)) { return html; }
        // Strip BOM / zero-width chars first — Java regex \s does not match U+FEFF
        html = html.replaceAll('[\\x{FEFF}\\x{200B}\\x{200C}\\x{200D}]', '');
        // Remove empty paragraphs (attributes, nbsp, whitespace, <br>, empty spans)
        html = html.replaceAll(
            '(?i)<p[^>]*+>(?:\\s|&nbsp;|&#160;|<br[^>]*+>|</?span[^>]*+>)*+</p>',
            ''
        );
        return html;
    }

    private Messaging.EmailFileAttachment generatePdf(String vfPageName, Id recordId) {
        try {
            PageReference vfPage = new PageReference('/apex/' + vfPageName);
            vfPage.getParameters().put('id', recordId);
            vfPage.setRedirect(true);
            
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Test PDF Content');
            } else {
                pdfBlob = vfPage.getContentAsPDF();
            }
            
            Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
            att.setFileName(vfPageName + '.pdf');
            att.setBody(pdfBlob);
            att.setContentType('application/pdf');
            return att;
        } catch (Exception e) {
            system.debug('generatePdf FAILED for ' + vfPageName + ' | recordId: ' + recordId 
                         + ' | Error: ' + e.getMessage() + ' | ' + e.getStackTraceString());
            return null;
        }
    }

    private Messaging.EmailFileAttachment generatePdf(String vfPageName, String recordIdStr) {
        return generatePdf(vfPageName, Id.valueOf(recordIdStr));
    }
}