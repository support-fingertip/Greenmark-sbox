public without sharing class QuotePdfController {
    @AuraEnabled
    public static string sendEmailtoCustomer(String recId)
    {
        Quote__c qt = [SELECT Id,payment_type__c,Quote_status__c,
                       Approval_status__c, Project__c, SLead__r.Email,
                       SLead__r.Secondary_Email__c,Plot_Type__c,SLead__c
                       ,RecordType.DeveloperName  FROM Quote__c WHERE Id=:recId];
        
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        
        
        String pdfName;
        String emailSubject;
        
        PageReference pref;
        if(qt.RecordType.DeveloperName=='Apartments'){
            pref= page.TrifectaCostsheet;
            pdfName = qt.Project__c + '_CostSheet.pdf';
            emailSubject = 'Cost Sheet for ' + qt.Project__c + ' – Your Dream Home Awaits!';
        }
        else if(qt.RecordType.DeveloperName=='Row_House')
        {
            pref= page.TrifectaRowHouseCostSheet;
            pdfName = qt.Project__c + '_CostSheet.pdf';
            emailSubject = 'Row House Cost Sheet for ' + qt.Project__c + ' – Your Dream Home Awaits!';
        }
        else{
            pref= page.trifectaVillaCostSheet;
            pdfName = qt.Project__c + '_CostSheet.pdf';
            emailSubject = 'Villa Cost Sheet for ' + qt.Project__c + ' – Your Dream Home Awaits!';
        }
        
        pref.getParameters().put('id',recId);
        pref.setRedirect(true);
        system.debug(pref);
        Blob b;
        
        Boolean isTest = System.Test.isRunningTest();
        if(isTest){
            b = blob.valueOf('Unit.Test');
        }else{
            b = pref.getContent();
        }
        attach.setFileName(pdfName);
        attach.setBody(b);
        semail.setSubject(emailSubject);
        system.debug(qt.SLead__r.Email);
        List<string> sendTo = new List<string>();
        if(qt.SLead__r.Email !=null){
            sendTo.add(qt.SLead__r.Email);
        }
        
        if(qt.SLead__r.Secondary_Email__c !=null){
            sendTo.add(qt.SLead__r.Secondary_Email__c);
        }
        string displayName = label.Default_Email_Address_Label;
        // Set sender using Org-Wide Email Address (Name = "System Admin Email")
        OrgWideEmailAddress owea = [
            SELECT Id 
            FROM OrgWideEmailAddress 
            WHERE DisplayName =: displayName // or use Address = 'admin@yourdomain.com'
            LIMIT 1
        ];
        semail.setOrgWideEmailAddressId(owea.Id);
        
        
        semail.setToAddresses(sendTo);
        semail.setHtmlBody(
            'Dear Sir/Madam,<br/><br/>' +
            'Thank you very much for your interest in <b>' + qt.Project__c + '</b>.<br/><br/>' +
            'Please find the attached Cost sheet  for your reference.<br/><br/>' +
            'We appreciate your trust in Trifecta Projects and look forward to welcoming you.<br/><br/>' +
            'Warm Regards,<br/>' +
            '<b>Team Trifecta</b><br/>' +
            '🌐 <a href="https://www.trifectaprojects.com">www.trifectaprojects.com</a>'
        );
        
        
        
        semail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});
        if(sendTo.size()>0){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail});
            system.debug(semail);
            
            Quote__c q = [select Id, Name, Quote_status__c from Quote__c where id = :recId limit 1];
            q.Quote_status__c = 'sent to customer';
            update q;
            return 'Quotation sent to customer';
        }else{
            return 'Please enter email address in lead';
        }
    }
}