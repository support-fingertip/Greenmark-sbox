public class BookingPDFController {
    public Booking__c booking { get; set; }
    public list<Payment_schedule__c> paymentSchdules { get; set; }
    public list<Payment_schedule__c> landpaymentSchdules { get; set; }
    public list<Payment_schedule__c> constructionpaymentSchdules { get; set; }
    public List<String> textLines { get; set; }
    public list<Receipt_Line_Item__c> receiptLineItems { get; set; }
    public list<Receipt_Line_Item__c> landreceiptLineItems { get; set; }
    public list<Receipt_Line_Item__c> constructionreceiptLineItems { get; set; }
    public String projectHead { get; set; }
    
    public List<CoApplicantWrapper> coApplicantList { get; set; }
    
    public class CoApplicantWrapper {
        public Integer index { get; set; }
        public Co_Applicant__c coApp { get; set; }
        
        public CoApplicantWrapper(Integer i, Co_Applicant__c c) {
            this.index = i;
            this.coApp = c;
        }
    }
    
    
    public BookingPDFController(ApexPages.StandardController controller) {
        Id bookingId =controller.getId();
        booking = [SELECT Id, Notes_and_Comments__c, Plot__r.Name, Plot__r.Block_Lookup__r.Name,BHK_Type__c,
                   Super_Built_UpArea__c,Unit_Number__c,Type_of_Aggrement__c, First_Applicant_Name__c,Age__c,
                   Son_Daughter_Wife_of1__c,Occupation__c,Mobile__c,Email1__c, PAN_Number__c,Address__c,Pincode1__c,
                   Permanent_Address1__c,Pincode__c,Rate_per_sqft__c,Basic_Cost__c,Quote__c,Email__c,
                   Bescom_STP_and_Generator_per_Sq_ft__c,Bescom_STP_and_Generator_Changes__c,
                   Car_Parking_Amount__c,Legal_Charge__c,Amenity_Charges__c,GST_Amount__c,Total_Amount__c,Plot_Land_Area__c,
                   Project_Brand_Name__c,
                   Total_Land_Amount__c,Extra_Land_Amount__c,Construction_Cost__c
                   FROM Booking__c WHERE Id = :bookingId];
        
        list<Payment_schedule__c> paymentSchdulesList = [select id ,Name,Payment_percent__c,S_No__c,Type__c,AmountB__c
                                                     from Payment_schedule__c where Quote__c =:booking.Quote__c  order by S_No__c asc];
        projectHead = booking.Project_Brand_Name__c;
        if(!paymentSchdulesList.isEmpty())
        {
            paymentSchdules = paymentSchdulesList;
            list<Payment_schedule__c> landpaymentschdulesList = new  list<Payment_schedule__c>();
            list<Payment_schedule__c> constructionpaymentschdulesList = new  list<Payment_schedule__c>();
            for(Payment_schedule__c pay : paymentSchdulesList)
            {
                if(pay.Type__c == 'Land')
                {
                    landpaymentschdulesList.add(pay);
                }
                else if(pay.Type__c == 'Construction')
                {
                    constructionpaymentschdulesList.add(pay);
                }
            }
            landpaymentSchdules = landpaymentschdulesList;
            constructionpaymentSchdules = constructionpaymentschdulesList;

        }
               
        
        system.debug(booking);
        
        if(booking.Notes_and_Comments__c != Null) {
            textLines = booking.Notes_and_Comments__c.split('\r\n');
        } else {
            textLines = new List<String>();
        }
      
        
        
        List<Co_Applicant__c> coApplicants = [
            select id,Name,Age__c,Son_Daughter_Wife_of__c,Occupation__c,
            Primary_Phone__c,Email__c,PAN_Number__c from Co_Applicant__c where Booking__c =:bookingId 
        ];
         
        List<Receipt_Line_Item__c> receiptLineItemsList = [select Id,Cheque_no_Transaction_Number__c,Bank_Name__c,	
                                                           Received_Amount__c,Receipt_Date__c,Type__c,
                                                           Mode_of_Payment__c,Payment_Type__c
                                                           from Receipt_Line_Item__c where 	Booking__c =:bookingId ];
        if(!receiptLineItemsList.isEmpty())
        {
            List<Receipt_Line_Item__c> constructionreceiptLineItemsList = new List<Receipt_Line_Item__c>();
            List<Receipt_Line_Item__c> landreceiptLineItemsList = new List<Receipt_Line_Item__c>();
            receiptLineItems = receiptLineItemsList;
            for(Receipt_Line_Item__c rec: receiptLineItemsList )
            {
                if(rec.Type__c == 'Land')
                {
                    landreceiptLineItemsList.add(rec);
                }
                else if(rec.Type__c == 'Construction')
                {
                    constructionreceiptLineItemsList.add(rec);
                }
            }
            landreceiptLineItems = landreceiptLineItemsList;
            constructionreceiptLineItems = constructionreceiptLineItemsList;
            
        }

        if (!coApplicants.isEmpty()) {
            List<CoApplicantWrapper> wrappedList = new List<CoApplicantWrapper>();
            Integer i = 0;
            
            for (Co_Applicant__c c : coApplicants) {
                wrappedList.add(new CoApplicantWrapper(i, c));
                i++;
            }
            
            coApplicantList = wrappedList;
    
        }
    }
    @AuraEnabled
    public static string sendEmailtoCustomer(String recId,String projectType)
    {
        Booking__c bk = [SELECT Id, Project__c,Email__c  FROM Booking__c WHERE Id=:recId];
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        
        
        PageReference pref;
       
   
        
        String pdfName;
        String emailSubject;
        
        if (projectType == 'Apartments') {
            pref=page.Trifecta_Booking_Form;
            pdfName = bk.Project__c + '_BookingForm.pdf';
            emailSubject = 'Booking for ' + bk.Project__c + ' – Your Dream Home Awaits!';
            bk.Approval_status__c = 'Submitted for Approval';
        } 
        if (projectType == 'Row House') {
            pref=page.TrifectaRowHouseBookingForm;
            pdfName = bk.Project__c + '_BookingForm.pdf';
            emailSubject = 'Row House Booking for ' + bk.Project__c + ' – Your Dream Home Awaits!';
            bk.Approval_status__c = 'Submitted for Approval';
        } 
        else if (projectType == 'Land') {
            pref=page.LandVillaBookingForm;
            pdfName = bk.Project__c + '_Land_BookingForm.pdf';
            emailSubject = 'Villa Plot Booking for ' + bk.Project__c + ' – Your Perfect Plot Awaits!';
            bk.Land_Approval_Status__c = 'Submitted for Approval';
        } 
        else if (projectType == 'Construction') {
            pref=page.ConstructionVillaBookingForm;
            pdfName = bk.Project__c + '_Construction_BookingForm.pdf';
            emailSubject = 'Villa Construction Booking for ' + bk.Project__c + ' – Let’s Build Your Dream Home!';
            bk.Construction_Approval_Status__c = 'Submitted for Approval';
        } 
        update bk;
        
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
        
        semail.setSubject(emailSubject);
        attach.setFileName(pdfName);
        attach.setBody(b);
        List<string> sendTo = new List<string>();
        if(bk.Email__c !=null){
            sendTo.add(bk.Email__c);
        }
        
        string displayName = label.Default_Email_Address_Label;
        // Set sender using Org-Wide Email Address (Name = "System Admin Email")
        OrgWideEmailAddress owea = [
            SELECT Id 
            FROM OrgWideEmailAddress 
            WHERE DisplayName =:displayName 
            LIMIT 1
        ];
        semail.setOrgWideEmailAddressId(owea.Id);
        
        
        semail.setToAddresses(sendTo);
        system.debug(sendTo);
        semail.setToAddresses(sendTo);
        string urlval = label.Org_url;
        Site mySite = [
            SELECT Id, Name, Subdomain, UrlPathPrefix 
            FROM Site 
            WHERE Name = 'Customer_Booking_Form' 
            LIMIT 1
        ];
        
        String bookingUrl = urlval + '/' + mySite.UrlPathPrefix + '?id=' + bk.Id + '&type=' + projectType;
        
        
        semail.setHtmlBody(
            'Dear Sir/Madam,<br/><br/>' +
            'Thank you very much for your interest in <b>' + bk.Project__c + '</b>.<br/><br/>' +
            'Please find the attached booking form for your reference.<br/><br/>' +
            //'To continue, please ' +
            //'<a href="' + bookingUrl + '">click here to proceed with your booking</a>.<br/><br/>' +
            'We appreciate your trust in Trifecta Projects and look forward to welcoming you.<br/><br/>' +
            'Warm Regards,<br/>' +
            '<b>Team Trifecta</b><br/>' +
            ' <a href="https://www.trifectaprojects.com">www.trifectaprojects.com</a>'
        );
        
        semail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});
        system.debug(semail);
        if(sendTo.size()>0){
            try{
               // if (!Test.isRunningTest()) {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail});
                bk.Booking_Form_Sent__c = true;
                update bk;
               // }
                system.debug(semail);
                
            }
            
            catch(Exception e){
                System.debug('Error sending email: ' + e.getMessage());
            }
            
            return 'Booking form sent to customer';    
            
        }else{
            return 'Please enter email address';
        }
        
    }
    
    
    
    
}