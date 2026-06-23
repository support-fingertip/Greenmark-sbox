public class TicketClosureEmailService {

    public static void sendClosureEmails(List<Id> ticketIds) {
        
        List<Ticket__c> tickets = [
            SELECT Id,
            Name,
            Description__c,
            Category__c,
            Priority__c,
            Raised_Date__c,
            Actual_Resolution_Date__c,
            Resolution_Remarks__c,
            Unit__r.Name,
            Project__r.Name,
            Block__c,
            Block__r.Name,
            Booking__r.Email__c,
            Booking__r.First_Applicant_Name__c,
            Booking__r.CRM_Head__c, Booking__r.CRM_Head__r.Email,
            Booking__r.CRM_Manager__c, Booking__r.CRM_Manager__r.Email,
            Booking__r.Project_Sales_Head__c, Booking__r.Project_Sales_Head__r.Email,
            Booking__r.Sales_Head__c, Booking__r.Sales_Head__r.Email,
            Booking__r.OwnerId, Booking__r.Owner.Email
            FROM   Ticket__c
            WHERE  Id IN :ticketIds
        ];
        
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        List<Ticket__c> ticketsToUpdate = new List<Ticket__c>();
        String displayName = Label.Default_Email_Address_Label;
        // Set OrgWideEmailAddress
        List<OrgWideEmailAddress> orgWideEmail = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName =: displayName LIMIT 1];
        
        
        
        for (Ticket__c ticket : tickets) {

            String toEmail = ticket.Booking__r?.Email__c;
            if (String.isBlank(toEmail)) {
                System.debug('No email found on Booking for ticket: '
                             + ticket.Name);
                continue;
            }

            Messaging.SingleEmailMessage mail =
                new Messaging.SingleEmailMessage();

            mail.setToAddresses(new List<String>{ toEmail });
            Set<String> ccSet = BookingCCEmailUtil.getCCEmails(ticket.Booking__r);
            if (!ccSet.isEmpty()) {
                mail.setCcAddresses(new List<String>(ccSet));
            }
            mail.setSubject(buildSubject(ticket));
            mail.setHtmlBody(buildHtmlBody(ticket));
            mail.setSaveAsActivity(true);
            mail.setWhatId(ticket.Booking__c);
            String EnableOrgWideEmailToMails = Label.EnableOrgWideEmailToMails;
            if (!orgWideEmail.isEmpty() && EnableOrgWideEmailToMails == 'True') {
                mail.setOrgWideEmailAddressId(orgWideEmail[0].Id);
            }
            else {
                // fallback to default OWA
                mail.setSenderDisplayName(UserInfo.getName());
                mail.setReplyTo(UserInfo.getUserEmail());
            }

            emailsToSend.add(mail);

            Ticket__c toUpdate               = new Ticket__c();
            toUpdate.Id                      = ticket.Id;
            toUpdate.Closure_Email_Sent__c   = true;
            toUpdate.Closure_Email_Sent_Date__c = DateTime.now();
            ticketsToUpdate.add(toUpdate);
        }

        if (!emailsToSend.isEmpty()) {
            try {
                Messaging.sendEmail(emailsToSend);
            } catch (Exception e) {
                System.debug('Email send error: ' + e.getMessage());
                throw new AuraHandledException(
                    'Failed to send closure email: ' + e.getMessage());
            }
        }

        if (!ticketsToUpdate.isEmpty()) {
            update ticketsToUpdate;
        }
    }

    // ── Subject ───────────────────────────────────────────────────────
    private static String buildSubject(Ticket__c ticket) {
        return 'Your complaint has been resolved — '
             + ticket.Name
             + ' | '
             + (ticket.Project__r?.Name != null
                ? ticket.Project__r.Name : '');
    }

    // ── HTML body — uses only queried fields ──────────────────────────
    private static String buildHtmlBody(Ticket__c ticket) {

        // ── pull all values safely — no undeclared variables ──────────
        String customerName = ticket.Booking__r?.First_Applicant_Name__c != null
                              ? ticket.Booking__r.First_Applicant_Name__c
                              : 'Customer';
        String ticketNo     = ticket.Name != null
                              ? ticket.Name : '';
        String description  = ticket.Description__c != null
                              ? ticket.Description__c : '';
        String category     = ticket.Category__c != null
                              ? ticket.Category__c : '';
        String priority     = ticket.Priority__c != null
                              ? ticket.Priority__c : '';
        String projectName  = ticket.Project__r?.Name != null
                              ? ticket.Project__r.Name : '';
        String unitName     = ticket.Unit__r?.Name != null
                              ? ticket.Unit__r.Name : '';
        String block        = ticket.Block__c != null
                              ? ticket.Block__r.Name : '';
        String raisedDate   = ticket.Raised_Date__c != null
                              ? ticket.Raised_Date__c.format() : '';
        String resolvedDate = ticket.Actual_Resolution_Date__c != null
                              ? ticket.Actual_Resolution_Date__c.format() : '';
        String resolution   = ticket.Resolution_Remarks__c != null
                              ? ticket.Resolution_Remarks__c : '';

        // unit + block combined display
        String unitDisplay  = unitName;
        if (String.isNotBlank(block)) {
            unitDisplay += ' — Block ' + block;
        }

        return '<!DOCTYPE html>'
            + '<html>'
            + '<head>'
            + '<meta charset="UTF-8"/>'
            + '<style>'
            + 'body{margin:0;padding:0;background:#f4f4f4;font-family:Arial,sans-serif;}'
            + '.wrapper{max-width:620px;margin:30px auto;background:#ffffff;'
            + '         border-radius:8px;overflow:hidden;'
            + '         box-shadow:0 2px 8px rgba(0,0,0,0.08);}'
            + '.header{background:#02323e;padding:28px 32px;}'
            + '.header h1{color:#ffffff;margin:0;font-size:22px;font-weight:700;}'
            + '.header p{color:#a8d5c6;margin:6px 0 0;font-size:13px;}'
            + '.resolved-badge{display:inline-block;background:#28a745;color:#fff;'
            + '                font-size:12px;font-weight:600;padding:5px 16px;'
            + '                border-radius:20px;margin-top:12px;}'
            + '.body{padding:28px 32px;}'
            + '.greeting{font-size:16px;color:#1a1a2e;margin:0 0 12px;font-weight:600;}'
            + '.intro{font-size:14px;color:#444;line-height:1.7;margin:0 0 24px;}'
            + '.section-title{font-size:11px;font-weight:700;color:#888;'
            + '               letter-spacing:.07em;text-transform:uppercase;'
            + '               margin:0 0 10px;}'
            + '.detail-box{background:#f8f9fa;border-radius:6px;'
            + '            padding:16px 20px;margin-bottom:20px;}'
            + '.detail-row{display:flex;justify-content:space-between;'
            + '            padding:7px 0;border-bottom:1px solid #e8e8e8;'
            + '            font-size:13px;}'
            + '.detail-row:last-child{border-bottom:none;}'
            + '.detail-label{color:#666;width:45%;}'
            + '.detail-value{color:#1a1a2e;font-weight:600;width:55%;text-align:right;}'
            + '.desc-box{background:#f0f4f8;border-radius:6px;'
            + '          padding:14px 18px;margin-bottom:20px;'
            + '          font-size:13px;color:#444;line-height:1.6;}'
            + '.resolution-box{background:#e8f5e9;border-left:4px solid #28a745;'
            + '                border-radius:4px;padding:14px 18px;margin-bottom:24px;}'
            + '.resolution-box p{margin:0;font-size:14px;color:#1a3a1a;line-height:1.7;}'
            + '.priority-badge{display:inline-block;font-size:11px;font-weight:600;'
            + '                padding:2px 10px;border-radius:10px;}'
            + '.closing{font-size:14px;color:#444;line-height:1.7;margin:0 0 24px;}'
            + '.footer{background:#f8f9fa;padding:18px 32px;'
            + '        border-top:1px solid #e8e8e8;}'
            + '.footer p{margin:0;font-size:12px;color:#888;line-height:1.7;}'
            + '.footer strong{color:#02323e;}'
            + '</style>'
            + '</head>'
            + '<body>'
            + '<div class="wrapper">'

            // ── Header ───────────────────────────────────────────────
            + '<div class="header">'
            + '  <h1>Complaint Resolved</h1>'
            + '  <p>' + projectName + '</p>'
            + '  <span class="resolved-badge">&#10003;&nbsp;Resolved</span>'
            + '</div>'

            // ── Body ─────────────────────────────────────────────────
            + '<div class="body">'

            + '  <p class="greeting">Dear ' + customerName + ',</p>'
            + '  <p class="intro">'
            + '    We are pleased to inform you that your complaint '
            + '    <strong>' + ticketNo + '</strong> has been successfully '
            + '    resolved. Thank you for your patience and for bringing '
            + '    this to our attention.'
            + '  </p>'

            // ── Complaint details table ───────────────────────────────
            + '  <p class="section-title">Complaint details</p>'
            + '  <div class="detail-box">'

            + '    <div class="detail-row">'
            + '      <span class="detail-label">Ticket number</span>'
            + '      <span class="detail-value">' + ticketNo + '</span>'
            + '    </div>'

            + '    <div class="detail-row">'
            + '      <span class="detail-label">Project</span>'
            + '      <span class="detail-value">' + projectName + '</span>'
            + '    </div>'

            + '    <div class="detail-row">'
            + '      <span class="detail-label">Unit / Flat</span>'
            + '      <span class="detail-value">' + unitDisplay + '</span>'
            + '    </div>'

            + '    <div class="detail-row">'
            + '      <span class="detail-label">Category</span>'
            + '      <span class="detail-value">' + category + '</span>'
            + '    </div>'

            + '    <div class="detail-row">'
            + '      <span class="detail-label">Priority</span>'
            + '      <span class="detail-value">'
            +          getPriorityBadge(priority)
            + '      </span>'
            + '    </div>'

            + '    <div class="detail-row">'
            + '      <span class="detail-label">Raised on</span>'
            + '      <span class="detail-value">' + raisedDate + '</span>'
            + '    </div>'

            + '    <div class="detail-row">'
            + '      <span class="detail-label">Resolved on</span>'
            + '      <span class="detail-value">' + resolvedDate + '</span>'
            + '    </div>'

            + '  </div>'

            // ── Description ───────────────────────────────────────────
            + (String.isNotBlank(description)
                ? '  <p class="section-title">Complaint description</p>'
                + '  <div class="desc-box">' + description + '</div>'
                : '')

            // ── Resolution summary ────────────────────────────────────
            + '  <p class="section-title">Resolution summary</p>'
            + '  <div class="resolution-box">'
            + '    <p>'
            + (String.isNotBlank(resolution)
                ? resolution
                : 'The reported issue has been inspected and resolved by our team.')
            + '    </p>'
            + '  </div>'

            + '  <p class="closing">'
            + '    If you have any further concerns or if the issue reoccurs, '
            + '    please do not hesitate to reach out to your CRM executive. '
            + '    We are committed to ensuring your satisfaction.'
            + '  </p>'

            + '</div>'

            // ── Footer ───────────────────────────────────────────────
            + '<div class="footer">'
            + '  <p>'
            + '    <strong>CRM Team — ' + projectName + '</strong><br/>'
            + ' <strong>Trifecta Projects Pvt Ltd</strong><br/>'
            + '    This is a system-generated email. '
            + '    Please do not reply directly to this email.'
            + '  </p>'
            + '</div>'

            + '</div>'
            + '</body>'
            + '</html>';
    }

    // ── Priority badge helper — no extra query needed ─────────────────
    private static String getPriorityBadge(String priority) {
        String bg    = '#888';
        String color = '#fff';
        if (priority == 'Critical') { bg = '#c23934'; }
        else if (priority == 'High')    { bg = '#e07a00'; }
        else if (priority == 'Medium')  { bg = '#0070d2'; }
        else if (priority == 'Low')     { bg = '#28a745'; }

        return '<span class="priority-badge" style="background:'
             + bg + ';color:' + color + ';">'
             + priority
             + '</span>';
    }
}