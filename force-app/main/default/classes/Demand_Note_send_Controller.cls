/****************************************************************
* Class Name   : Demand_Note_send_Controller
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
* 1.0 | Durga Prasad | 12-02-2026  | Initial version
* -----------------------------------------------------------------
*****************************************************************/
public class Demand_Note_send_Controller {
    /** ===================== WRAPPER FOR HEADER INFO ===================== **/
    public class bookingInfoWrapper {
        public String customerId { get; set; }
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
        
        public String bankName { get; set; }
        public String accountNumber { get; set; }
        public String ifscCode { get; set; }
        public String typeOfAccount { get; set; }
        public String branch { get; set; }
        public Date demandDueDate { get; set; }
        
        public String formattedDueDate { get; set; }
        
        public decimal interstPercent { get; set; }
        public decimal tdsPercent { get; set; }
        public decimal amountPercent { get; set; }
        public String companyName { get; set; }
    }
    
    /** ===================== PUBLIC VARIABLES ===================== **/
    public Booking__c booking { get; set; }
    public List<Co_Applicant__c> coapplicants { get; set; }
    public Co_Applicant__c firstCoApplicant { get; set; }
    public bookingInfoWrapper bookingInfo { get; set; }
    public String bookingId {get; set;}
    
    public String currentCompletedStage { get; set; }
    public List<String> pendingMilestoneNames { get; set; }
    public Date demandDueDate { get; set; }
    
    public Decimal balanceInterest {get;set;}
    public Decimal balanceDueTillPrevMilestone {get;set;}
    
    public Decimal presentDue {get;set;}
    
    public Decimal paidTDS {get;set;}
    public Decimal pendingPreviousTDS {get;set;}
    public Decimal currentPendingTDS {get;set;}
    
    public Decimal prevDueExcludingTDS {get; set;}
    public Decimal currentDueExcludingTDS {get; set;}
    
    public String totalAmountFormatted { get; set; }
    public String prevDueExcludingTDSFormatted { get; set; }
    public String pendingPreviousTDSFormatted { get; set; }
    public String currentDueExcludingTDSFormatted { get; set; }
    public String currentPendingTDSFormatted { get; set; }
    
    public String formattedDueDate { get; set; }
    public String balanceInterestFormatted { get; set; }
    public Decimal totalAmountPayable {get; set;}
    public String milestoneAmountInWords {get; set;}
    

    
    public Demand_Note_send_Controller(ApexPages.StandardController controller) {
        String demandId = ApexPages.currentPage().getParameters().get('id');
        List<Demand_Raised__c> dmList = [
            SELECT Id,Booking__c,Demanded_Date__c,Due_Date__c,Pending_Dues_excluding_TDS__c,Payment_schedule__c,Payment_schedule__r.Interest_Percent__c,
            Payment_schedule__r.Without_Tds_Amount_Percent__c,Payment_schedule__r.S_No__c,Payment_schedule__r.Name,
            Payment_schedule__r.Tds__c,Pending_Payment_TDS_1__c,Current_Milestone_Excluding_the_TDS__c,Current_Milestone_TDS_1__c,
            Grand_Total_in_Words__c,Grand_Total__c,Interest_Till_Now__c,Demand_Name__c,Payment_schedule__r.Type__c
            FROM Demand_Raised__c
            WHERE Id = :demandId
            LIMIT 1
        ];
        
        System.debug('dmList: ' + dmList);
        
        Demand_Raised__c demand = dmList[0];
        
        String bookingId = demand.Booking__c;
        /** ===================== BOOKING QUERY ===================== **/
        booking = [SELECT Id, Name, Total_received_Amount__c, SLead__r.Lead_ID__c, Block_Id__c,Owner_Email__c,
                   First_Applicant_Name__c, Unit_No__c, Block_Name__c, Project1__r.Name, Total_Amount__c,Project_Type__c,
                   Project1__r.Company_Address__c, CRM_Executive_Contact_No__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        
        /** ===================== BLOCK DETAILS ===================== **/
        Block__c block = booking.Block_Id__c != null ? [SELECT Id, Name, Email__c, Project_Address__c,Project_Name__c,Company_Address__c,
                                                        Land_Company_Name__c,Construction_Company_Name__c,Company_Name__c,
                                                        Branch__c, Type_of_Account__c, IFSC_Code__c, Account_Number__c, 
                                                        Bank_Name__c FROM Block__c WHERE Id = :booking.Block_Id__c LIMIT 1] : null;
        
        /** ===================== MAPPING HEADER INFO ===================== **/
        bookingInfo = new bookingInfoWrapper();
        
        bookingInfo.bankName = (block != null && block.Bank_Name__c != null) ? block.Bank_Name__c : '';
        bookingInfo.accountNumber = (block != null && block.Account_Number__c != null) ? block.Account_Number__c : '';
        bookingInfo.ifscCode = (block != null && block.IFSC_Code__c != null) ? block.IFSC_Code__c : '';
        bookingInfo.typeOfAccount = (block != null && block.Type_of_Account__c != null) ? block.Type_of_Account__c : '';
        bookingInfo.branch = (block != null && block.Branch__c != null) ? block.Branch__c : '';
        
        bookingInfo.demandDate = demand.Demanded_Date__c.date();
        bookingInfo.tdsPercent = demand!= null && demand.Payment_schedule__r != null ? demand.Payment_schedule__r.Tds__c/100 : 0;
        bookingInfo.interstPercent = demand!= null && demand.Payment_schedule__r != null ? demand.Payment_schedule__r.Interest_Percent__c : 0;
        bookingInfo.amountPercent =  demand!= null && demand.Payment_schedule__r != null ?  demand.Payment_schedule__r.Without_Tds_Amount_Percent__c/100 : 0;
        bookingInfo.customerId = (booking.SLead__r != null && booking.SLead__r.Lead_ID__c != null) ? booking.SLead__r.Lead_ID__c : '';
        bookingInfo.customerName = booking.First_Applicant_Name__c != null ? booking.First_Applicant_Name__c : '';
        bookingInfo.unitNo = booking.Unit_No__c != null ? booking.Unit_No__c : '';
        bookingInfo.block = booking.Block_Name__c != null ? booking.Block_Name__c : '';
        bookingInfo.project = (block!= null && block.Project_Name__c != null) ? block.Project_Name__c : '';
        bookingInfo.email = (booking != null && booking.Owner_Email__c != null) ? booking.Owner_Email__c : '';
        bookingInfo.projectAddress = (block != null && block.Project_Address__c != null) ? block.Project_Address__c : '';
        bookingInfo.webAddress = 'www.trifectaprojects.com';
        bookingInfo.contactNo = booking.CRM_Executive_Contact_No__c != null ? booking.CRM_Executive_Contact_No__c : '';
        bookingInfo.companyAddress = (block.Company_Address__c != null) 
            ? block.Company_Address__c.replaceAll('(?i),?\\s*Bangalore', '<br/>Bangalore')
            : '';
        
        bookingInfo.companyName = 'TRIFECTA PROJECTS PVT LTD';
        if(booking.Project_Type__c == 'Villas')
        {
            if(demand.Payment_schedule__r.Type__c =='Land')
            {
                bookingInfo.companyName =(block.Land_Company_Name__c != null) ? block.Land_Company_Name__c : '';
            }
            else if(demand.Payment_schedule__r.Type__c =='Construction')
            {
                bookingInfo.companyName =(block.Construction_Company_Name__c != null) ? block.Construction_Company_Name__c: '';
            }
        }
        else
        {
            bookingInfo.companyName =(block.Company_Name__c != null ) ? block.Company_Name__c : '';
        }
        
        /** ===================== CO APPLICANTS ===================== **/
        coapplicants = [SELECT Name, Salutation__c FROM Co_Applicant__c WHERE Booking__c = :bookingId];
        firstCoApplicant = !coapplicants.isEmpty() ? coapplicants[0] : null;
        
        currentCompletedStage = demand.Demand_Name__c;

        // List prior completed milestones whose demand was never raised, plus the current one,
        // in ascending S_No__c order. Schedules with Is_Demanded__c = true are skipped unless
        // they are the current demand's own schedule.
        pendingMilestoneNames = new List<String>();
        if (demand.Payment_schedule__c != null && demand.Payment_schedule__r.S_No__c != null) {
            Decimal currentSNo = demand.Payment_schedule__r.S_No__c;
            Id currentScheduleId = demand.Payment_schedule__c;
            for (Payment_Schedule__c ps : [
                SELECT Id, Name, Is_Demanded__c,Pending_Amount__c
                FROM Payment_Schedule__c
                WHERE Booking__c = :bookingId
                AND Status__c = 'Completed'
                AND S_No__c <= :currentSNo
                ORDER BY S_No__c ASC
            ]) {
                if ((ps.Id == currentScheduleId || ps.Is_Demanded__c == false) && ps.Pending_Amount__c > 0) {
                    pendingMilestoneNames.add(ps.Name);
                }
            }
        }
        if (pendingMilestoneNames.isEmpty() && currentCompletedStage != null) {
            pendingMilestoneNames.add(currentCompletedStage);
        }

        demandDueDate = demand.Due_Date__c.date();
        prevDueExcludingTDS = demand.Pending_Dues_excluding_TDS__c ?? 0;
        prevDueExcludingTDS = prevDueExcludingTDS < 0 ? 0 : prevDueExcludingTDS;
        pendingPreviousTDS = demand.Pending_Payment_TDS_1__c ?? 0;
        currentDueExcludingTDS = demand.Current_Milestone_Excluding_the_TDS__c ?? 0;
        currentPendingTDS = demand.Current_Milestone_TDS_1__c ?? 0;
        balanceInterest = demand.Interest_Till_Now__c ?? 0;
        totalAmountPayable = demand.Grand_Total__c ?? 0;
        milestoneAmountInWords = demand.Grand_Total_in_Words__c ?? '';
        
        
        
        totalAmountPayable = totalAmountPayable != null ? totalAmountPayable.setScale(0, RoundingMode.HALF_UP)      : 0;
        
        totalAmountFormatted = totalAmountPayable != null ? totalAmountPayable.setScale(2).format() : '0.00';
        prevDueExcludingTDSFormatted = prevDueExcludingTDS != null ? prevDueExcludingTDS.setScale(2).format() : '0.00';
        pendingPreviousTDSFormatted = pendingPreviousTDS != null ? pendingPreviousTDS.setScale(2).format() : '0.00';
        currentDueExcludingTDSFormatted = currentDueExcludingTDS != null ? currentDueExcludingTDS.setScale(2).format(): '0.00';
        currentPendingTDSFormatted = currentPendingTDS != null? currentPendingTDS.setScale(2).format(): '0.00';
        balanceInterestFormatted = balanceInterest != null? balanceInterest.setScale(2).format() : '0.00'; 
        
        formattedDueDate = '';
        
        if (demand.Due_Date__c != null) {
            List<String> months = new List<String>{
                'January','February','March','April','May','June',
                    'July','August','September','October','November','December'
                    };
                        
                        formattedDueDate = demand.Due_Date__c.day() + ' ' + months[demand.Due_Date__c.month() - 1] + ' ' + demand.Due_Date__c.year();
        }
        
        
    }
    
    
}