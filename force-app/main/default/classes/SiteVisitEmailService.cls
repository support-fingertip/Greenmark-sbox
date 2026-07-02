/**
 * Class Name  : SiteVisitEmailService
 * Company     : Fingertipplus
 * @description : Bulk-safe email automation for Site Visits.
 *               - sendScheduledQrEmails: emails the customer (linked Lead) the EXISTING QR code for
 *                 the Site Visit when Status becomes 'Scheduled'. The QR is not stored on the record;
 *                 it is generated deterministically from the record Id via SiteVisitQRService, so we
 *                 reuse that URL and fetch the image rather than generating a new QR.
 *               - sendFeedbackEmails: emails the customer a link to the public SiteVisitFeedback page
 *                 when Status changes to 'Completed'.
 *               Both methods query once, build one email per record, and send in a single
 *               Messaging.sendEmail call (no SOQL/DML/email in loops).
 */
public with sharing class SiteVisitEmailService {

    // Keep QR image callouts under the per-transaction governor limit (100); chain the remainder.
    private static final Integer QR_CALLOUT_LIMIT = 90;

    /**
     * Emails the linked Lead the Site Visit QR code as a PNG attachment.
     * @param svIds Site Visit Ids whose Status just became 'Scheduled'.
     */
    public static void sendScheduledQrEmails(Set<Id> svIds) {
        if (svIds == null || svIds.isEmpty()) {
            return;
        }

        List<Site_Visit__c> svs = [
            SELECT Id, Name, SLead__c, SLead__r.Name, SLead__r.Email
            FROM Site_Visit__c
            WHERE Id IN :svIds
        ];

        OrgWideEmailAddress owa = getOrgWideAddress();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Set<Id> overflow = new Set<Id>();
        Integer processed = 0;

        for (Site_Visit__c sv : svs) {
            if (String.isBlank(sv.SLead__r.Email)) {
                continue; // no customer email -> skip, don't error the batch
            }
            if (processed >= QR_CALLOUT_LIMIT) {
                overflow.add(sv.Id); // defer to a chained job to respect the callout limit
                continue;
            }
            processed++;

            Blob qrBody = fetchQrImage(SiteVisitQRService.getQrImageUrl(sv.Id));
            if (qrBody == null) {
                continue;
            }

            String customerName = String.isNotBlank(sv.SLead__r.Name) ? sv.SLead__r.Name : 'Customer';

            Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
            att.setFileName('SiteVisit-' + sv.Name + '-QR.png');
            att.setBody(qrBody);
            att.setContentType('image/png');
            att.setInline(false);

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ sv.SLead__r.Email });
            mail.setSubject('Your Site Visit QR Code');
            mail.setHtmlBody(
                '<p>Dear ' + customerName + ',</p>'
                + '<p>Please find your Site Visit QR code attached. Present this QR code at the site; '
                + 'our team will scan it to pull up your visit details.</p>'
                + '<p>Regards,<br/>Team</p>'
            );
            mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ att });
            mail.setSaveAsActivity(false);
            if (owa != null) {
                mail.setOrgWideEmailAddressId(owa.Id);
            }
            mails.add(mail);
        }

        sendEmails(mails);

        // Chain the overflow (only when a single transaction exceeds the callout budget).
        if (!overflow.isEmpty()) {
            System.enqueueJob(new SiteVisitEmailQueueable(overflow, SiteVisitEmailQueueable.MODE_SCHEDULED));
        }
    }

    /**
     * Emails the linked Lead a link to the public customer feedback page.
     * @param svIds Site Visit Ids whose Status just transitioned to 'Completed'.
     */
    public static void sendFeedbackEmails(Set<Id> svIds) {
        if (svIds == null || svIds.isEmpty()) {
            return;
        }

        List<Site_Visit__c> svs = [
            SELECT Id, Name, SLead__c, SLead__r.Name, SLead__r.Email
            FROM Site_Visit__c
            WHERE Id IN :svIds
        ];

        String baseUrl = getFeedbackBaseUrl();
        OrgWideEmailAddress owa = getOrgWideAddress();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        for (Site_Visit__c sv : svs) {
            if (String.isBlank(sv.SLead__r.Email)) {
                continue;
            }

            String feedbackUrl = baseUrl + '/apex/SiteVisitFeedback?id=' + sv.Id;
            String customerName = String.isNotBlank(sv.SLead__r.Name) ? sv.SLead__r.Name : 'Customer';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ sv.SLead__r.Email });
            mail.setSubject('We would love your feedback on your Site Visit');
            mail.setHtmlBody(
                '<p>Dear ' + customerName + ',</p>'
                + '<p>Thank you for visiting us. We would appreciate your feedback on your experience. '
                + 'Please click the link below to rate your visit and share your comments:</p>'
                + '<p><a href="' + feedbackUrl + '">Share your feedback</a></p>'
                + '<p>Regards,<br/>Team</p>'
            );
            mail.setSaveAsActivity(false);
            if (owa != null) {
                mail.setOrgWideEmailAddressId(owa.Id);
            }
            mails.add(mail);
        }

        sendEmails(mails);
    }

    /** Base URL for the feedback link: the configured label, else the org domain. */
    private static String getFeedbackBaseUrl() {
        String labelUrl = Label.Site_Visit_Feedback_Base_URL;
        if (String.isNotBlank(labelUrl)) {
            return labelUrl.removeEnd('/');
        }
        return URL.getOrgDomainUrl().toExternalForm();
    }

    /** Best-effort org-wide sender address; null falls back to the running user. */
    private static OrgWideEmailAddress getOrgWideAddress() {
        List<OrgWideEmailAddress> owas = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        return owas.isEmpty() ? null : owas[0];
    }

    /** Single send point with error handling so one bad batch never aborts the transaction. */
    private static void sendEmails(List<Messaging.SingleEmailMessage> mails) {
        if (mails.isEmpty()) {
            return;
        }
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'SiteVisitEmailService.sendEmails failed: ' + e.getMessage());
        }
    }

    /** Downloads the QR PNG from the QR service (QRServer Remote Site Setting required). */
    @TestVisible
    private static Blob fetchQrImage(String url) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod('GET');
            req.setTimeout(60000);
            HttpResponse res = new Http().send(req);
            return res.getStatusCode() == 200 ? res.getBodyAsBlob() : null;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'SiteVisitEmailService.fetchQrImage failed: ' + e.getMessage());
            return null;
        }
    }
}
