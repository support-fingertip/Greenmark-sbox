/****************************************************************
* Class Name   : ReminderdemandInvioceController
* Company      : Fingertipplus
* Created Date : 10-02-2026
* @description : This Apex controller is used to generate Demand
*                Invoice PDF for a Booking. It calculates:
*                - Previous pending dues
*                - Current milestone due
*                - TDS @1% (if > 50 Lakhs)
*                - Interest amount
*                - Amount excluding TDS as per legal format
*                Data is merged to Visualforce for invoice print.
*
* @author      : Durga Prasad
*
* Change Log:
* -----------------------------------------------------------------
* Ver | Author        | Date        | Description
* -----------------------------------------------------------------
* 1.0 | Durga Prasad | 10-02-2026  | Initial version
* -----------------------------------------------------------------
*****************************************************************/
public class ReminderdemandInvioceController {

    /** ===================== WRAPPER FOR HEADER INFO ===================== **/
    public class bookingInfoWrapper {
        public String customerId { get; set; }
        public String reminderType { get; set; }
        public String customerName { get; set; }
        public String unitNo { get; set; }
        public String block { get; set; }
        public String project { get; set; }
        public Date demandDate { get; set; }
        public String projectAddress { get; set; }
        public String email { get; set; }
        public String contactNo { get; set; }
        public String webAddress { get; set; }
        public String companyAddress { get; set; }
        public String companyName { get; set; }
        
        public String bankName { get; set; }
        public String accountNumber { get; set; }
        public String ifscCode { get; set; }
        public String typeOfAccount { get; set; }
        public String branch { get; set; }
        
        public decimal interstPercent { get; set; }
        public decimal tdsPercent { get; set; }
        public decimal amountPercent { get; set; }
    }

    /** ===================== PUBLIC VARIABLES ===================== **/
    public Booking__c booking { get; set; }
    public List<Co_Applicant__c> coapplicants { get; set; }
    public Co_Applicant__c firstCoApplicant { get; set; }
    public bookingInfoWrapper bookingInfo { get; set; }
    public String bookingId {get; set;}

    public String currentCompletedStage { get; set; }
    public Date demandDueDate { get; set; }

    public Decimal balanceInterest {get;set;}
 
    public Decimal balanceDueTillPrevMilestone {get;set;}

    public Decimal presentDue {get;set;}

    public Decimal paidTDS {get;set;}
    public Decimal pendingPreviousTDS {get;set;}
    public Decimal currentPendingTDS {get;set;}

    public Decimal prevDueExcludingTDS {get; set;}
    public Decimal currentDueExcludingTDS {get; set;}

    public Decimal totalAmountPayable {get; set;}
    public String totalAmountFormatted { get; set; }
    
    
    public String prevDueExcludingTDSFormatted { get; set; }
    public String pendingPreviousTDSFormatted { get; set; }
    public String currentDueExcludingTDSFormatted { get; set; }
    public String currentPendingTDSFormatted { get; set; }
    
    public String formattedDueDate { get; set; }
    
    public String balanceInterestFormatted { get; set; }
    public String milestoneAmountInWords {get; set;}
    
    

 	 /**
    * @description Constructor to fetch Booking, Block, Payment Schedule,
    *              calculate previous dues, current dues, TDS, interest
    *              and prepare data for Demand Invoice PDF.
    * @param controller StandardController instance from VF page
    */
    public ReminderdemandInvioceController(ApexPages.StandardController controller) {

        /** ===================== GET BOOKING ID ===================== **/
        Id bookingRecordId = ApexPages.currentPage().getParameters().get('Id');
        Id paymentSchduleId = ApexPages.currentPage().getParameters().get('paymentSchduleId');
        string reminderType = ApexPages.currentPage().getParameters().get('reminderType');
        bookingId = bookingRecordId;
        bookingInfo = new bookingInfoWrapper();
        bookingInfo.reminderType = 'DEMAND NOTE';
        if(reminderType != null && reminderType!= '')
        {
            if(reminderType == 'Demand_1ST_REMINDER')
            {
                bookingInfo.reminderType = 'REMINDER-1';
            }
            else if(reminderType == 'Demand_2ND_REMINDER')
            {
                bookingInfo.reminderType = 'REMINDER-2';
            }
            else if(reminderType == 'Demand_3RD_REMINDER')
            {
                bookingInfo.reminderType = 'REMINDER-3';
            }
            else
            {
                bookingInfo.reminderType = reminderType;
            }
        }
      

        /** ===================== BOOKING QUERY ===================== **/
        booking = [SELECT Id, Name, Total_received_Amount__c, SLead__r.Lead_ID__c, Block_Id__c,Project_Type__c,
                   First_Applicant_Name__c, Unit_No__c, Block_Name__c, Project1__r.Name, Total_Amount__c,Owner_Email__c,
                   Project1__r.Company_Address__c, CRM_Executive_Contact_No__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];

        /** ===================== BLOCK DETAILS ===================== **/
        Block__c block = booking.Block_Id__c != null ? [SELECT Id, Name, Email__c, Project_Address__c,Company_Name__c,Company_Address__c,
                                                        Construction_Company_Name__c,Land_Company_Name__c,Project_Name__c,
                                                        Branch__c, Type_of_Account__c, IFSC_Code__c, Account_Number__c, 
                                                        Constriction_Bank_Name__c,Constriction_Account_Number__c,Constriction_IFSC_Code__c,
                                                        Constriction_Type_of_Account__c,Constriction_Branch__c,
                                                        Bank_Name__c FROM Block__c WHERE Id = :booking.Block_Id__c LIMIT 1] : null;

        /** ===================== MAPPING HEADER INFO ===================== **/
       


        bookingInfo.demandDate = System.today(); 
        bookingInfo.customerId = (booking.SLead__r != null && booking.SLead__r.Lead_ID__c != null) ? booking.SLead__r.Lead_ID__c : '';
        bookingInfo.customerName = booking.First_Applicant_Name__c != null ? booking.First_Applicant_Name__c : '';
        bookingInfo.unitNo = booking.Unit_No__c != null ? booking.Unit_No__c : '';
        bookingInfo.block = booking.Block_Name__c != null ? booking.Block_Name__c : '';
        //bookingInfo.project = (booking.Project1__r != null) ? booking.Project1__r.Name : '';
        bookingInfo.project = (block!= null && block.Project_Name__c != null) ? block.Project_Name__c : '';
        bookingInfo.email = (booking != null && booking.Owner_Email__c != null) ? booking.Owner_Email__c : '';
        bookingInfo.projectAddress = (block != null && block.Project_Address__c != null) ? block.Project_Address__c : '';
        bookingInfo.webAddress = 'www.trifectaprojects.com';
        bookingInfo.contactNo = booking.CRM_Executive_Contact_No__c != null ? booking.CRM_Executive_Contact_No__c : '';

        
        bookingInfo.companyAddress = (block.Company_Address__c != null) 
            ? block.Company_Address__c.replaceAll('(?i),?\\s*Bangalore', '<br/>Bangalore')
            : '';

        /** ===================== CO APPLICANTS ===================== **/
        coapplicants = [SELECT Name, Salutation__c FROM Co_Applicant__c WHERE Booking__c = :bookingId];
        firstCoApplicant = !coapplicants.isEmpty() ? coapplicants[0] : null;

        /** ===================== GET LATEST COMPLETED MILESTONE ===================== **/
        List<Payment_Schedule__c> psRecordList = [SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c,Type__c,Tds__c,Interest_Percent__c,
                                                  Last_Payment_Schedule__c, AmountB__c, Pending_Amount__c, PaymentDueDate__c,Default_Due_Date_in_days__c
                                                  ,Without_Tds_Amount_Percent__c FROM Payment_Schedule__c WHERE Status__c = 'Completed' 
                                                  AND Id = :paymentSchduleId ORDER BY S_No__c DESC];

        if (psRecordList.isEmpty()) {
            currentCompletedStage = '';
            demandDueDate = null;
            totalAmountPayable = 0;
            return;
        }

        Payment_Schedule__c psRecord = psRecordList[0];
        bookingInfo.tdsPercent = psRecord.Tds__c/100;
        bookingInfo.interstPercent = psRecord.Interest_Percent__c;
        bookingInfo.amountPercent =  psRecord.Without_Tds_Amount_Percent__c/100;
        
        currentCompletedStage = psRecord.Name;
        if(psRecord.PaymentDueDate__c != null)
        {
            demandDueDate = psRecord.PaymentDueDate__c;
        }
        else
        {
            demandDueDate = Date.today().addDays((psRecord.Default_Due_Date_in_days__c ?? 0).intValue());
        }
        
        bookingInfo.companyName = 'TRIFECTA PROJECTS PVT LTD';
        if(booking.Project_Type__c == 'Villas')
        {
            if(psRecord.Type__c =='Land')
            {
                bookingInfo.companyName =(block.Land_Company_Name__c != null) ? block.Land_Company_Name__c : '';
                
                
                bookingInfo.bankName = (block != null && block.Bank_Name__c != null) ? block.Bank_Name__c : '';
                bookingInfo.accountNumber = (block != null && block.Account_Number__c != null) ? block.Account_Number__c : '';
                bookingInfo.ifscCode = (block != null && block.IFSC_Code__c != null) ? block.IFSC_Code__c : '';
                bookingInfo.typeOfAccount = (block != null && block.Type_of_Account__c != null) ? block.Type_of_Account__c : '';
                bookingInfo.branch = (block != null && block.Branch__c != null) ? block.Branch__c : '';
                
                
                
            }
            else if(psRecord.Type__c =='Construction')
            {
                bookingInfo.companyName =(block.Construction_Company_Name__c != null) ? block.Construction_Company_Name__c: '';
                
                
                bookingInfo.bankName = (block != null && block.Constriction_Bank_Name__c != null) ? block.Constriction_Bank_Name__c : '';
                bookingInfo.accountNumber = (block != null && block.Constriction_Account_Number__c != null) ? block.Constriction_Account_Number__c : '';
                bookingInfo.ifscCode = (block != null && block.Constriction_IFSC_Code__c != null) ? block.Constriction_IFSC_Code__c : '';
                bookingInfo.typeOfAccount = (block != null && block.Constriction_Type_of_Account__c != null) ? block.Constriction_Type_of_Account__c : '';
                bookingInfo.branch = (block != null && block.Constriction_Branch__c != null) ? block.Constriction_Branch__c : '';
                
                
            }
        }
        else
        {
            bookingInfo.companyName =(block.Company_Name__c != null ) ? block.Company_Name__c : '';
            
                            
            bookingInfo.bankName = (block != null && block.Bank_Name__c != null) ? block.Bank_Name__c : '';
            bookingInfo.accountNumber = (block != null && block.Account_Number__c != null) ? block.Account_Number__c : '';
            bookingInfo.ifscCode = (block != null && block.IFSC_Code__c != null) ? block.IFSC_Code__c : '';
            bookingInfo.typeOfAccount = (block != null && block.Type_of_Account__c != null) ? block.Type_of_Account__c : '';
            bookingInfo.branch = (block != null && block.Branch__c != null) ? block.Branch__c : '';
            
            
        }
        
        /** ===================== PREVIOUS DUES ===================== **/
        AggregateResult[] prevAgg = [SELECT SUM(Pending_Amount__c) totalPendingAmount, SUM(Interest_Up_to_Date__c)
                                     totalInterestUplodate, SUM(Interest_Paid__c) totalInterestPaid,
                                     SUM(Total_TDS_Amount__c) tdsAmount
                                     FROM Payment_Schedule__c WHERE Status__c = 'Completed'
                                     AND S_No__c < :psRecord.S_No__c AND Booking__c = :booking.Id];

        Decimal totalPendingAmount = !prevAgg.isEmpty() ? (Decimal)prevAgg[0].get('totalPendingAmount') ?? 0 : 0;
        Decimal totalInterestUplodateAmount = !prevAgg.isEmpty() ? (Decimal)prevAgg[0].get('totalInterestUplodate') ?? 0 : 0;
        Decimal totalInterestPaid = !prevAgg.isEmpty() ? (Decimal)prevAgg[0].get('totalInterestPaid') ?? 0 : 0;
        Decimal previousTDS = !prevAgg.isEmpty() ? (Decimal)prevAgg[0].get('tdsAmount') ?? 0 : 0; 
        balanceDueTillPrevMilestone = totalPendingAmount;
       

        /** ===================== CURRENT MILESTONE DUE ===================== **/
        AggregateResult currentDue = [SELECT SUM(Pending_Amount__c) totalAmountB, SUM(Interest_Up_to_Date__c) totalInterestUplodate,  
                                      SUM(Total_TDS_Amount__c) tdsAmount FROM Payment_Schedule__c 
                                      WHERE S_No__c = :psRecord.S_No__c AND Booking__c = :booking.Id];
        presentDue = (Decimal)currentDue.get('totalAmountB') ?? 0;
        Decimal currentTds = (Decimal)currentDue.get('tdsAmount') ?? 0;
        Decimal currentDueInterest = (Decimal)currentDue.get('totalInterestUplodate') ?? 0;
        
        balanceInterest = (currentDueInterest + totalInterestUplodateAmount) - totalInterestPaid;
        /** ===================== PAID TDS ===================== **/
        AggregateResult paidTDSAgg = [SELECT SUM(Amount__c) amt FROM Receipt_Line_Item__c WHERE Payment_Type__c = 'TDS Challan Entry'
                                      AND Booking__c = :booking.Id];

        paidTDS = (Decimal)paidTDSAgg.get('amt') ?? 0;

        pendingPreviousTDS = previousTDS - paidTDS;
        pendingPreviousTDS = pendingPreviousTDS < 0 ? 0 : pendingPreviousTDS;

        Decimal remaingTdPaidAmount = paidTDS - previousTDS;

        currentPendingTDS = currentTds;
        currentPendingTDS = remaingTdPaidAmount > 0 ? currentTds - remaingTdPaidAmount : currentPendingTDS;
        currentPendingTDS = currentPendingTDS < 0 ? 0 : currentPendingTDS;

        /** ===================== EXCLUDING TDS ===================== **/
        prevDueExcludingTDS = balanceDueTillPrevMilestone - pendingPreviousTDS;
        currentDueExcludingTDS = presentDue - currentTds;
        currentDueExcludingTDS = currentDueExcludingTDS < 0 ? 0 : currentDueExcludingTDS;

        /** ===================== FINAL TOTAL ===================== **/
        totalAmountPayable = prevDueExcludingTDS + pendingPreviousTDS + currentDueExcludingTDS + currentPendingTDS + balanceInterest;
        
        
        totalAmountFormatted = totalAmountPayable != null
            ? totalAmountPayable.setScale(2).format()
            : '0.00';
        
        prevDueExcludingTDSFormatted = prevDueExcludingTDS != null
            ? prevDueExcludingTDS.setScale(2).format()
            : '0.00';
        
        pendingPreviousTDSFormatted = pendingPreviousTDS != null
            ? pendingPreviousTDS.setScale(2).format()
            : '0.00';
        
        currentDueExcludingTDSFormatted = currentDueExcludingTDS != null
            ? currentDueExcludingTDS.setScale(2).format()
            : '0.00';
        
        currentPendingTDSFormatted = currentPendingTDS != null
            ? currentPendingTDS.setScale(2).format()
            : '0.00';
        
        
        balanceInterestFormatted = balanceInterest != null
            ? balanceInterest.setScale(2).format()
            : '0.00'; 
        
         formattedDueDate = '';
        
        if (demandDueDate != null) {
            List<String> months = new List<String>{
                'January','February','March','April','May','June',
                    'July','August','September','October','November','December'
                    };
                        
                        formattedDueDate = demandDueDate.day() + ' ' + months[demandDueDate.month() - 1] + ' ' + demandDueDate.year();
        }
        
        NumberTOWordConvertion convert = new NumberTOWordConvertion();
        if (totalAmountPayable != null && totalAmountPayable > -1) {
            milestoneAmountInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
        }
        
        
    }
}