/**
 * Aura-facing service for the Site Visit QR feature:
 *  - getQrImageUrl: returns a QR image URL (rendered via the CSP-trusted
 *    api.qrserver.com) that encodes the SiteVisitQR redirect page URL.
 *  - sendQrCodeEmail: generates the QR image and emails it to the customer
 *    (Site_Visit__c -> SLead__c -> Lead.Email), following the existing
 *    OrgWideEmailAddress + EmailFileAttachment pattern used across the org.
 */
public with sharing class SiteVisitQRService {

    private static final String QR_BASE = 'https://api.qrserver.com/v1/create-qr-code/';
    private static final Integer QR_SIZE = 250;

    /** Full scannable URL of the SiteVisitQR redirect page for a Site Visit. */
    @TestVisible
    private static String buildRedirectUrl(Id recordId) {
        PageReference pr = Page.SiteVisitQR;
        pr.getParameters().put('id', recordId);
        return URL.getOrgDomainUrl().toExternalForm() + pr.getUrl();
    }

    /** QR image URL for display in the component (needs CSP Trusted Site for api.qrserver.com). */
    @AuraEnabled(cacheable=true)
    public static String getQrImageUrl(Id recordId) {
        try {
            String redirect = buildRedirectUrl(recordId);
            return QR_BASE + '?size=' + QR_SIZE + 'x' + QR_SIZE
                + '&data=' + EncodingUtil.urlEncode(redirect, 'UTF-8');
        } catch (Exception e) {
            throw new AuraHandledException('Unable to build the QR code URL: ' + e.getMessage());
        }
    }

    /** Generates the QR image and emails it to the linked Lead's email. Returns the address used. */
    @AuraEnabled
    public static String sendQrCodeEmail(Id recordId) {
        List<Site_Visit__c> svs = [
            SELECT Id, Name, SLead__c, SLead__r.Name, SLead__r.Email
            FROM Site_Visit__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        if (svs.isEmpty()) {
            throw new AuraHandledException('Site Visit not found.');
        }
        Site_Visit__c sv = svs[0];
        if (sv.SLead__c == null) {
            throw new AuraHandledException('No Lead is linked to this Site Visit.');
        }
        String toEmail = sv.SLead__r.Email;
        if (String.isBlank(toEmail)) {
            throw new AuraHandledException('The linked Lead does not have an email address.');
        }

        Blob qrBody = fetchQrImage(getQrImageUrl(recordId));
        if (qrBody == null) {
            throw new AuraHandledException('Could not generate the QR image. Please try again.');
        }

        String customerName = String.isNotBlank(sv.SLead__r.Name) ? sv.SLead__r.Name : 'Customer';

        Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
        att.setFileName('SiteVisit-' + sv.Name + '-QR.png');
        att.setBody(qrBody);
        att.setContentType('image/png');
        att.setInline(false);

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ toEmail });
        mail.setSubject('Your Site Visit QR Code');
        mail.setHtmlBody(
            '<p>Dear ' + customerName + ',</p>'
            + '<p>Please find your Site Visit QR code attached. Present this QR code at the site; '
            + 'our team will scan it to pull up your visit details.</p>'
            + '<p>Regards,<br/>Team</p>'
        );
        mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ att });
        mail.setSaveAsActivity(false);

        OrgWideEmailAddress owa = getOrgWideAddress();
        if (owa != null) {
            mail.setOrgWideEmailAddressId(owa.Id);
        }

        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        } catch (Exception e) {
            throw new AuraHandledException('Failed to send the email: ' + e.getMessage());
        }
        return toEmail;
    }

    /** Best-effort org-wide sender address; falls back to the running user when none exist. */
    private static OrgWideEmailAddress getOrgWideAddress() {
        List<OrgWideEmailAddress> owas = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        return owas.isEmpty() ? null : owas[0];
    }

    /** Downloads the QR PNG from the QR service (requires Remote Site Setting). */
    @TestVisible
    private static Blob fetchQrImage(String url) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        req.setTimeout(60000);
        HttpResponse res = new Http().send(req);
        return res.getStatusCode() == 200 ? res.getBodyAsBlob() : null;
    }
}

