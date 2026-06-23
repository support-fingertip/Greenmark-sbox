public without sharing class TrifectaCustomerBookingFormController {
    
    
    public class dataBox{
        @AuraEnabled 
        public Booking__c bookingRec {get; set;}
        @AuraEnabled 
        public boolean isResponded {get; set;}
        @AuraEnabled 
        public List<Co_Applicant__c> coApplicants {get; set;}
        @AuraEnabled 
        public list<Receipt_Line_Item__c> receiptLineItems { get; set; }
        @AuraEnabled 
        public list<Payment_schedule__c> paymentSchdules { get; set; }
    }
    
    @AuraEnabled
    public static dataBox getBookingData(string recordId,String projectType){
        dataBox dt = new dataBox();
        system.debug('recordId'+recordId);
        List<Booking__c> bookingList = [select Id,Name,Plot__c,Project_Type__c,Super_Built_UpArea__c,Email__c,
                                        Project1__r.Name,Project1__c,Plot__r.Name,BHK_Type__c,Plot__r.Floor__c,Unit_Number__c,	Rate_per_sqft__c,
                                        
                                        Additional_Car_Parking_Charges__c,Construction_Cost__c,Total_Land_Amount__c,Plot_Land_Area__c,
                                        Sub_Total__c,GST_Percentage__c,GST_Amount__c,Total_Amount__c,
                                        First_Applicant_Name__c,Occupation__c,Son_Daughter_Wife_of1__c, Email1__c,Mobile__c,PAN_Number__c,
                                        Address__c,Permanent_Address1__c,Pincode__c,Pincode1__c,Type_of_Aggrement__c,
										Basic_Cost__c,Bescom_STP_and_Generator_Changes__c,Car_Parking__c,Legal_Charges__c,Amenities__c,
                                        Approval_status__c,Land_Approval_Status__c,Construction_Approval_Status__c
                                        
                                        from Booking__c where Id =:recordId ];
        
        if(!bookingList.isEmpty())
        {
            Booking__C bk =  bookingList[0];
            dt.bookingRec =bk;
            dt.isResponded = false;
            if(projectType == 'Apartments' && (bk.Approval_status__c == 'Approved' || bk.Approval_status__c == 'Rejected'))
            {
                dt.isResponded = true;
            }
            if(projectType == 'Row House' && (bk.Approval_status__c == 'Approved' || bk.Approval_status__c == 'Rejected'))
            {
                dt.isResponded = true;
            }
            else if(projectType == 'Land' && (bk.Land_Approval_Status__c == 'Approved' || bk.Land_Approval_Status__c == 'Rejected'))
            {
                dt.isResponded = true;
            }
            else if(projectType == 'Construction' && (bk.Construction_Approval_Status__c == 'Approved' || bk.Construction_Approval_Status__c == 'Rejected'))
            {
                dt.isResponded = true;
            }
            
            dt.coApplicants = [
                select id,Name,Age__c,Son_Daughter_Wife_of__c,Occupation__c,
                Primary_Phone__c,Email__c,PAN_Number__c from Co_Applicant__c where Booking__c =:bk.Id 
            ];
            
            List<Receipt_Line_Item__c> receiptLineItemsList = [
                SELECT Id, Cheque_no_Transaction_Number__c, Bank_Name__c,
                Received_Amount__c, Receipt_Date__c, Type__c,
                Mode_of_Payment__c, Payment_Type__c
                FROM Receipt_Line_Item__c
                WHERE Booking__c = :bk.Id
            ];
            
            if (!receiptLineItemsList.isEmpty()) {
                // For 'Appartments', assign directly
                if (projectType == 'Appartments') {
                    dt.receiptLineItems = receiptLineItemsList;
                } 
                else {
                    // Filter only matching Type__c in a single pass
                    dt.receiptLineItems = new List<Receipt_Line_Item__c>();
                    
                    for (Receipt_Line_Item__c rec : receiptLineItemsList) {
                        if (rec.Type__c == projectType) {
                            dt.receiptLineItems.add(rec);
                        }
                    }
                }
            }   
            
            
            
            list<Payment_schedule__c> paymentSchdulesList = [select id ,Name,Payment_percent__c,Amount1__c,S_No__c,Type__c
                                                             from Payment_schedule__c where Booking__c =:bk.Id  order by S_No__c asc];
            
            if(!paymentSchdulesList.isEmpty())
            {
                
                // For 'Appartments', assign directly
                if (projectType == 'Apartments') {
                    dt.paymentSchdules = paymentSchdulesList;
                } 
                else if(projectType == 'Row House')
                {
                    dt.paymentSchdules = paymentSchdulesList;
                }
                else {
                    // Filter only matching Type__c in a single pass
                    dt.paymentSchdules = new List<Payment_schedule__c>();
                    
                    for (Payment_schedule__c pay : paymentSchdulesList) {
                        if (pay.Type__c == projectType) {
                            dt.paymentSchdules.add(pay);
                        }
                    }
                }
            }
        }
  
        return  dt;
    }
    @AuraEnabled
    public static void updateBooking(string recordId,String comments,String appovalStatus, String projectType)
    {
        Booking__c bk = new Booking__c();
        bk.Id = recordId;
        if (projectType == 'Apartments') {
            bk.Approval_status__c =appovalStatus;
        } 
        if (projectType == 'Row House') {
            bk.Approval_status__c =appovalStatus;
        } 
        if (projectType == 'Land') {
            bk.Land_Approval_Status__c = appovalStatus;
        } 
        if (projectType == 'Construction') {
            bk.Construction_Approval_Status__c = appovalStatus;
        } 
        bk.Customer_Approval_Comments__c = comments;
        update bk;
    }
    
}