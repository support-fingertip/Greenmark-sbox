public class RefundController {
    @AuraEnabled(cacheable=true)
    public static Demand_Raised__c getDemandDetails(Id demandId) {
        return [
            SELECT Id, Name, Grand_Total__c, Demand_Status__c, Booking__r.Name, 
            CreatedDate
            FROM Demand_Raised__c 
            WHERE Id = :demandId
            LIMIT 1
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getRefundFormData() {
        return new Map<String, List<String>>{
            'refundTypes'  => ReceiptController.getPicklistValues('Refund__c', 'Refund_Type__c'),
            'paymentModes' => ReceiptController.getPicklistValues('Refund__c', 'Payment_Mode__c'),
            'bankNames'    => ReceiptController.getPicklistValues('Refund__c', 'Bank_Name__c')
        };
    }

    @AuraEnabled
    public static Id createRefund(Id bookingId, String refundType, Decimal amount,
                                  String refundDateStr, String bankName, String branchName,
                                  String chequeDateStr, String transactionChequeNo,
                                  String drawnOnStr, String paymentMode, String reason) {
        if (bookingId == null) {
            throw new AuraHandledException('Booking is required.');
        }
        if (String.isBlank(refundType)) {
            throw new AuraHandledException('Refund Type is required.');
        }
        if (amount == null || amount <= 0) {
            throw new AuraHandledException('Please enter a valid Refund Amount.');
        }

        Date refundDate = String.isNotBlank(refundDateStr) ? Date.valueOf(refundDateStr) : Date.today();
        Date chequeDate = String.isNotBlank(chequeDateStr) ? Date.valueOf(chequeDateStr) : null;
        Date drawnOn = String.isNotBlank(drawnOnStr) ? Date.valueOf(drawnOnStr) : null;
        Boolean isTds = (refundType == 'TDS Refund');

        // TDS Refund caps each schedule at its pending bank-deducted TDS; Cancellation
        // Refund caps at the principal actually received on the schedule (Received_Amount1__c).
        List<Payment_schedule__c> payList = [
            SELECT Id, S_No__c, Pending_TDS_Refund__c, Received_Amount1__c
            FROM Payment_schedule__c
            WHERE Booking__c = :bookingId
            ORDER BY S_No__c ASC
        ];

        List<Refund__c> toInsert = new List<Refund__c>();
        Decimal remaining = amount;
        for (Payment_schedule__c ps : payList) {
            if (remaining <= 0) {
                break;
            }
            Decimal cap = isTds ? ps.Pending_TDS_Refund__c : ps.Received_Amount1__c;
            if (cap != null && cap > 0) {
                Decimal amt = Math.min(cap, remaining);
                remaining -= amt;
                toInsert.add(buildRefund(bookingId, refundType, refundDate, amt, ps.Id, bankName,
                                         branchName, chequeDate, transactionChequeNo, drawnOn,
                                         paymentMode, reason));
            }
        }

        if (toInsert.isEmpty()) {
            throw new AuraHandledException('No eligible payment schedules to allocate this refund against.');
        }
        if (remaining > 0) {
            if (isTds) {
                // Mirror ReceiptController: dump excess on the last allocated schedule.
                toInsert[toInsert.size() - 1].Refund_Amount__c += remaining;
            } else {
                throw new AuraHandledException(
                    'Refund amount exceeds the total received (Received Amount) of ' +
                    (amount - remaining) + ' for this booking.');
            }
        }
        insert toInsert;
        return bookingId;
    }

    private static Refund__c buildRefund(Id bookingId, String refundType, Date refundDate,
                                         Decimal amount, Id scheduleId, String bankName,
                                         String branchName, Date chequeDate, String transactionChequeNo,
                                         Date drawnOn, String paymentMode, String reason) {
        Refund__c r = new Refund__c();
        r.Booking__c          = bookingId;
        r.Refund_Type__c      = refundType;
        r.Refund_Amount__c    = amount;
        r.Refund_Date__c      = refundDate;
        r.Payment_Schedule__c = scheduleId;
        if (String.isNotBlank(bankName)) {
            r.Bank_Name__c = bankName;
        }
        if (String.isNotBlank(branchName)) {
            r.Branch_Name__c = branchName;
        }
        if (String.isNotBlank(transactionChequeNo)) {
            r.Transaction_ChequeNo__c = transactionChequeNo;
        }
        if (chequeDate != null) {
            r.Cheque_Date__c = chequeDate;
        }
        if (drawnOn != null) {
            r.Drawn_on__c = drawnOn;
        }
        if (String.isNotBlank(paymentMode)) {
            r.Payment_Mode__c = paymentMode;
        }
        if (String.isNotBlank(reason)) {
            r.Reason__c = reason;
        }
        return r;
    }

    @AuraEnabled
    public static Id cancelDemandAndCreateRefund(Id demandId) {
        Demand_Raised__c demand = [
            SELECT Id, Grand_Total__c
            FROM Demand_Raised__c
            WHERE Id = :demandId
            LIMIT 1
        ];
        
        if (demand == null) {
            throw new AuraHandledException('Demand not found.');
        }
        
        // Create Refund
        Refund__c refund = new Refund__c();
        refund.Refund_Amount__c = demand.Grand_Total__c;
        refund.Reversed_Demand__c = demand.Id;
        refund.Refund_Type__c = 'Credit Note';
        insert refund;
        
        // Update Demand
        demand.Demand_Status__c = 'Demand Cancelled';
        update demand;
        
        // Return newly created refund record Id
        return refund.Id;
    }
}