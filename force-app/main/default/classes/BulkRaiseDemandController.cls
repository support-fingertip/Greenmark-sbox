public without sharing class BulkRaiseDemandController {
    
    public class BookingWrapper {
        @AuraEnabled public Booking__c booking;
        @AuraEnabled public Decimal displayAmount;
        @AuraEnabled public Decimal totalPaymentAmount;
        @AuraEnabled public Decimal grandTotal;
        @AuraEnabled public Decimal totalAmountPaid;
        @AuraEnabled public Id paymentScheduleId;
        @AuraEnabled public Decimal previousDemandRaisedPending;
        @AuraEnabled public Boolean demandRaised;
        @AuraEnabled public String includeInterest;
        @AuraEnabled public Id unitId;
        @AuraEnabled public Boolean selected;
        @AuraEnabled public String currentMilestone;
        @AuraEnabled public Decimal balanceInterest;
        @AuraEnabled public Decimal tdsRefundIssued;
        
        public BookingWrapper(Booking__c booking, Decimal displayAmount, Decimal totalPaymentAmount, 
                              Id paymentScheduleId, Decimal previousDemandRaisedPending, 
                              Decimal grandTotal, String includeInterest, Boolean demandRaised, 
                              Id unitId,Boolean selected,String currentMilestone,Decimal totalAmountPaid,Decimal balanceInterest)
        {
            this.booking = booking;
            this.displayAmount = displayAmount;
            this.totalPaymentAmount = totalPaymentAmount;
            this.paymentScheduleId = paymentScheduleId;
            this.previousDemandRaisedPending = previousDemandRaisedPending;
            this.grandTotal = grandTotal;
            this.demandRaised = demandRaised;
            this.includeInterest = includeInterest;
            this.unitId = unitId;
            this.selected = selected;
            this.currentMilestone = currentMilestone;
            This.totalAmountPaid = totalAmountPaid;
            this.balanceInterest = balanceInterest;
        }
    }
    
    @AuraEnabled
    public static List<BookingWrapper> getBookingRecords(String masterPaymentScheduleId) {
        // Query the Master_Payment_Schedule__c and related Project__c in one query
        Master_Payment_Schedule__c masterPaymentSchedule = [
            SELECT Id, Name, S_No__c, Project__r.Project__c, Completed_Date__c 
            FROM Master_Payment_Schedule__c 
            WHERE Id = :masterPaymentScheduleId 
            LIMIT 1
        ];
        
        if (masterPaymentSchedule != null) {
            String projectValue = masterPaymentSchedule.Project__r.Project__c;
            map<id,payment_schedule__c> paymentBookMap = new map<id,payment_schedule__c>();
            // Query all relevant payment_schedule__c records
            List<payment_schedule__c> getPayScheLineItems = [
                SELECT Id, Name, Amount__c, Is_Demanded__c, Booking__c, AmountB__c, 
                Received_Amount1__c, Pending_Amount__c, status__c, 
                Master_Payment_Schedule__r.Completed_Date__c, Demand_Uploaded__c 
                FROM payment_schedule__c 
                WHERE Master_Payment_Schedule__c = :masterPaymentScheduleId
            ];
            
            list<id> bookingLists = new list<id>();
            for(payment_schedule__c pay : getPayScheLineItems){
                bookingLists.add(pay.Booking__c);
                paymentBookMap.put(pay.Booking__c, pay);
            }
            
            List<Booking__c> bookings = [
                SELECT Id, Name, Plot__r.Name, Project1__r.Name, Email__c,S__c,Applicant_Name__c
                FROM Booking__c
                WHERE id IN :bookingLists
                ORDER BY CreatedDate ASC
            ];
            
            system.debug('bookings '+bookings);
            system.debug('paymentBookMap '+paymentBookMap);
            system.debug('masterPaymentSchedule '+masterPaymentSchedule);
            List<BookingWrapper> result = bookingScheduleCalculations(bookings,paymentBookMap,masterPaymentSchedule);
            
            return result;
        }
        
        return new List<BookingWrapper>();
    }
    
    @AuraEnabled
    public static List<BookingWrapper> bookingScheduleCalculations(List<Booking__c> bookings,map<id,payment_schedule__c> bookingPaymentMap,
                                                                   Master_payment_Schedule__c masterPaymentSchedule) 
    {
        List<BookingWrapper> result = new List<BookingWrapper>();
        
        List<Demand_Raised__c> demands = new List<Demand_Raised__c>();
        Decimal completed_StageNumber;
        Map<Id, Master_Payment_Schedule__c> towerToMasterPaymentScheduleMap = new Map<Id, Master_Payment_Schedule__c>();
        map<id,Decimal> debitAmountMap = new map<id,Decimal>();
        
        for (Booking__c book : bookings) {
            if (masterPaymentSchedule != null) {
                completed_StageNumber = masterPaymentSchedule.S_No__c;
            }
        }
        
        // Query all Payment Schedules for the provided bookings
        List<AggregateResult> aggregateResults = [
            SELECT Booking__c, SUM(Pending_Amount__c) totalPendingAmount, SUM(Interest_Amount__c) totalInterestAmount,
            SUM(AmountB__c) totalPayableAmount, SUM(Interest_Up_to_Date__c) totalInterestUplodateAmount,
            SUM(Interest_Paid__c) totalInterestPaid, SUM(Payment_percent__c) paymentPercentageTill
            FROM Payment_Schedule__c
            WHERE Master_Payment_Schedule__r.Status__c = 'Completed' 
            AND Booking__c IN :bookings AND Master_Payment_Schedule__r.S_No__c <: completed_StageNumber
            GROUP BY Booking__c
        ];
        
        // Map to store the aggregated payment schedule results
        Map<Id, AggregateResult> bookingToAggregateResultMap = new Map<Id, AggregateResult>();
        for (AggregateResult result1 : aggregateResults) {
            bookingToAggregateResultMap.put((Id) result1.get('Booking__c'), result1);
        }
        
        // Query total received amounts for all bookings
        List<AggregateResult> totalReceivedResults = [
            SELECT Booking__c, SUM(Received_Amount1__c) totalReceivedAmount,SUM(AmountB__c) totalAmountB
            FROM Payment_Schedule__c
            WHERE Booking__c IN :bookings AND Master_Payment_Schedule__r.S_No__c = :completed_StageNumber
            GROUP BY Booking__c
        ];
        
        List<AggregateResult> totalReceivedAmount = [
            SELECT Booking__c, SUM(Received_Amount1__c) totalReceivedAmount, SUM(Total_TDS_Refund_Issued__c) totalTdsRefund
            FROM Payment_Schedule__c
            WHERE Booking__c IN :bookings
            GROUP BY Booking__c
        ];
        Map<Id, Decimal> bookingToReceivedAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToTdsRefundMap = new Map<Id, Decimal>();
        for (AggregateResult result2 : totalReceivedAmount) {
            bookingToReceivedAmountMap.put((Id) result2.get('Booking__c'), (Decimal) result2.get('totalReceivedAmount'));
            bookingToTdsRefundMap.put((Id) result2.get('Booking__c'), (Decimal) result2.get('totalTdsRefund'));
        }
        
        // Map to store total received amounts per booking
        Map<Id, Decimal> bookingToThisMSAmountMap = new Map<Id, Decimal>();
        for (AggregateResult result3 : totalReceivedResults) {
            bookingToThisMSAmountMap.put((Id) result3.get('Booking__c'), (Decimal) result3.get('totalAmountB'));
        }
        
        for (Booking__c book : bookings) {
            AggregateResult aggregateResult = bookingToAggregateResultMap.get(book.Id);
            Decimal currentaggregate = bookingToThisMSAmountMap.get(book.Id);
            Decimal totalPaidAmount =  bookingToReceivedAmountMap.get(book.Id) != null ? bookingToReceivedAmountMap.get(book.Id): 0;
            Decimal tdsRefundIssued = bookingToTdsRefundMap.get(book.Id) != null ? bookingToTdsRefundMap.get(book.Id) : 0;
            if (aggregateResult == null && currentaggregate != null) {
                Decimal presentDue = bookingToThisMSAmountMap.get(book.Id) != null ? bookingToThisMSAmountMap.get(book.Id) : 0;
                Decimal totalAmountPayable = presentDue - totalPaidAmount + tdsRefundIssued;
                //Decimal TDSonePercentage = presentDue * 0.01;
                //totalAmountPayable = (totalAmountPayable - TDSonePercentage).setScale(0);
                totalAmountPayable = (totalAmountPayable).setScale(0);

                NumberTOWordConvertion convert = new NumberTOWordConvertion();
                String totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);

                Boolean demandRaised = bookingPaymentMap.get(book.id).Is_Demanded__c;
                String currentMilestone = bookingPaymentMap.get(book.id).Name;
                Id unitId = book.Plot__c;
                String bookingProject = book.Project1__r.Name;

                BookingWrapper bw = new BookingWrapper(
                    book,
                    0,                      // previous due = 0
                    presentDue.setScale(0),             // current milestone amount
                    null,
                    0,                      // balanceDueTillPrevMilestone = 0
                    totalAmountPayable,     // total due = current milestone
                    'false',
                    demandRaised,
                    unitId,
                    false,
                    currentMilestone,
                    totalPaidAmount,
                    0
                );
                bw.tdsRefundIssued = tdsRefundIssued.setScale(0);
                result.add(bw);

                continue;
            }
            
            if (aggregateResult == null) {
                continue;
            }
            
            Decimal totalPendingAmount = (Decimal) aggregateResult.get('totalPendingAmount') != null ? (Decimal) aggregateResult.get('totalPendingAmount') : 0;
            Decimal totalInterestAmount = (Decimal) aggregateResult.get('totalInterestAmount') != null ? (Decimal) aggregateResult.get('totalInterestAmount') : 0;
            Decimal totalPayableAmount = (Decimal) aggregateResult.get('totalPayableAmount') != null ? (Decimal) aggregateResult.get('totalPayableAmount') : 0;
            Decimal totalInterestUplodateAmount = (Decimal) aggregateResult.get('totalInterestUplodateAmount') != null ? (Decimal) aggregateResult.get('totalInterestUplodateAmount') : 0;
            Decimal totalInterestPaid = (Decimal) aggregateResult.get('totalInterestPaid') != null ? (Decimal) aggregateResult.get('totalInterestPaid') : 0;
            Decimal milestonePaymentPercent = (Decimal) aggregateResult.get('paymentPercentageTill') != null ? (Decimal) aggregateResult.get('paymentPercentageTill') : 0;
            
            Decimal paidTotalAmount = bookingToReceivedAmountMap.get(book.Id) != null ? bookingToReceivedAmountMap.get(book.Id) : 0;
            //if (debitAmountMap.get(book.Id) != null) {
            //    paidTotalAmount -= debitAmountMap.get(book.Id);
            // }
            
            Decimal balanceDueTillPrevMilestoneMod = totalPayableAmount - paidTotalAmount;
            Decimal balanceDueTillPrevMilestone = balanceDueTillPrevMilestoneMod > 0 ? balanceDueTillPrevMilestoneMod : 0;
            Decimal balanceInterest = totalInterestUplodateAmount - totalInterestPaid;
            Decimal presentDue = bookingToThisMSAmountMap.get(book.Id) != null ? bookingToThisMSAmountMap.get(book.Id) : 0;
            
            //Decimal TDSonePercentage = presentDue * 0.01;
            Decimal actualTotalAmountPayable = (balanceDueTillPrevMilestoneMod + balanceInterest + presentDue + tdsRefundIssued/* - TDSonePercentage*/).setScale(0);
            Decimal totalAmountPayable = actualTotalAmountPayable > 0 ? actualTotalAmountPayable : 0;
            
            NumberTOWordConvertion convert = new NumberTOWordConvertion();
            String totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
            
            Boolean demandRaised = bookingPaymentMap.get(book.id).Is_Demanded__c;
            String currentMilestone = bookingPaymentMap.get(book.id).Name;
            Id unitId = book.Plot__c;
            String bookingProject = book.Project1__r.Name;
            
            BookingWrapper bw = new BookingWrapper(
                book,
                0,
                presentDue,
                null,
                balanceDueTillPrevMilestone,
                totalAmountPayable,
                'false',
                demandRaised,
                unitId,
                false,
                currentMilestone,
                paidTotalAmount,
                balanceInterest
            );
            bw.tdsRefundIssued = tdsRefundIssued.setScale(0);
            result.add(bw);
        }
        
        system.debug('result '+result);
        return result;
    }
    
    
    
    
    @AuraEnabled
    public static List<BookingWrapper> getBookingRecordsWithProject(String masterPaymentScheduleId) {
        
        // Query the Master_Payment_Schedule__c and related Project__c in one query
        Master_Payment_Schedule__c masterPaymentSchedule = [
            SELECT Id, Name, S_No__c, Project__r.Project__c, Completed_Date__c 
            FROM Master_Payment_Schedule__c 
            WHERE Id = :masterPaymentScheduleId 
            LIMIT 1
        ];
        
        if (masterPaymentSchedule != null) {
            String projectValue = masterPaymentSchedule.Project__r.Project__c;
            map<id,payment_schedule__c> paymentBookMap = new map<id,payment_schedule__c>();
            // Query all relevant payment_schedule__c records
            List<payment_schedule__c> getPayScheLineItems = [
                SELECT Id, Name, Amount__c, Is_Demanded__c, Booking__c, AmountB__c, 
                Received_Amount1__c, Pending_Amount__c, status__c, 
                Master_Payment_Schedule__r.Completed_Date__c, Demand_Uploaded__c 
                FROM payment_schedule__c 
                WHERE Master_Payment_Schedule__c = :masterPaymentScheduleId
            ];
            
            list<id> bookingLists = new list<id>();
            for(payment_schedule__c pay : getPayScheLineItems){
                bookingLists.add(pay.Booking__c);
                paymentBookMap.put(pay.Booking__c, pay);
            }
            
            List<Booking__c> bookings = [
                SELECT Id, Name,  Plot__r.Name, Project1__r.Name, Email__c,S__c,Applicant_Name__c FROM Booking__c
                WHERE id IN :bookingLists
                ORDER BY CreatedDate ASC
            ];
            
            
            List<BookingWrapper> result = bookingScheduleCalculations(bookings,paymentBookMap,masterPaymentSchedule);
            
            return result;
        }
        
        return new List<BookingWrapper>();
    }

    
    @AuraEnabled
    public static void updatePaymentSchedules(Id payIds){
        List<payment_schedule__c> payList = [select id,name, Is_Demanded__c,Payment_Due_Date__c from payment_schedule__c where id =: payIds];
        system.debug('payList   '+payList);
        system.debug('payIds   '+payIds);
        List<payment_schedule__c> toUpdate = new List<payment_schedule__c>();
        for(payment_schedule__c p : payList){
            p.Is_Demanded__c = true;
            if(p.Payment_Due_Date__c != null){
                p.Payment_Due_Date__c = System.today() + 15;
            }
            toUpdate.add(p);
        }
        if(toUpdate.size()>0){
            update toUpdate;
            system.debug('after updated   '+toUpdate);
        }
    }


}