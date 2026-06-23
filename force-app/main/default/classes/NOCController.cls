public with sharing class NOCController {
    public Booking__c booking { get; private set; }
    public List<Co_Applicant__c> coapplicants { get; set; }
    public Co_Applicant__c firstCoApplicant { get; set; }
    public bookingInfoWrapper bookingInfo { get; set; }
    public String amountInWords { get; set; }
    public decimal amount{ get; set; }
    
    public String registrationDateLong { get; set; }
    
    public list<Receipt_Line_Item__c> landreceiptLineItems { get; set; }
    public class bookingInfoWrapper {
        public String customerId { get; set; }
        public String customerName { get; set; }
        public String unitNo { get; set; }
        public String block { get; set; }
        public String project { get; set; }
        public String projectAddress { get; set; }
        public String currentYear { get; set; }
    }
    
    public NOCController(ApexPages.StandardController stdController) {
        Id bookingId = stdController.getId();
        
        if (bookingId == null) {
            booking = new Booking__c();
            return;
        }
        
        booking = [
            SELECT Id,First_Applicant_Name__c,Unit_No__c,Block_Name__c,Project1__r.Name ,Block_Id__c,S__c,Registration_Date__c,Project_Block_Name__c
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];
        if (booking.Registration_Date__c != null) {
            
            // If Registration_Date__c is DateTime in your org, use .date()
            Date d = ((DateTime) booking.Registration_Date__c).date();
            
            Integer day = d.day();
            String suffix;
            if (day >= 11 && day <= 13) suffix = 'th';
            else if (Math.mod(day, 10) == 1) suffix = 'st';
            else if (Math.mod(day, 10) == 2) suffix = 'nd';
            else if (Math.mod(day, 10) == 3) suffix = 'rd';
            else suffix = 'th';
            
            // Month name without using Date.format()
            // (avoids the Date/DateTime format confusion and locale surprises)
            List<String> months = new List<String>{
                'January','February','March','April','May','June',
                    'July','August','September','October','November','December'
                    };
                        String monthName = months[d.month() - 1];
            
            registrationDateLong = day + suffix + ' day of ' + monthName + ' ' + d.year();
        } else {
            registrationDateLong = '';
        }
        //Block 
        Block__c block = [select Id,Name,Email__c,Project_Address__c,Construction_Company_Name__c,Land_Company_Name__c,
                          Company_Name__c,Company_Address__c from Block__c where Id =: booking.Block_Id__c];
        
        bookingInfo = new bookingInfoWrapper();
        bookingInfo.customerName = booking.First_Applicant_Name__c != null ? booking.First_Applicant_Name__c : '';
        bookingInfo.unitNo = booking.Unit_No__c != null ? booking.Unit_No__c : '';
        bookingInfo.block = booking.Block_Name__c != null ? booking.Block_Name__c : '';
        bookingInfo.project = (booking.Project1__r != null) ? booking.Project1__r.Name : '';
        bookingInfo.projectAddress = (block != null && block.Project_Address__c != null) ? block.Project_Address__c : '';
        bookingInfo.currentYear = String.valueOf(Date.today().year());
        
        coapplicants = [SELECT Name, Salutation__c FROM Co_Applicant__c WHERE Booking__c = :bookingId];
        firstCoApplicant = !coapplicants.isEmpty() ? coapplicants[0] : null;
        
        
        List<Receipt_Line_Item__c> receiptLineItemsList = [select Id,Cheque_no_Transaction_Number__c,Bank_Name__c,	
                                                           Received_Amount__c,Receipt_Date__c,Type__c,
                                                           Mode_of_Payment__c,Payment_Type__c
                                                           from Receipt_Line_Item__c where 	Booking__c =:bookingId ];
        
        if(!receiptLineItemsList.isEmpty())
        {
            List<Receipt_Line_Item__c> landreceiptLineItemsList = new List<Receipt_Line_Item__c>();
            decimal totalReceivedAmount = 0;
            for(Receipt_Line_Item__c rec: receiptLineItemsList )
            {
                if(rec.Type__c == 'Land')
                {
                    landreceiptLineItemsList.add(rec);
                    if (rec.Received_Amount__c != null) {
                        totalReceivedAmount += rec.Received_Amount__c;
                    }
                }
            }
            NumberTOWordConvertion conversion = new NumberTOWordConvertion();
            amountInWords = totalReceivedAmount != null ?conversion.getNumberTOWordConvertion(totalReceivedAmount) : null;
            amount = totalReceivedAmount;
            landreceiptLineItems = landreceiptLineItemsList;
            
        }
        
        
    }
    
}