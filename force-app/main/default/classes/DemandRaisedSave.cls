public class DemandRaisedSave {
    //=======================================
    //Signle Demand Raise 
    //=======================================
    
    /**
    * Method Name  : getDemandRaised
    * Description  : Entry method to generate Demand record for selected Payment Schedule milestone.
    *
    * Functionality:
    * 1. Fetches Demand_Raised__c record based on recordId.
    *
    * Parameters:
    * @param milestoneId - Id of Demand_Raised__c recordId record for which demand is raised.
    * Used From:
    * - LWC / Aura component when user clicks “Resend Demand” button from Demand and Component GenerateDemandNote.
    * - Automated demand generation process.
    */
    @AuraEnabled
    public static Demand_Raised__c getDemandRaised(id recordId){
        Demand_Raised__c demand = [SELECT 
                                   Id, Amount_Demanded__c, Booking__c, Current_Demand_amount__c, Name, Demanded_Date__c,Demand_Email_Content__c, 
                                   Due_Date__c, Grand_Total__c, Include_Interest__c, Payment_schedule__c, Previous_pendings__c,Interest_Till_Now__c
                                   FROM Demand_Raised__c WHERE id =: recordId LIMIT 1];
        return demand;
    }
    /**
    * Method Name  : ResendRaiseDemand
    * Description  : Entry method to generate Demand record for selected Payment Schedule milestone.
    *
    * Functionality:
    * 1. Fetches Demand_Raised__c record based on list<Id> recordIds.
    *
    * Parameters:
    * @param milestoneId - Id of Demand_Raised__c list<Id> recordIds.
    * Used From:
    * - LWC / Aura component when user clicks “Resend Demand” button from Demand and Component GenerateDemandNote.
    * - Automated demand generation process.
    */
    @AuraEnabled
    public static void ResendRaiseDemand(list<Id> recordIds){
        if(recordIds.size() > 0){
            try {
                DocumentandEmailController.sendEmailGenerateDemand(recordIds,new List<id>());
                List<Demand_Raised__c> recordsToUpdate = [SELECT Id, Demand_Email_Send__c FROM Demand_Raised__c WHERE Id IN :recordIds];
                for (Demand_Raised__c record : recordsToUpdate) {
                    record.Demand_Email_Send__c = true;
                }
                update recordsToUpdate;
            } catch (Exception e) {
                System.debug('Error during email sending: ' + e.getMessage());
                throw new AuraHandledException('Failed to resend demand. Please try again later.');
            }
        }
    }
    
    /**
    * Method Name  : raiseCustomDemand
    * Description  : When Welcome mail Send Using this method we are raising 1st Demand
    *
    * Functionality:
    * 1. Fetches Payment_Schedule__c record based on milestoneId.
    * 2. Retrieves related Booking__c details required for demand calculations.
    * 3. Passes fetched data to customScheduleCalculations method for:
    *      - Previous due calculation
    *      - Interest computation
    *      - TDS handling
    *      - Grand total preparation
    * 4. Returns success or error message from calculation method.
    *
    * Parameters:
    * @param milestoneId - Id of Payment_Schedule__c record for which demand is raised.
    *
    * Returns:
    * @return String - Success/Error message after demand generation.
    *
    * Used From:
    * - LWC / Aura component when user clicks “Raise Demand” button.
    * - Automated demand generation process.
    */
    @AuraEnabled
    public static String raiseCustomDemand(id milestoneId){
        String result = raiseCustomDemand(milestoneId, false);
        // Preserve LWC API: return success message, not the raw Demand_Raised__c Id
        return (result != null && !result.startsWith('Error')) ? 'Demand raised successfully.' : result;
    }

    // Overload that allows the caller to force Previous_pendings__c,
    // Pending_Payment_TDS_1__c and Pending_Dues_excluding_TDS__c to zero on the
    // created Demand_Raised__c record. Used by the Villa welcome-email flow where
    // S_No = 1 and S_No = 2 demands are raised at the same time and the second
    // demand must not inherit the first demand's still-unpaid amount as a "previous due".
    public static String raiseCustomDemand(id milestoneId, Boolean skipPreviousDues){

        Payment_Schedule__c psRecord = [SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c,
                                        Booking__c,Master_Payment_Schedule__r.S_No__c,Master_Payment_Schedule__c
                                        FROM Payment_Schedule__c WHERE Id = :milestoneId];

        Booking__c book = [SELECT Id,Applicant_Name__c,First_Applicant_Name__c,Plot__r.Name, Total__c, Name, Project__c, Project1__r.Name,GST__c,
                           RecordType.DeveloperName, Quote__r.Agreement_Value_Before_GST__c,Total_Amount__c,Block_Name__c,Unit_No__c,Owner_Phone_Number__c,
                           Company_Name__c FROM Booking__c WHERE Id = :psRecord.Booking__c];
        return customScheduleCalculations(milestoneId,psRecord.Master_Payment_Schedule__c,book,'',false,new List<id>(),skipPreviousDues);
    }

    /**
    * Method Name  : customScheduleCalculations
    * Description  : Core calculation engine to prepare Demand_Raised__c record data.
    *
    * Business Rules:
    * - TDS is customer responsibility.
    * - Grand Total = Sum of Pending + Interest.
    * - Overpayments adjust previous dues.
    *
    * @param milestoneId - Current Payment Schedule Id.
    * @param masterId    - Master Payment Schedule Id (optional).
    * @param book        - Booking__c record.
    *
    * @return String - Success or error message.
    */
    public static String customScheduleCalculations(Id milestoneId, Id masterId, Booking__c book,String emailContent,boolean sendEmail,List<Id> contentIds,Boolean skipPreviousDues) {
        
        /** ==================VARIABLE DECLARATIONS =========================**/
        String totalAmountPayableInWords = '';
        Decimal totalAmountPayable = 0;
        
        String currentCompletedStage = '';
        String currentMilestoneNumber = '';
        Date currentCompletedStageDate;
        Decimal currentSNo = 0;
        
        Decimal balanceTotalInterest = 0;
        Decimal previousbalanceInterest = 0;
        Decimal milestonePaymentPercentResult = 0;
        Decimal totalIntrestAmount = 0;
        
        
        /** ==================GET TEMPLATE RECORD =========================**/
        String template = '';
        if(emailContent =='')
        {
            
            General_Settings__c temp = [
                SELECT Template_Body__c, Type__c 
                FROM General_Settings__c 
                WHERE Project_Name1__c INCLUDES (:book.Project__c)
                AND Type__c = 'Demand Note'
                LIMIT 1
            ];
            
            template = temp.Template_Body__c;
            
            template = template.replace('##APPLICANT_NAME##', book.First_Applicant_Name__c ?? '');
            template = template.replace('##PROJECT_NAME##', book.Project__c ?? '');
            template = template.replace('##BLOCK_NAME##', String.valueOf(book.Block_Name__c ?? ''));
            template = template.replace('##UNIT_NUMBER##', String.valueOf(book.Unit_No__c ?? ''));
            template = template.replace('##CRM_PHONE##', String.valueOf(book.Owner_Phone_Number__c ?? ''));
            template = template.replace('##COMAPANY_NAME##', String.valueOf(book.Company_Name__c ?? ''));
            
        }
        else
        {
            template = emailContent;
        }
        
        
        /** ==================FETCH CURRENT PAYMENT SCHEDULE =========================**/
        Payment_Schedule__c currentPS = [
            SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c
            FROM Payment_Schedule__c
            WHERE Id = :milestoneId
            LIMIT 1
        ];
        
        Boolean hasMaster = (masterId != null);
        
        if (hasMaster) {
            
            Master_Payment_Schedule__c msRecord = [
                SELECT Id, Name, S_No__c, Completed_Date__c
                FROM Master_Payment_Schedule__c
                WHERE Id = :masterId
                LIMIT 1
            ];
            
            currentCompletedStage = msRecord.Name;
            currentCompletedStageDate = msRecord.Completed_Date__c;
            currentSNo = msRecord.S_No__c;
            
        } 
        else {
            
            currentCompletedStage = currentPS.Name;
            currentCompletedStageDate = currentPS.Completed_Date__c;
            currentSNo = currentPS.S_No__c;
        }
        
        if (currentSNo != null) {
            currentMilestoneNumber = getMilestoneLabel(currentSNo.intValue());
        }
        
        
        /** ==================PREVIOUS MILESTONE AGGREGATES =========================**/
        AggregateResult[] aggregateResults = [
            SELECT SUM(Pending_Amount__c) totalPendingAmount,
            SUM(Interest_Up_to_Date__c) totalInterestAmount,
            SUM(Interest_Paid__c) totalInterestPaid,
            SUM(Payment_percent__c) paymentPercentageTill,
            SUM(Total_TDS_Amount__c) tdsAmount,
            SUM(Total_TDS_Refund_Issued__c) tdsrefundissued
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed'
            AND Booking__c = :book.Id
            AND S_No__c < :currentSNo
        ];
        
        Decimal balanceDueTillPrevMilestone = 0;
        Decimal previousMileStoneInterest = 0;
        Decimal previousTotalInterestPaid = 0;
        Decimal previousMilestonePaymentPercent = 0;
        Decimal previousTDS = 0;
        
        Decimal previousTDSAmount = 0;
        Decimal previoustdsRefund = 0;
        

        
        // When skipPreviousDues is true (e.g. raising Villa S_No = 1 and S_No = 2 demands
        // simultaneously from the welcome email flow), treat previous pending/TDS/dues as
        // zero so the downstream fields Previous_pendings__c, Pending_Payment_TDS_1__c and
        // Pending_Dues_excluding_TDS__c are not carried forward onto this demand.
        if (skipPreviousDues != true && !aggregateResults.isEmpty()) {
            AggregateResult ar = aggregateResults[0];
            balanceDueTillPrevMilestone = (Decimal)ar.get('totalPendingAmount') ?? 0;
            previousMileStoneInterest = (Decimal)ar.get('totalInterestAmount') ?? 0;
            previousTotalInterestPaid = (Decimal)ar.get('totalInterestPaid') ?? 0;
            previousMilestonePaymentPercent = (Decimal)ar.get('paymentPercentageTill') ?? 0;
            previousTDSAmount = (Decimal)ar.get('tdsAmount') ?? 0;
            previoustdsRefund = (Decimal)ar.get('tdsrefundissued') ?? 0;
            previousTDS = previousTDSAmount + previoustdsRefund; 
            
        }
        previousbalanceInterest = previousMileStoneInterest - previousTotalInterestPaid;
        
        
        /** ==================CURRENT MILESTONE DUE =========================**/
        AggregateResult presentDueResult = [
            SELECT SUM(Pending_Amount__c) Pending_Amount,
            SUM(Interest_Up_to_Date__c) totalInterestAmount,
            SUM(Interest_Paid__c) totalInterestPaid,
            SUM(Payment_percent__c) paymentPercentage,
            SUM(Total_TDS_Amount__c) tdsAmount
            FROM Payment_Schedule__c
            WHERE S_No__c = :currentSNo
            AND Booking__c = :book.Id
        ];
        
        Decimal presentDue = (Decimal)presentDueResult.get('Pending_Amount') ?? 0;
        Decimal presentInterestAmount = (Decimal)presentDueResult.get('totalInterestAmount') ?? 0;
        Decimal presentInterestAmountPaid = (Decimal)presentDueResult.get('totalInterestPaid') ?? 0;
        Decimal presentMilestonePaymentPercent = (Decimal)presentDueResult.get('paymentPercentage') ?? 0;
        Decimal currentTds = (Decimal)presentDueResult.get('tdsAmount') ?? 0;
        
        Decimal presentBalanceInterst = presentInterestAmount - presentInterestAmountPaid;
        milestonePaymentPercentResult = presentMilestonePaymentPercent + previousMilestonePaymentPercent;
      
        
        
        /** ==================TOTAL RECEIVED INCLUDING CURRENT =========================**/
        AggregateResult[] totalReceivedIncludingCurrent = [
            SELECT SUM(Received_Amount1__c) totalReceivedAmountWithCurrent,
            SUM(Interest_Paid__c) totalInterestPaid
            FROM Payment_Schedule__c
            WHERE Booking__c = :book.Id
        ];
        
        Decimal totalReceivedWithCurrent = 0;
        Decimal totalInterstPaid = 0;
        
        if (!totalReceivedIncludingCurrent.isEmpty()) {
            AggregateResult tr = totalReceivedIncludingCurrent[0];
            
            totalReceivedWithCurrent = (Decimal)tr.get('totalReceivedAmountWithCurrent') ?? 0;
            totalInterstPaid = (Decimal)tr.get('totalInterestPaid') ?? 0;
        }
  
        
        /** ==================TDS CALCULATION =========================**/
        Decimal paidTDS = 0;
        Decimal pendingPreviousTDS = 0;
        Decimal currentPendingTDS = 0;
        Decimal prevDueExcludingTDS = 0;
        Decimal currentDueExcludingTDS = 0;
        
        Decimal totalBookingAmount = book.Total_Amount__c ?? 0;
        
        AggregateResult paidTDSAgg = [SELECT SUM(Received_Amount__c) amt FROM Receipt_Line_Item__c WHERE   
                                      (Payment_Type__c = 'TDS Challan Entry' OR Payment_Type__c = 'TDS from Bank') 
                                      AND Booking__c = :book.Id];
        paidTDS = (Decimal)paidTDSAgg.get('amt') ?? 0;
        
        pendingPreviousTDS = previousTDS - paidTDS;
        pendingPreviousTDS = pendingPreviousTDS < 0 ? 0 : roundToTwo(pendingPreviousTDS);
        
        Decimal remaingTdPaidAmount = paidTDS - previousTDS;
        currentPendingTDS = currentTds;
        currentPendingTDS = remaingTdPaidAmount > 0 ? currentTds - remaingTdPaidAmount : currentPendingTDS;
        currentPendingTDS = currentPendingTDS < 0 ? 0 : currentPendingTDS;
        
        /** ===================== EXCLUDING TDS ===================== **/
        prevDueExcludingTDS = balanceDueTillPrevMilestone - pendingPreviousTDS;
        currentDueExcludingTDS = presentDue - currentTds;
        currentDueExcludingTDS = currentDueExcludingTDS < 0 ? 0 : currentDueExcludingTDS;
        
        /** ==================GRAND TOTAL =========================**/
        balanceTotalInterest = presentBalanceInterst + previousbalanceInterest;
        totalIntrestAmount = previousMileStoneInterest + presentInterestAmount;
        
        Decimal grandTotal = presentDue + balanceDueTillPrevMilestone + balanceTotalInterest;
        
        NumberTOWordConvertion convert = new NumberTOWordConvertion();
        totalAmountPayableInWords = convert.getNumberTOWordConvertion(grandTotal);
        
        
        /** ==================PREPARE DEMAND RECORD =========================**/
        Demand_Raised__c re = new Demand_Raised__c();
        
        re.Current_Demand_amount__c = roundToTwo(presentDue);
        re.Current_Milestone_Excluding_the_TDS__c = roundToTwo(currentDueExcludingTDS);
        re.Current_Milestone_TDS_1__c = roundToTwo(currentTds);
        re.Milestone_Percentage__c = roundToTwo(presentMilestonePaymentPercent);
        re.Pending_Payment_TDS_1__c = roundToTwo(pendingPreviousTDS);
        re.Pending_Dues_excluding_TDS__c = roundToTwo(prevDueExcludingTDS);
        re.Previous_pendings__c = roundToTwo(balanceDueTillPrevMilestone);
        
        re.Include_Interest__c = true;
        re.Due_Date__c = system.today() + 15;
    	re.Demand_Email_Send__c = true;
        
        re.Amount_Demanded__c = grandTotal;
        re.Grand_Total__c = grandTotal;
        re.Total_Amount_Paid__c = totalReceivedWithCurrent;
        re.Total_Percentage_till_Current_Milestone__c = milestonePaymentPercentResult;
        
        re.Interest_Till_Now__c = balanceTotalInterest;
        re.Total_Interest_Paid__c = totalInterstPaid;
        re.Total_Interest__c = totalIntrestAmount;
        
        re.Booking__c = book.Id;
        re.Payment_schedule__c = milestoneId;
        re.Demanded_Date__c = system.now();
        re.Demand_Name__c = currentCompletedStage;
        re.Demand_Email_Content__c = template;
        re.Grand_Total_in_Words__c = totalAmountPayableInWords;
        re.Disable_Demand_Mail__c = true;
        
        /** ==================SAVE RECORDS =========================**/
        try {
            currentPS.Is_Demanded__c = true;
            currentPS.Demanded_Date__c = Date.today();
            update currentPS;
            insert re;
            if(sendEmail && re != null)
            {
                sendDemandEmail(new List<Id>{re.Id},contentIds);
            }
            
            return String.valueOf(re.Id);
            
        } catch (DmlException e) {
            return 'Error: ' + e.getMessage();
        }
    }
    private static Decimal roundToTwo(Decimal value) {
        return value != null ? value.setScale(1, RoundingMode.HALF_UP) : 0;
    }
    
    @future(callout=true)
    public static void sendDemandEmail(List<Id> demandIds,List<Id> contentIds) {
        DocumentandEmailController.sendEmailGenerateDemand(demandIds,contentIds);
    }
    
    /**Raise New Demand When Raise Demand Button Clicked**/
    @AuraEnabled
    public static String raiseNewCustomDemand(String bookingId,String emailContent,List<Id> contentIds){ 
        Payment_Schedule__c psRecord = [SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c, 
                                        Booking__c,Master_Payment_Schedule__r.S_No__c,Master_Payment_Schedule__c 
                                        FROM Payment_Schedule__c WHERE Status__c = 'Completed'  AND Booking__c = :bookingId ORDER BY S_No__c DESC limit 1];
        
        Booking__c book = [SELECT Id,Applicant_Name__c,First_Applicant_Name__c,Plot__r.Name, Total__c, Name, Project__c, Project1__r.Name,GST__c,
                           RecordType.DeveloperName, Quote__r.Agreement_Value_Before_GST__c,Total_Amount__c,Block_Name__c,Unit_No__c,Owner_Phone_Number__c,
                           Company_Name__c,Owner.Email FROM Booking__c WHERE Id = :psRecord.Booking__c];
        String result = customScheduleCalculations(psRecord.Id,psRecord.Master_Payment_Schedule__c,book,emailContent,true,contentIds,false);
        // Preserve LWC API: return success message, not the raw Demand_Raised__c Id
        return (result != null && !result.startsWith('Error')) ? 'Demand raised successfully.' : result;
    }
    
    
    //=======================================
    //Bulk Demand Raise 
    //=======================================
    @AuraEnabled
    public Static String RaiseDemand(List<Id> bookingIds, Map<Id,String> emailContents, map<Id,List<String>> contentIds ) {
        
        String demandRaisedReturn='';
        
        if (bookingIds == null || bookingIds.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Booking records provided.'));
            return 'No Booking records provided';
        }
        
        List<Booking__c> bookings = [SELECT Id,Applicant_Name__c,First_Applicant_Name__c,Plot__r.Name, Total__c, Name, Project__c, GST__c,CRM_Manager__c,
                                     Project1__r.Name,Quote__r.With_GST__c, RecordType.DeveloperName, Quote__r.Agreement_Value_Before_GST__c,
                                     Block_Name__c,Unit_No__c,Owner_Phone_Number__c,Company_Name__c FROM Booking__c WHERE Id IN :bookingIds];
        
        if (bookings.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Booking records found.'));
            return 'No Booking records found';
        }
        
        List<Booking__c> apartmentBookings = new List<Booking__c>();
        
        for (Booking__c book : bookings) {
            apartmentBookings.add(book);
        }
        
        if (!apartmentBookings.isEmpty()) {
            List<Demand_Raised__c> apartmentDemands = bulkScheduleCalculations(apartmentBookings,emailContents,contentIds,true);
            if (apartmentDemands != null && !apartmentDemands.isEmpty()) {
                demandRaisedReturn = 'Demands Raised Successfully';
            }
        }
        
        return demandRaisedReturn;
    }
    
    @TestVisible
    private Static List<Demand_Raised__c> bulkScheduleCalculations1(List<Booking__c> bookings,Map<Id,String> emailContents,
                                                                   map<Id,List<String>> contentIds)
    {
        List<Demand_Raised__c> demands = new List<Demand_Raised__c>();
        Map<Id, Payment_Schedule__c> bookingLatestPaymentSchedules = new Map<Id, Payment_Schedule__c>();
        Map<Id, List<Payment_Schedule__c>> groupedByBooking = new Map<Id, List<Payment_Schedule__c>>();
        Map<Id, Booking__c> bookingProjectMap = new Map<Id, Booking__c>();
        
        for (Booking__c book : bookings) {
            bookingProjectMap.put(book.Id, book);
        }
        
        List<Payment_Schedule__c> psRecords = [
            SELECT Id, S_No__c, Is_Demanded__c, Completed_Date__c, Booking__c, Name, Payment_percent__c, 
            Interest_Paid__c, Received_Amount1__c, Interest_Up_to_Date__c, AmountB__c, Interest_Amount__c, 
            Pending_Amount__c, Last_Payment_Schedule__c
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' AND Booking__c IN :bookings
        ];
        
        for (Payment_Schedule__c ps : psRecords) {
            if (!groupedByBooking.containsKey(ps.Booking__c)) {
                groupedByBooking.put(ps.Booking__c, new List<Payment_Schedule__c>());
            }
            groupedByBooking.get(ps.Booking__c).add(ps);
        }
        
        for (Id bookingId : groupedByBooking.keySet()) {
            List<Payment_Schedule__c> schedules = groupedByBooking.get(bookingId);
            Decimal highestSNo = 0;
            Payment_Schedule__c latestps;
            for (Payment_Schedule__c schedule : schedules) {
                if (schedule.S_No__c != null && schedule.S_No__c > highestSNo) {
                    highestSNo = schedule.S_No__c;
                    latestps = schedule;
                }
            }
            bookingLatestPaymentSchedules.put(bookingId, latestps);         
        }
        
        // Get previous milestones data (excluding current)
        List<AggregateResult> aggregateResults = [
            SELECT Booking__c, 
            SUM(Pending_Amount__c) totalPendingAmount, 
            SUM(Interest_Up_to_Date__c) totalInterestAmount,
            SUM(AmountB__c) totalPayableAmount, 
            SUM(Interest_Up_to_Date__c) totalInterestUplodate, 
            SUM(Received_Amount1__c) totalReceivedAmount,
            SUM(Interest_Paid__c) totalInterestPaid, 
            SUM(Payment_percent__c) paymentPercentageTill
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' 
            AND Booking__c IN :bookings
            AND Id NOT IN :bookingLatestPaymentSchedules.values()
            GROUP BY Booking__c
        ];
        
        // Get total received amount INCLUDING current milestone
        List<AggregateResult> totalReceivedIncludingCurrent = [
            SELECT Booking__c, 
            SUM(Received_Amount1__c) totalReceivedAmountWithCurrent
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' 
            AND Booking__c IN :bookings
            GROUP BY Booking__c
        ];
        
        // Get total pending INCLUDING current milestone
        List<AggregateResult> totalPendingIncludingCurrent = [
            SELECT Booking__c, 
            SUM(Pending_Amount__c) totalPendingWithCurrent
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' 
            AND Booking__c IN :bookings
            GROUP BY Booking__c
        ];
        
        Map<Id, Decimal> bookingToPendingAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToPayableAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestUpToDateAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToReceivedAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestPaidMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToPaymentPercentageMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToTotalReceivedWithCurrentMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToTotalPendingWithCurrentMap = new Map<Id, Decimal>();
        
        for (AggregateResult result : aggregateResults) {
            Id bookingId = (Id) result.get('Booking__c');
            
            bookingToPendingAmountMap.put(bookingId, (Decimal) result.get('totalPendingAmount'));
            bookingToInterestAmountMap.put(bookingId, (Decimal) result.get('totalInterestAmount'));
            bookingToPayableAmountMap.put(bookingId, (Decimal) result.get('totalPayableAmount'));
            bookingToInterestUpToDateAmountMap.put(bookingId, (Decimal) result.get('totalInterestUplodate'));
            bookingToReceivedAmountMap.put(bookingId, (Decimal) result.get('totalReceivedAmount'));
            bookingToInterestPaidMap.put(bookingId, (Decimal) result.get('totalInterestPaid'));
            bookingToPaymentPercentageMap.put(bookingId, (Decimal) result.get('paymentPercentageTill'));
        }
        
        // Map total received including current milestone
        for (AggregateResult result : totalReceivedIncludingCurrent) {
            Id bookingId = (Id) result.get('Booking__c');
            bookingToTotalReceivedWithCurrentMap.put(bookingId, (Decimal) result.get('totalReceivedAmountWithCurrent'));
        }
        
        // Map total pending including current milestone
        for (AggregateResult result : totalPendingIncludingCurrent) {
            Id bookingId = (Id) result.get('Booking__c');
            bookingToTotalPendingWithCurrentMap.put(bookingId, (Decimal) result.get('totalPendingWithCurrent'));
        }
        
        for (Id bookingId : bookingLatestPaymentSchedules.keySet()) {
            
            if (bookingLatestPaymentSchedules.get(bookingId).Is_Demanded__c == true) {
                continue;
            }
            
            // Get values from maps (previous milestones only)
            Decimal totalPayableAmountPrevious = bookingToPayableAmountMap.get(bookingId) != null ? bookingToPayableAmountMap.get(bookingId) : 0;
            Decimal totalReceivedAmountPrevious = bookingToReceivedAmountMap.get(bookingId) != null ? bookingToReceivedAmountMap.get(bookingId) : 0;
            Decimal totalInterestAmount = bookingToInterestAmountMap.get(bookingId) != null ? bookingToInterestAmountMap.get(bookingId) : 0;
            
            // Get total received including current milestone
            Decimal totalReceivedWithCurrent = bookingToTotalReceivedWithCurrentMap.get(bookingId) != null ? bookingToTotalReceivedWithCurrentMap.get(bookingId) : 0;
            
            // Get total pending including current milestone (from Pending_Amount__c field)
            Decimal totalPendingWithCurrent = bookingToTotalPendingWithCurrentMap.get(bookingId) != null ? bookingToTotalPendingWithCurrentMap.get(bookingId) : 0;
            
            Decimal PaymentPercentage = bookingToPaymentPercentageMap.get(bookingId) != null ? bookingToPaymentPercentageMap.get(bookingId) : 0;
            Decimal CurrentPaymentPercentage = bookingLatestPaymentSchedules.get(bookingId).Payment_percent__c;
            Decimal totalInterestUplodateAmount = bookingToInterestUpToDateAmountMap.get(bookingId) != null ? bookingToInterestUpToDateAmountMap.get(bookingId) : 0;
            Decimal totalInterestPaid = bookingToInterestPaidMap.get(bookingId) != null ? bookingToInterestPaidMap.get(bookingId) : 0;
            
            // Previous pending from actual Pending_Amount__c field
            Decimal previousPendingFromField = bookingToPendingAmountMap.get(bookingId) != null ? bookingToPendingAmountMap.get(bookingId) : 0;
            
            Decimal balanceInterest = totalInterestUplodateAmount - totalInterestPaid;
            Decimal presentDue = bookingLatestPaymentSchedules.get(bookingId).AmountB__c;
            
            // TDS Calculation - 1% of Agreement Value Before GST if > 50 lakhs
            Decimal totalSalesConsideration = bookingProjectMap.get(bookingId).Quote__r.Agreement_Value_Before_GST__c != null ? 
                bookingProjectMap.get(bookingId).Quote__r.Agreement_Value_Before_GST__c : 0;
            Decimal TDSonePercentage = totalSalesConsideration > 5000000 ? (totalSalesConsideration * 0.01).setScale(0) : 0;
            
            String currentMilestone = bookingLatestPaymentSchedules.get(bookingId).Name;
            Date currentMilestoneCompletedDate = bookingLatestPaymentSchedules.get(bookingId).Completed_Date__c;
            String currentMilestoneNumber = getMilestoneLabel(bookingLatestPaymentSchedules.get(bookingId).S_No__c.intValue());
            Id currentMilestoneId = bookingLatestPaymentSchedules.get(bookingId).Id;
            
            // Grand Total = Sum of Pending_Amount__c from all milestones (previous + current)
            Decimal grandTotal = totalPendingWithCurrent != null ? totalPendingWithCurrent : 0;
            
            NumberTOWordConvertion convert = new NumberTOWordConvertion();
            String totalAmountPayableInWords = convert.getNumberTOWordConvertion(grandTotal);
            String totaCurrentMilestoneAmount = convert.getNumberTOWordConvertion(presentDue);
            
            String content = emailContents.get(bookingId);            
            
            if (String.isBlank(content)) {
                content = ''
                    + '<div style="color: black;">'
                    + 'Dear <strong>' + bookingProjectMap.get(bookingId).First_Applicant_Name__c + '</strong>,'
                    + '</div><br/>'
                    + '<div>'
                    + '<strong>Greetings from Zuari !!</strong><br/><br/>'
                    + 'Hope this mail finds you in good health and spirit.<br/><br/>'
                    + '<strong>Sub: Requisition for release of instalment.</strong><br/>'
                    + '<strong>Ref: ' + bookingProjectMap.get(bookingId).Project1__r.Name + ', Apartment No. ' + bookingProjectMap.get(bookingId).Plot__r.Name + ' - ' + bookingProjectMap.get(bookingId).First_Applicant_Name__c + '</strong><br/><br/>'
                    + 'This is to remind you that an amount of <strong>INR '+grandTotal+'/-</strong> ('+totalAmountPayableInWords+') will be due against apartment No. '
                    + bookingProjectMap.get(bookingId).Plot__r.Name + ' at <strong>' + bookingProjectMap.get(bookingId).Project1__r.Name + '</strong>.<br/><br/>'
                    + 'Request you to kindly release the amount <br/><br/>'
                    + '<br/><br/>Thank you for choosing <strong>Zuari.</strong><br/><br/>'
                    + 'Best regards,<br/><br/>'
                    + 'Zuari'
                    + '</div>';
            }
            
            Demand_Raised__c re = new Demand_Raised__c();
            re.Current_Demand_amount__c = presentDue; // Always current milestone amount
            re.Previous_pendings__c = previousPendingFromField; // Actual pending from Payment_Schedule__c.Pending_Amount__c
            re.Amount_Demanded__c = grandTotal; // Total amount to pay (can be 0 if overpaid)
            re.Include_Interest__c = true;
            re.Due_Date__c = system.today() + 15;
            re.Interest_Till_Now__c = balanceInterest;
            re.Total_Interest__c = totalInterestUplodateAmount;
            re.Total_Interest_Paid__c = totalInterestPaid;
            re.Grand_Total__c = grandTotal; // Total amount to pay
            re.Demanded_Date__c = system.now();
            re.Payment_schedule__c = currentMilestoneId;
            re.Demand_Name__c =  currentMilestone;
            re.Demand_Email_Content__c = content;
            re.Total_Percentage_till_Current_Milestone__c = PaymentPercentage;
            re.Milestone_Percentage__c = CurrentPaymentPercentage;
            re.Booking__c = bookingId;
            re.Total_Amount_Paid__c = totalReceivedWithCurrent; // FIXED: Now includes current milestone payment
            re.Grand_Total_in_Words__c = totalAmountPayableInWords;
            demands.add(re);
        }
        
        if (!demands.isEmpty()) {
            insert demands;
        }
        return demands;
    }
    
    @TestVisible
    private static List<Demand_Raised__c> bulkScheduleCalculations(
        List<Booking__c> bookings,
        Map<Id, String> emailContents,
        Map<Id, List<String>> contentIds,
        Boolean sendEmail
    ) {
        List<Demand_Raised__c> demands = new List<Demand_Raised__c>();
        Map<Id, Payment_Schedule__c> bookingLatestPaymentSchedules = new Map<Id, Payment_Schedule__c>();
        Map<Id, List<Payment_Schedule__c>> groupedByBooking = new Map<Id, List<Payment_Schedule__c>>();
        Map<Id, Booking__c> bookingProjectMap = new Map<Id, Booking__c>();
        Set<Id> bookingIds = new Set<Id>();
        
        for (Booking__c book : bookings) {
            bookingProjectMap.put(book.Id, book);
            bookingIds.add(book.Id);
        }
        
        /** ==================FETCH ALL PAYMENT SCHEDULES (all statuses) ========================= **/
        // Mirror customScheduleCalculations: current-milestone sums have NO status filter,
        // previous-milestone sums are Completed-only, and total-received spans all rows.
        // Fetch every row once and aggregate in-memory to stay bulk-safe (no SOQL in loops).
        List<Payment_Schedule__c> psRecords = [
            SELECT Id, S_No__c, Status__c, Is_Demanded__c, Completed_Date__c, Booking__c, Name,
            Payment_percent__c, Interest_Paid__c, Received_Amount1__c, Interest_Up_to_Date__c,
            Pending_Amount__c, Total_TDS_Amount__c, Total_TDS_Refund_Issued__c
            FROM Payment_Schedule__c
            WHERE Booking__c IN :bookingIds
        ];

        for (Payment_Schedule__c ps : psRecords) {
            if (!groupedByBooking.containsKey(ps.Booking__c)) {
                groupedByBooking.put(ps.Booking__c, new List<Payment_Schedule__c>());
            }
            groupedByBooking.get(ps.Booking__c).add(ps);
        }

        /** ==================CURRENT MILESTONE S_No (max completed) ========================= **/
        // The current milestone is the highest S_No among Completed rows (mirrors the single
        // method, where the milestone being raised is the latest completed schedule).
        Map<Id, Decimal> bookingToCurrentSNo = new Map<Id, Decimal>();
        for (Id bookingId : groupedByBooking.keySet()) {
            Decimal maxCompletedSNo;
            for (Payment_Schedule__c ps : groupedByBooking.get(bookingId)) {
                if (ps.Status__c == 'Completed' && ps.S_No__c != null
                    && (maxCompletedSNo == null || ps.S_No__c > maxCompletedSNo)) {
                    maxCompletedSNo = ps.S_No__c;
                }
            }
            if (maxCompletedSNo != null) bookingToCurrentSNo.put(bookingId, maxCompletedSNo);
        }

        // Representative current Payment Schedule per booking (used for milestone metadata
        // and the Is_Demanded skip/mark). Pick the first Completed row at the current S_No.
        for (Id bookingId : bookingToCurrentSNo.keySet()) {
            Decimal curSNo = bookingToCurrentSNo.get(bookingId);
            for (Payment_Schedule__c ps : groupedByBooking.get(bookingId)) {
                if (ps.Status__c == 'Completed' && ps.S_No__c == curSNo) {
                    bookingLatestPaymentSchedules.put(bookingId, ps);
                    break;
                }
            }
        }

        /** ==================BUILD MAPS (in-memory aggregation) ========================= **/
        // Previous milestone maps
        Map<Id, Decimal> prevPendingMap = new Map<Id, Decimal>();
        Map<Id, Decimal> prevInterestMap = new Map<Id, Decimal>();
        Map<Id, Decimal> prevInterestPaidMap = new Map<Id, Decimal>();
        Map<Id, Decimal> prevPaymentPercentMap = new Map<Id, Decimal>();
        Map<Id, Decimal> prevTDSMap = new Map<Id, Decimal>();
        // Current milestone maps
        Map<Id, Decimal> currPendingMap = new Map<Id, Decimal>();
        Map<Id, Decimal> currInterestMap = new Map<Id, Decimal>();
        Map<Id, Decimal> currInterestPaidMap = new Map<Id, Decimal>();
        Map<Id, Decimal> currPaymentPercentMap = new Map<Id, Decimal>();
        Map<Id, Decimal> currTDSMap = new Map<Id, Decimal>();
        // Total received maps (all milestones)
        Map<Id, Decimal> totalReceivedMap = new Map<Id, Decimal>();
        Map<Id, Decimal> totalInterestPaidAllMap = new Map<Id, Decimal>();

        for (Id bookingId : groupedByBooking.keySet()) {
            Decimal curSNo = bookingToCurrentSNo.containsKey(bookingId) ? bookingToCurrentSNo.get(bookingId) : null;

            Decimal prevPending = 0, prevInt = 0, prevIntPaid = 0, prevPct = 0, prevTdsAmt = 0, prevTdsRefund = 0;
            Decimal curPending = 0, curInt = 0, curIntPaid = 0, curPct = 0, curTds = 0;
            Decimal totRecv = 0, totIntPaid = 0;

            for (Payment_Schedule__c ps : groupedByBooking.get(bookingId)) {
                // Total received = ALL rows, ALL statuses
                totRecv += ps.Received_Amount1__c ?? 0;
                totIntPaid += ps.Interest_Paid__c ?? 0;

                if (curSNo != null && ps.S_No__c == curSNo) {
                    // Current milestone = rows at current S_No, NO status filter
                    curPending += ps.Pending_Amount__c ?? 0;
                    curInt += ps.Interest_Up_to_Date__c ?? 0;
                    curIntPaid += ps.Interest_Paid__c ?? 0;
                    curPct += ps.Payment_percent__c ?? 0;
                    curTds += ps.Total_TDS_Amount__c ?? 0;
                }
                if (ps.Status__c == 'Completed' && curSNo != null && ps.S_No__c != null && ps.S_No__c < curSNo) {
                    // Previous milestones = Completed AND S_No < current
                    prevPending += ps.Pending_Amount__c ?? 0;
                    prevInt += ps.Interest_Up_to_Date__c ?? 0;
                    prevIntPaid += ps.Interest_Paid__c ?? 0;
                    prevPct += ps.Payment_percent__c ?? 0;
                    prevTdsAmt += ps.Total_TDS_Amount__c ?? 0;
                    prevTdsRefund += ps.Total_TDS_Refund_Issued__c ?? 0;
                }
            }

            prevPendingMap.put(bookingId, prevPending);
            prevInterestMap.put(bookingId, prevInt);
            prevInterestPaidMap.put(bookingId, prevIntPaid);
            prevPaymentPercentMap.put(bookingId, prevPct);
            prevTDSMap.put(bookingId, prevTdsAmt + prevTdsRefund); // matches single: TDS amount + refund issued
            currPendingMap.put(bookingId, curPending);
            currInterestMap.put(bookingId, curInt);
            currInterestPaidMap.put(bookingId, curIntPaid);
            currPaymentPercentMap.put(bookingId, curPct);
            currTDSMap.put(bookingId, curTds);
            totalReceivedMap.put(bookingId, totRecv);
            totalInterestPaidAllMap.put(bookingId, totIntPaid);
        }

        /** ==================TDS FROM RECEIPT LINE ITEMS ========================= **/
        List<AggregateResult> tdsReceipts = [
            SELECT Booking__c,
            SUM(Received_Amount__c) paidTDS
            FROM Receipt_Line_Item__c
            WHERE (Payment_Type__c = 'TDS Challan Entry' OR Payment_Type__c = 'TDS from Bank')
            AND Booking__c IN :bookingIds
            GROUP BY Booking__c
        ];

        // TDS paid map
        Map<Id, Decimal> tdsPaidMap = new Map<Id, Decimal>();
        for (AggregateResult ar : tdsReceipts) {
            Id bookingId = (Id) ar.get('Booking__c');
            tdsPaidMap.put(bookingId, (Decimal) ar.get('paidTDS') ?? 0);
        }
        
        /** ==================EMAIL TEMPLATE FETCH (bulk) ========================= **/
        // Collect all unique project names
        Set<String> projectNames = new Set<String>();
        for (Booking__c book : bookings) {
            if (String.isNotBlank(book.Project__c)) {
                projectNames.add(book.Project__c);
            }
        }
        
        // Bulk fetch templates
        Map<String, String> templateByProject = new Map<String, String>();
        if (!projectNames.isEmpty()) {
            
            // Build INCLUDES clause dynamically for multi-select picklist
            List<String> includesClauses = new List<String>();
            for (String pName : projectNames) {
                includesClauses.add('\'' + String.escapeSingleQuotes(pName) + '\'');
            }
            String includesValue = String.join(includesClauses, ',');
            
            String query = 'SELECT Template_Body__c, Project_Name1__c '
                + 'FROM General_Settings__c '
                + 'WHERE Project_Name1__c INCLUDES (' + includesValue + ') '
                + 'AND Type__c = \'Demand Note\'';
            
            List<General_Settings__c> templates = Database.query(query);
            
            // Build the map — since Project_Name1__c is multi-select,
            // map each individual project value to the template
            for (General_Settings__c gs : templates) {
                if (String.isNotBlank(gs.Project_Name1__c)) {
                    for (String proj : gs.Project_Name1__c.split(';')) {
                        if (projectNames.contains(proj)) {
                            templateByProject.put(proj, gs.Template_Body__c);
                        }
                    }
                }
            }
        }
        
        /** ==================PROCESS EACH BOOKING ========================= **/
        List<Payment_Schedule__c> psToUpdate = new List<Payment_Schedule__c>();
        
        for (Id bookingId : bookingLatestPaymentSchedules.keySet()) {
            
            Payment_Schedule__c currentPS = bookingLatestPaymentSchedules.get(bookingId);
            
            // Skip if already demanded
            if (currentPS == null || currentPS.Is_Demanded__c == true) {
                continue;
            }
            
            Booking__c book = bookingProjectMap.get(bookingId);
            
            // ===== PREVIOUS MILESTONE VALUES =====
            Decimal balanceDueTillPrevMilestone = prevPendingMap.containsKey(bookingId) ? prevPendingMap.get(bookingId) : 0;
            Decimal previousMilestoneInterest = prevInterestMap.containsKey(bookingId) ? prevInterestMap.get(bookingId) : 0;
            Decimal previousTotalInterestPaid = prevInterestPaidMap.containsKey(bookingId) ? prevInterestPaidMap.get(bookingId) : 0;
            Decimal previousMilestonePaymentPercent = prevPaymentPercentMap.containsKey(bookingId) ? prevPaymentPercentMap.get(bookingId) : 0;
            Decimal previousTDS = prevTDSMap.containsKey(bookingId) ? prevTDSMap.get(bookingId) : 0;
            
            Decimal previousBalanceInterest = previousMilestoneInterest - previousTotalInterestPaid;
            
            // ===== CURRENT MILESTONE VALUES =====
            Decimal presentDue = currPendingMap.containsKey(bookingId) ? currPendingMap.get(bookingId) : 0;
            Decimal presentInterestAmount = currInterestMap.containsKey(bookingId) ? currInterestMap.get(bookingId) : 0;
            Decimal presentInterestPaid = currInterestPaidMap.containsKey(bookingId) ? currInterestPaidMap.get(bookingId) : 0;
            Decimal presentMilestonePaymentPercent = currPaymentPercentMap.containsKey(bookingId) ? currPaymentPercentMap.get(bookingId) : 0;
            Decimal currentTds = currTDSMap.containsKey(bookingId) ? currTDSMap.get(bookingId) : 0;
            
            Decimal presentBalanceInterest = presentInterestAmount - presentInterestPaid;
            Decimal milestonePaymentPercentResult = presentMilestonePaymentPercent + previousMilestonePaymentPercent;
            
            // ===== TOTAL RECEIVED (all milestones) =====
            Decimal totalReceivedWithCurrent = totalReceivedMap.containsKey(bookingId) ? totalReceivedMap.get(bookingId) : 0;
            Decimal totalInterestPaidAll = totalInterestPaidAllMap.containsKey(bookingId) ? totalInterestPaidAllMap.get(bookingId) : 0;
            
            // ===== TDS CALCULATION (matching single method logic) =====
            Decimal paidTDS = tdsPaidMap.containsKey(bookingId) ? tdsPaidMap.get(bookingId) : 0;
            
            Decimal pendingPreviousTDS = previousTDS - paidTDS;
            pendingPreviousTDS = pendingPreviousTDS < 0 ? 0 : pendingPreviousTDS;
            
            Decimal remainingTdsPaidAmount = paidTDS - previousTDS;
            Decimal currentPendingTDS = currentTds;
            currentPendingTDS = remainingTdsPaidAmount > 0 ? currentTds - remainingTdsPaidAmount : currentPendingTDS;
            currentPendingTDS = currentPendingTDS < 0 ? 0 : currentPendingTDS;
            
            // Excluding TDS
            Decimal prevDueExcludingTDS = balanceDueTillPrevMilestone - pendingPreviousTDS;
            Decimal currentDueExcludingTDS = presentDue - currentTds;
            currentDueExcludingTDS = currentDueExcludingTDS < 0 ? 0 : currentDueExcludingTDS;
            
            // ===== GRAND TOTAL (matching single method formula) =====
            Decimal balanceTotalInterest = presentBalanceInterest + previousBalanceInterest;
            Decimal totalInterestAmount = previousMilestoneInterest + presentInterestAmount;
            
            Decimal grandTotal = presentDue + balanceDueTillPrevMilestone + balanceTotalInterest;
            
            // ===== CONVERT TO WORDS =====
            NumberTOWordConvertion convert = new NumberTOWordConvertion();
            String totalAmountPayableInWords = convert.getNumberTOWordConvertion(grandTotal);
            
            // ===== EMAIL TEMPLATE RESOLUTION =====
            String content = emailContents != null ? emailContents.get(bookingId) : null;
            
            if (String.isBlank(content)) {
                String templateBody = templateByProject.get(book.Project__c);
                if (String.isNotBlank(templateBody)) {
                    content = templateBody;
                    content = content.replace('##APPLICANT_NAME##', book.First_Applicant_Name__c ?? '');
                    content = content.replace('##PROJECT_NAME##', book.Project__c ?? '');
                    content = content.replace('##BLOCK_NAME##', String.valueOf(book.Block_Name__c ?? ''));
                    content = content.replace('##UNIT_NUMBER##', String.valueOf(book.Unit_No__c ?? ''));
                    content = content.replace('##CRM_PHONE##', String.valueOf(book.Owner_Phone_Number__c ?? ''));
                    content = content.replace('##COMAPANY_NAME##', String.valueOf(book.Company_Name__c ?? ''));
                } else {
                    // Fallback hardcoded template (existing Zuari template)
                    content = ''
                        + '<div style="color: black;">'
                        + 'Dear <strong>' + (book.First_Applicant_Name__c ?? '') + '</strong>,'
                        + '</div><br/>'
                        + '<div>'
                        + '<strong>Greetings!!</strong><br/><br/>'
                        + 'Hope this mail finds you in good health and spirit.<br/><br/>'
                        + '<strong>Sub: Requisition for release of instalment.</strong><br/><br/>'
                        + 'An amount of <strong>INR ' + grandTotal + '/-</strong> (' + totalAmountPayableInWords + ') is due.<br/><br/>'
                        + 'Request you to kindly release the amount.<br/><br/>'
                        + 'Best regards'
                        + '</div>';
                }
            }
            
            // ===== MILESTONE INFO =====
            String currentMilestone = currentPS.Name;
            Date currentMilestoneCompletedDate = currentPS.Completed_Date__c;
            String currentMilestoneNumber = getMilestoneLabel(currentPS.S_No__c.intValue());
            Id currentMilestoneId = currentPS.Id;
            
            // ===== BUILD DEMAND RECORD (matching all fields from single method) =====
            Demand_Raised__c re = new Demand_Raised__c();
            
            re.Current_Demand_amount__c = roundToTwo(presentDue);
            re.Current_Milestone_Excluding_the_TDS__c = roundToTwo(currentDueExcludingTDS);
            re.Current_Milestone_TDS_1__c = roundToTwo(currentTds);
            re.Milestone_Percentage__c = roundToTwo(presentMilestonePaymentPercent);
            re.Pending_Payment_TDS_1__c = roundToTwo(pendingPreviousTDS);
            re.Pending_Dues_excluding_TDS__c = roundToTwo(prevDueExcludingTDS);
            re.Previous_pendings__c = roundToTwo(balanceDueTillPrevMilestone);
            
            re.Include_Interest__c = true;
            re.Due_Date__c = System.today() + 15;
            re.Demand_Email_Send__c = true;                                      
            
            re.Amount_Demanded__c = grandTotal;
            re.Grand_Total__c = grandTotal;
            re.Total_Amount_Paid__c = totalReceivedWithCurrent;
            re.Total_Percentage_till_Current_Milestone__c = milestonePaymentPercentResult;
            
            re.Interest_Till_Now__c = balanceTotalInterest;                         
            re.Total_Interest_Paid__c = totalInterestPaidAll;
            re.Total_Interest__c = totalInterestAmount;                            
            
            re.Booking__c = bookingId;
            re.Payment_schedule__c = currentMilestoneId;
            re.Demanded_Date__c = System.now();
            re.Demand_Name__c = currentMilestone;
            re.Demand_Email_Content__c = content;
            re.Grand_Total_in_Words__c = totalAmountPayableInWords;
            re.Disable_Demand_Mail__c = true;                                      
            
            demands.add(re);
            
            // ===== MARK PAYMENT SCHEDULE AS DEMANDED ===== 
            Payment_Schedule__c psUpdate = new Payment_Schedule__c();
            psUpdate.Id = currentPS.Id;
            psUpdate.Is_Demanded__c = true;
            psUpdate.Demanded_Date__c = Date.today();
            psToUpdate.add(psUpdate);
        }
        
        /** ==================SAVE ALL RECORDS ========================= **/
        if (!psToUpdate.isEmpty()) {
            update psToUpdate;
        }
        if (!demands.isEmpty()) {
            insert demands;
            
            // Send emails if required
            if (sendEmail) {
                List<Id> demandIds = new List<Id>();
                for (Demand_Raised__c d : demands) {
                    demandIds.add(d.Id);
                }
                // Collect all content IDs
                List<Id> allContentIds = new List<Id>();
                if (contentIds != null) {
                    for (List<String> cIds : contentIds.values()) {
                        for (String cId : cIds) {
                            allContentIds.add(Id.valueOf(cId));
                        }
                    }
                }
                if (!demandIds.isEmpty()) {
                    sendDemandEmail(demandIds, allContentIds);
                }
            }
        }
        return demands;
    }
    
    public static Map<Integer, String> daySuffixMap = new Map<Integer, String>{1 => 'st', 2 => 'nd', 3 => 'rd', 21 => 'st', 22 => 'nd', 23 => 'rd', 31 => 'st'};
        
    public static String getMilestoneLabel(Integer sNo) {
            if (sNo == null) {
                return 'Invalid milestone';
            }
            String suffix = daySuffixMap.containsKey(sNo) ? daySuffixMap.get(sNo) : 'th';
            return sNo + suffix;
        }
    
    @AuraEnabled
    public static BookingWrapper getBookingRecord(Id recordId) {
        Booking__c booking = [
            SELECT Id, Project__c, Project1__r.Name, 
            Total_received_Amount__c, First_Applicant_Name__c, Plot__r.Name,Total__c
            FROM Booking__c 
            WHERE Id = :recordId 
            LIMIT 1
        ];
        
        List<Payment_Schedule__c> psRecordList = [
            SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' AND Booking__c = :recordId
            ORDER BY S_No__c DESC 
            LIMIT 1
        ];
        
        Payment_Schedule__c currentMilestone = psRecordList.isEmpty() ? null : psRecordList[0];
        
        return new BookingWrapper(booking, currentMilestone);
    }
    
    public class BookingWrapper {
        @AuraEnabled
        public Booking__c booking { get; set; }
        @AuraEnabled
        public Payment_Schedule__c currentMilestone { get; set; }
        
        public BookingWrapper(Booking__c booking, Payment_Schedule__c currentMilestone) {
            this.booking = booking;
            this.currentMilestone = currentMilestone;
        }
    }
    
    public Decimal totalAmount;
    public Decimal totalPaymentPercent;
    public Decimal totalPendingAmount;
    public Decimal totalReceivedAmount;
    public Decimal totalInterest;
    
    public Static String RaiseDemandController(ID bookingRecordId) {
        Booking__c bk = [select id,Agreement_Value_Before_GST__c,Payment_Plan_Name__c,Booking_Date__c,Project1__r.GST_on_Aggrement__c from Booking__c where Id =:bookingRecordId];
        Payment_schedule__c ps = [select id,Amount__c,AmountB__c,Master_Payment_Schedule__c From Payment_schedule__c where Booking__c =: bk.Id and S_No__c=1];
        
        Decimal demandAmount = bk.Agreement_Value_Before_GST__c* 0.2;
        Demand_Raised__c re = new Demand_Raised__c();
        re.Current_Demand_amount__c = ps.AmountB__c; 
        re.Amount_Demanded__c = ps.AmountB__c;
        re.Include_Interest__c = true;
        if(bk.Payment_Plan_Name__c =='20:80 Payment plan'){
            re.Due_Date__c = bk.Booking_Date__c + 20;
        }
        if(bk.Payment_Plan_Name__c =='70:30 Payment Plan'){
            re.Due_Date__c = bk.Booking_Date__c+ 15;
        }
        else{
            re.Due_Date__c = bk.Booking_Date__c+ 30;
        }
        re.Demanded_Date__c = system.now();
        re.Payment_schedule__c = ps.Id;
        re.Booking__c = bookingRecordId;
        
        try{
            insert re;
            return 'Demand Created';
        }
        catch(Exception e){
            return e.getMessage();
        }
    }

    @TestVisible
    public Static List<Demand_Raised__c> bulkAutoDemands ( Map<String,Decimal> bookingsWithPSNO) {
        System.debug(bookingsWithPSNO);
        List<Demand_Raised__c> demands = new List<Demand_Raised__c>();
        
        Map<Id, Payment_Schedule__c> bookingLatestPaymentSchedules = new Map<Id, Payment_Schedule__c>();
        Map<Id, List<Payment_Schedule__c>> groupedByBooking = new Map<Id, List<Payment_Schedule__c>>();
        Map<Id, Booking__c> bookingProjectMap = new Map<Id, Booking__c>();
        List<Id> CompletedPsIDs = new List<Id> ();
        
        List<Booking__c> bookings = [Select Id, Total__c, Applicant_Name__c,First_Applicant_Name__c, Project1__r.Name, Plot__r.Name, GST__c, 
                                     Project1__r.GST_on_Aggrement__c, RecordType.DeveloperName, Quote__r.With_GST__c,
                                     Quote__r.Agreement_Value_Before_GST__c,Block_Name__c
                                     from Booking__c WHERE Id IN: bookingsWithPSNO.keySet()];
        
        if(bookings.isEmpty()){
            return null;
        }
        
        for (Booking__c book : bookings) {
            bookingProjectMap.put(book.Id, book);
        }
        
        List<Payment_Schedule__c> psRecords = [
            SELECT Id, S_No__c, Is_Demanded__c, Completed_Date__c, Booking__c, Name, Payment_percent__c, 
            Interest_Paid__c, Received_Amount1__c, Interest_Up_to_Date__c, AmountB__c, Interest_Amount__c, 
            Pending_Amount__c, Last_Payment_Schedule__c
            FROM Payment_Schedule__c
            WHERE Booking__c IN :bookings
        ];
        
        System.debug(psRecords);
        for (Payment_Schedule__c ps : psRecords) {
            if (!groupedByBooking.containsKey(ps.Booking__c)) {
                groupedByBooking.put(ps.Booking__c, new List<Payment_Schedule__c>());
            }
            
            if( ps.S_No__c <= bookingsWithPSNO.get(ps.Booking__c)){
                groupedByBooking.get(ps.Booking__c).add(ps);
                CompletedPsIDs.add(ps.Id);
            }
        }
        
        System.debug(CompletedPsIDs);
        for (Id bookingId : groupedByBooking.keySet()) {
            List<Payment_Schedule__c> schedules = groupedByBooking.get(bookingId);
            
            for (Payment_Schedule__c schedule : schedules) {
                if (schedule.S_No__c != null && schedule.S_No__c == bookingsWithPSNO.get(bookingId)) {
                    bookingLatestPaymentSchedules.put(bookingId, schedule);         
                }
            }
        }
        
        // Get previous milestones data (excluding current milestone)
        List<AggregateResult> aggregateResults = [
            SELECT Booking__c, 
            SUM(Pending_Amount__c) totalPendingAmount, 
            SUM(Interest_Amount__c) totalInterestAmount,
            SUM(AmountB__c) totalPayableAmount, 
            SUM(Interest_Up_to_Date__c) totalInterestUplodate, 
            SUM(Received_Amount1__c) totalReceivedAmount,
            SUM(Interest_Paid__c) totalInterestPaid, 
            SUM(Payment_percent__c) paymentPercentageTill
            FROM Payment_Schedule__c
            WHERE Booking__c IN :bookings 
            AND Id IN: CompletedPsIDs
            AND Id NOT IN :bookingLatestPaymentSchedules.values()
            GROUP BY Booking__c
        ];
        
        // Get total received INCLUDING current milestone
        List<AggregateResult> totalReceivedIncludingCurrent = [
            SELECT Booking__c,
            SUM(Received_Amount1__c) totalReceivedAmountWithCurrent
            FROM Payment_Schedule__c
            WHERE Booking__c IN :bookings 
            AND Id IN: CompletedPsIDs
            GROUP BY Booking__c
        ];
        
        // Get total pending INCLUDING current milestone
        List<AggregateResult> totalPendingIncludingCurrent = [
            SELECT Booking__c,
            SUM(Pending_Amount__c) totalPendingWithCurrent
            FROM Payment_Schedule__c
            WHERE Booking__c IN :bookings 
            AND Id IN: CompletedPsIDs
            GROUP BY Booking__c
        ];
        Map<Id, Decimal> bookingToTotalPendingWithCurrentMap = new Map<Id, Decimal>();
        
        system.debug(aggregateResults);
        Map<Id, Decimal> bookingToPendingAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToPayableAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestUpToDateAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToReceivedAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestPaidMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToPaymentPercentageMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToTotalReceivedWithCurrentMap = new Map<Id, Decimal>();
        
        for (AggregateResult result : aggregateResults) {
            Id bookingId = (Id) result.get('Booking__c');
            
            bookingToPendingAmountMap.put(bookingId, (Decimal) result.get('totalPendingAmount'));
            bookingToInterestAmountMap.put(bookingId, (Decimal) result.get('totalInterestAmount'));
            bookingToPayableAmountMap.put(bookingId, (Decimal) result.get('totalPayableAmount'));
            bookingToInterestUpToDateAmountMap.put(bookingId, (Decimal) result.get('totalInterestUplodate'));
            bookingToReceivedAmountMap.put(bookingId, (Decimal) result.get('totalReceivedAmount'));
            bookingToInterestPaidMap.put(bookingId, (Decimal) result.get('totalInterestPaid'));
            bookingToPaymentPercentageMap.put(bookingId, (Decimal) result.get('paymentPercentageTill'));
        }
        
        // Map total received including current milestone
        for (AggregateResult result : totalReceivedIncludingCurrent) {
            Id bookingId = (Id) result.get('Booking__c');
            bookingToTotalReceivedWithCurrentMap.put(bookingId, (Decimal) result.get('totalReceivedAmountWithCurrent'));
        }
        
        // Map total pending including current milestone
        for (AggregateResult result : totalPendingIncludingCurrent) {
            Id bookingId = (Id) result.get('Booking__c');
            bookingToTotalPendingWithCurrentMap.put(bookingId, (Decimal) result.get('totalPendingWithCurrent'));
        }
        
        System.debug(bookingToPendingAmountMap);
        
        for (Id bookingId : bookingLatestPaymentSchedules.keySet()) {
            
            if (bookingLatestPaymentSchedules.get(bookingId).Is_Demanded__c == true) {
                system.debug(bookingLatestPaymentSchedules.get(bookingId).Is_Demanded__c);
                continue;
            }
            
            // Get values from maps (previous milestones only)
            Decimal totalPayableAmountPrevious = bookingToPayableAmountMap.get(bookingId) != null ? bookingToPayableAmountMap.get(bookingId) : 0;
            Decimal totalReceivedAmountPrevious = bookingToReceivedAmountMap.get(bookingId) != null ? bookingToReceivedAmountMap.get(bookingId) : 0;
            
            // Get total received including current milestone
            Decimal totalReceivedWithCurrent = bookingToTotalReceivedWithCurrentMap.get(bookingId) != null ? bookingToTotalReceivedWithCurrentMap.get(bookingId) : 0;
            
            // Get total pending including current milestone (from Pending_Amount__c field)
            Decimal totalPendingWithCurrent = bookingToTotalPendingWithCurrentMap.get(bookingId) != null ? bookingToTotalPendingWithCurrentMap.get(bookingId) : 0;
            
            Decimal PaymentPercentage = bookingToPaymentPercentageMap.get(bookingId) != null ? bookingToPaymentPercentageMap.get(bookingId) : 0;
            Decimal CurrentPaymentPercentage = bookingLatestPaymentSchedules.get(bookingId).Payment_percent__c;
            Decimal totalInterestUplodateAmount = bookingToInterestUpToDateAmountMap.get(bookingId) != null ? bookingToInterestUpToDateAmountMap.get(bookingId) : 0;
            Decimal totalInterestPaid = bookingToInterestPaidMap.get(bookingId) != null ? bookingToInterestPaidMap.get(bookingId) : 0;
            
            // Previous pending from actual Pending_Amount__c field
            Decimal previousPendingFromField = bookingToPendingAmountMap.get(bookingId) != null ? bookingToPendingAmountMap.get(bookingId) : 0;
            
            Decimal balanceInterest = totalInterestUplodateAmount - totalInterestPaid;
            Decimal presentDue = bookingLatestPaymentSchedules.get(bookingId).AmountB__c;
            
            // TDS Calculation - 1% of Agreement Value Before GST if > 50 lakhs
            Decimal totalSalesConsideration = bookingProjectMap.get(bookingId).Quote__r.Agreement_Value_Before_GST__c != null ? 
                bookingProjectMap.get(bookingId).Quote__r.Agreement_Value_Before_GST__c : 0;
            Decimal TDSonePercentage = totalSalesConsideration > 5000000 ? (totalSalesConsideration * 0.01).setScale(0) : 0;
            
            String currentMilestone = bookingLatestPaymentSchedules.get(bookingId).Name;
            Date currentMilestoneCompletedDate = bookingLatestPaymentSchedules.get(bookingId).Completed_Date__c;
            String currentMilestoneNumber =getMilestoneLabel(bookingLatestPaymentSchedules.get(bookingId).S_No__c.intValue());
            Id currentMilestoneId = bookingLatestPaymentSchedules.get(bookingId).Id;
            
            // Grand Total = Sum of Pending_Amount__c from all milestones (previous + current)
            Decimal grandTotal = totalPendingWithCurrent != null ? totalPendingWithCurrent : 0;
            
            NumberTOWordConvertion convert = new NumberTOWordConvertion();
            String totalAmountPayableInWords = convert.getNumberTOWordConvertion(grandTotal);
            String totaCurrentMilestoneAmount = convert.getNumberTOWordConvertion(presentDue);
            
            String content = ''
                + '<div style="color: black;">'
                + 'Dear <strong>' + bookingProjectMap.get(bookingId).First_Applicant_Name__c + '</strong>,'
                + '</div><br/>'
                + '<div>'
                + '<strong>Greetings from Zuari !!</strong><br/><br/>'
                + 'Hope this mail finds you in good health and spirit.<br/><br/>'
                + '<strong>Sub: Requisition for release of instalment.</strong><br/>'
                + '<strong>Ref: ' + bookingProjectMap.get(bookingId).Project1__r.Name + ', Apartment No. ' + bookingProjectMap.get(bookingId).Plot__r.Name + ' - ' + bookingProjectMap.get(bookingId).First_Applicant_Name__c + '</strong><br/><br/>'
                + 'This is to remind you that an amount of <strong>INR '+grandTotal+'/-</strong> ('+totalAmountPayableInWords+') will be due against apartment No. '
                + bookingProjectMap.get(bookingId).Plot__r.Name + ' at <strong>' + bookingProjectMap.get(bookingId).Project1__r.Name + '</strong>.<br/><br/>'
                + 'Request you to kindly release the amount <br/><br/>'
                + '<br/><br/>Thank you for choosing <strong>Zuari.</strong><br/><br/>'
                + 'Best regards,<br/><br/>'
                + 'Zuari'
                + '</div>';
            
            Demand_Raised__c re = new Demand_Raised__c();
            re.Current_Demand_amount__c = presentDue; // Always current milestone amount
            re.Previous_pendings__c = previousPendingFromField; // Actual pending from Payment_Schedule__c.Pending_Amount__c
            re.Amount_Demanded__c = grandTotal; // Total amount to pay (can be 0 if overpaid)
            re.Include_Interest__c = true;
            re.Due_Date__c = system.today() + 15;
            re.Interest_Till_Now__c = balanceInterest;
            re.Total_Interest__c = totalInterestUplodateAmount;
            re.Total_Interest_Paid__c = totalInterestPaid;
            re.Grand_Total__c = grandTotal; // Total amount to pay
            re.Demanded_Date__c = system.now();
            re.Payment_schedule__c = currentMilestoneId;
            re.Demand_Name__c =  currentMilestone;
            re.Demand_Email_Content__c = content;
            re.Total_Percentage_till_Current_Milestone__c = PaymentPercentage;
            re.Milestone_Percentage__c = CurrentPaymentPercentage;
            re.Booking__c = bookingId;
            re.Total_Amount_Paid__c = totalReceivedWithCurrent; // FIXED: Now includes current milestone payment
            re.Grand_Total_in_Words__c = totalAmountPayableInWords;
            demands.add(re);
        }
        
        System.debug(demands);
        if (!demands.isEmpty()) {
            insert demands;
        }
        return demands;
    }    
}