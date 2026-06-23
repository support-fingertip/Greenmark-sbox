public without sharing class ReceiptController {
    public class dataBox{
        @AuraEnabled
        public List<Receipt_Line_Item__c> rcList;
        @AuraEnabled
        public Decimal grandTotal;
        @AuraEnabled
        public List<Payment_schedule__c> pysch{get;set;}
        @AuraEnabled
        public List<Additional_Charges__c> additionalCharges{get;set;}
        @AuraEnabled
        public List<Payment_schedule__c> paymentSchdules {get;set;}
        @AuraEnabled
        public List<string> paymentTypePicklist {get;set;}
        @AuraEnabled
        public List<String> tdsStatusPicklist {get;set;}
        @AuraEnabled
        public List<String> bankNamePicklist {get;set;}
        @AuraEnabled
        public List<Receipt_Line_Item__c> pendingTdsRefunds {get;set;}
        @AuraEnabled
        public Decimal pendingTdsRefundAmount;
        @AuraEnabled
        public Decimal tdsAmount;
        @AuraEnabled
        public Decimal flatOrVillaPendingAmount;
        @AuraEnabled
        public Booking__c bookingRecord; 
        @AuraEnabled
        public decimal iterestAmount;
    } 
    
    // Non-AuraEnabled overload preserved for existing Apex callers / tests.
    public static dataBox getData(String recId) {
        return getData(recId, null);
    }

    @AuraEnabled
    public static dataBox getData(String recId, String receiptType){
        Boolean filterByType = String.isNotBlank(receiptType);
        dataBox dt = new dataBox();
        dt.additionalCharges = [select id,name,Pending_Amount__c
                                from Additional_Charges__c where Booking__c =: recid and Pending_Amount__c> 0];

        // Payment schedule list — filtered by Type__c when caller provided a receipt type (Villas)
        if (filterByType) {
            dt.paymentSchdules = [SELECT Id,Name,Payment_percent__c,
                                  Payment_Due_Date__c,Recived_Per__c,S_No__c,
                                  status__c,Booking__c,Quote__c,Type__c FROM Payment_schedule__c
                                  WHERE Booking__c =:recid AND Type__c =:receiptType
                                  ORDER BY S_No__c ASC];
        } else {
            dt.paymentSchdules = [SELECT Id,Name,Payment_percent__c,
                                  Payment_Due_Date__c,Recived_Per__c,S_No__c,
                                  status__c,Booking__c,Quote__c,Type__c FROM Payment_schedule__c
                                  WHERE Booking__c =:recid ORDER BY S_No__c ASC];
        }
        Set<Id> scopedScheduleIds = new Set<Id>();
        for (Payment_schedule__c ps : dt.paymentSchdules) {
            scopedScheduleIds.add(ps.Id);
        }

        dt.paymentTypePicklist = getPicklistValues('Receipt_Line_Item__c','Mode_of_Payment__c');
        dt.tdsStatusPicklist = getPicklistValues('Receipt_Line_Item__c', 'TDS_Status__c');
        dt.bankNamePicklist = getPicklistValues('Receipt_Line_Item__c', 'Bank_Name__c');

        // bankDeductedTotal — sum of 'TDS from Bank' RLI, optionally restricted to schedules in scope
        // refundedTotal      — sum of legacy 'TDS Refund' RLI + new Refund__c (Refund_Type__c='TDS Refund')
        Decimal refundedTotal = 0;
        Decimal bankDeductedTotal = 0;

        if (filterByType) {
            for (AggregateResult ar : [
                SELECT SUM(Received_Amount__c) total
                FROM Receipt_Line_Item__c
                WHERE Booking__c = :recId
                  AND Payment_Type__c = 'TDS from Bank'
                  AND Payment_Schedule__c IN :scopedScheduleIds
            ]) {
                Decimal t = (Decimal) ar.get('total');
                bankDeductedTotal = t != null ? t : 0;
            }
            for (AggregateResult ar : [
                SELECT SUM(Received_Amount__c) total
                FROM Receipt_Line_Item__c
                WHERE Booking__c = :recId
                  AND Payment_Type__c = 'TDS Refund'
                  AND Payment_Schedule__c IN :scopedScheduleIds
            ]) {
                Decimal t = (Decimal) ar.get('total');
                refundedTotal += t != null ? t : 0;
            }
            for (AggregateResult ar : [
                SELECT SUM(Refund_Amount__c) total
                FROM Refund__c
                WHERE Booking__c = :recId
                  AND Refund_Type__c = 'TDS Refund'
                  AND Payment_Schedule__c IN :scopedScheduleIds
            ]) {
                Decimal t = (Decimal) ar.get('total');
                refundedTotal += t != null ? t : 0;
            }
        } else {
            for (AggregateResult ar : [
                SELECT Payment_Type__c pt, SUM(Received_Amount__c) total
                FROM Receipt_Line_Item__c
                WHERE Booking__c = :recId
                  AND Payment_Type__c IN ('TDS from Bank', 'TDS Refund')
                GROUP BY Payment_Type__c
            ]) {
                Decimal total = (Decimal) ar.get('total');
                if ((String) ar.get('pt') == 'TDS Refund') {
                    refundedTotal += total != null ? total : 0;
                } else {
                    bankDeductedTotal = total != null ? total : 0;
                }
            }
            for (AggregateResult ar : [
                SELECT SUM(Refund_Amount__c) total
                FROM Refund__c
                WHERE Booking__c = :recId
                  AND Refund_Type__c = 'TDS Refund'
            ]) {
                Decimal t = (Decimal) ar.get('total');
                refundedTotal += t != null ? t : 0;
            }
        }

        if (bankDeductedTotal > refundedTotal) {
            if (filterByType) {
                dt.pendingTdsRefunds = [
                    SELECT Id, Name, Received_Amount__c, Amount__c, TDS_Status__c,
                           Receipt__c, Receipt__r.Name,
                           Payment_Schedule__c, Payment_Schedule__r.Name,
                           Mode_of_Payment__c, Drawn_On__c
                    FROM Receipt_Line_Item__c
                    WHERE Booking__c = :recId
                      AND Payment_Type__c = 'TDS from Bank'
                      AND Payment_Schedule__c IN :scopedScheduleIds
                    ORDER BY CreatedDate DESC
                ];
            } else {
                dt.pendingTdsRefunds = [
                    SELECT Id, Name, Received_Amount__c, Amount__c, TDS_Status__c,
                           Receipt__c, Receipt__r.Name,
                           Payment_Schedule__c, Payment_Schedule__r.Name,
                           Mode_of_Payment__c, Drawn_On__c
                    FROM Receipt_Line_Item__c
                    WHERE Booking__c = :recId
                      AND Payment_Type__c = 'TDS from Bank'
                    ORDER BY CreatedDate DESC
                ];
            }
        } else {
            dt.pendingTdsRefunds = new List<Receipt_Line_Item__c>();
        }
        dt.pendingTdsRefundAmount = (bankDeductedTotal > refundedTotal)
            ? (bankDeductedTotal - refundedTotal)
            : 0;

        Booking__c bk =[select Id,Name,Project__c,TOTAL__c,Unit_Number__c,Total_Tds_Amount__c,
                        Pending_Amount__c,Total_Amount__c,Project_Type__c from Booking__c where Id=: recId];
        dt.bookingRecord = bk;

        // ============================
        // Pending principal + TDS — when a receipt type is in scope (Villas),
        // these are computed from the in-scope schedules so the form's top
        // figures match what the user can actually allocate against.
        // ============================
        
        Decimal scopedPrincipalPending = 0;
        Decimal scopedTdsPending = 0;
        Decimal scopedInterest = 0;
        for (Payment_Schedule__c ps : [
            SELECT Id, Pending_Amount_Without_Tds__c, Pending_Tds_Amount__c, Interest_Up_to_Date__c
            FROM Payment_Schedule__c
            WHERE Id IN :scopedScheduleIds
        ]) {
            scopedPrincipalPending += ps.Pending_Amount_Without_Tds__c != null ? ps.Pending_Amount_Without_Tds__c : 0;
            scopedTdsPending += ps.Pending_Tds_Amount__c != null ? ps.Pending_Tds_Amount__c : 0;
            scopedInterest += ps.Interest_Up_to_Date__c != null ? ps.Interest_Up_to_Date__c : 0;
        }
        dt.tdsAmount = scopedTdsPending.setScale(1, RoundingMode.HALF_UP);
        dt.flatOrVillaPendingAmount = scopedPrincipalPending.setScale(1, RoundingMode.HALF_UP);
        dt.iterestAmount = scopedInterest;
        
        return dt;
    }
    public static List<String> getPicklistValues(String objectName, String fieldName) {
        List<String> picklistValueList = new List<String>();
        
        // Get the describe info for the object
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType == null) {
            return picklistValueList; // Return empty list if object not found
        }
        
        // Get field describe info
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        
        if (!fieldMap.containsKey(fieldName)) {
            return picklistValueList; // Return empty list if field not found
        }
        
        Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldName).getDescribe();
        
        // Extract picklist values
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            picklistValueList.add(picklistEntry.getLabel());
        }
        
        return picklistValueList;
    }
    // Non-AuraEnabled overload preserved for existing Apex callers / tests.
    public static Id insertReceiptLineItems(List<Receipt_Line_Item__c> polist, String remark, String poc, String recid, Decimal paidAmount, Decimal interestAmount, String stagedFiles) {
        return insertReceiptLineItems(polist, remark, poc, recid, paidAmount, interestAmount, stagedFiles, null);
    }

    @AuraEnabled
    public static Id insertReceiptLineItems(List<Receipt_Line_Item__c> polist, String remark, String poc, String recid, Decimal paidAmount, Decimal interestAmount, String stagedFiles, String receiptType)
    {
        Booking__c bk = [SELECT Id, Name, Finance_Lead__c, Project__c, Project_Type__c
                         FROM Booking__c WHERE Id = :recid LIMIT 1];

        Boolean filterByType = String.isNotBlank(receiptType);

        // Villas funnel a Type__c through the quick action; schedules are filtered
        // so allocation never crosses Land/Construction boundaries.
        List<Payment_Schedule__c> payList;
        if (filterByType) {
            payList = [
                SELECT Id, Is_Demanded__c, Interest_Pending_Amount__c,
                Villa_Flat_Amount_Pending__c, Pending_Amount__c, Type__c,Pending_Amount_Without_Tds__c,
                S_No__c, Pending_Tds_Amount__c, Pending_TDS_Refund__c
                FROM Payment_Schedule__c
                WHERE Pending_Amount__c > 0 AND Booking__c = :bk.Id AND Type__c = :receiptType
                ORDER BY S_No__c ASC
            ];
        } else {
            payList = [
                SELECT Id, Is_Demanded__c, Interest_Pending_Amount__c,
                Villa_Flat_Amount_Pending__c, Pending_Amount__c, Type__c,Pending_Amount_Without_Tds__c,
                S_No__c, Pending_Tds_Amount__c, Pending_TDS_Refund__c
                FROM Payment_Schedule__c
                WHERE Pending_Amount__c > 0 AND Booking__c = :bk.Id
                ORDER BY S_No__c ASC
            ];
        }
        
        System.debug('Payment Schedule: ' + payList);
        System.debug('Receipt Items from JS: ' + polist);
        
        Map<Id, Decimal> paymentScheduleToPendingAmount = new Map<Id, Decimal>();
        for (Payment_Schedule__c pay : payList) {
            paymentScheduleToPendingAmount.put(pay.Id, pay.Pending_Amount_Without_Tds__c);
        }
        
        // ===============================
        // 1. Main Amount Calculation
        //    (Flat, Villa, Plot, Booking, Row House — excludes TDS & Additional Charges)
        // ===============================
        Map<Integer, Receipt_Line_Item__c> receiptLineItemMap = new Map<Integer, Receipt_Line_Item__c>();
        for (Integer i = 0; i < polist.size(); i++) {
            String payType = polist[i].Payment_Type__c;
            //  FIX: Removed 'TDS' from this block — TDS now has its own section
            if (payType != 'Additional Charges' && payType != 'TDS' &&
                (payType == 'Flat Amount' || payType == 'Villa Amount' || 
                 payType == 'Plot Amount' || payType == 'Booking Amount' ||
                 payType == 'Row House Amount'))
            {
                receiptLineItemMap.put(i + 1, polist[i]);
            }
        }
        
        List<Receipt_Line_Item__c> receiptsToCreate = new List<Receipt_Line_Item__c>();
        
        for (Payment_Schedule__c payIt : payList) {
            if (paymentScheduleToPendingAmount.get(payIt.Id) > 0) {
                for (Integer inte : receiptLineItemMap.keySet()) {
                    if (receiptLineItemMap.get(inte).Received_Amount__c > 0 && paymentScheduleToPendingAmount.get(payIt.Id) > 0) {
                        Decimal amountToReceive = Math.min(
                            paymentScheduleToPendingAmount.get(payIt.Id), 
                            receiptLineItemMap.get(inte).Received_Amount__c
                        );
                        
                        Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                        rece.Booking__c = bk.Id;
                        rece.Name = receiptLineItemMap.get(inte).Payment_Type__c;
                        rece.Payment_Schedule__c = payIt.Id;
                        rece.Received_Amount__c = amountToReceive;
                        rece.Amount__c = amountToReceive;
                        rece.Bank_Name__c = receiptLineItemMap.get(inte).Bank_Name__c;
                        rece.Branch__c = receiptLineItemMap.get(inte).Branch__c;
                        rece.Drawn_On__c = receiptLineItemMap.get(inte).Drawn_On__c;
                        rece.Payment_Type__c = receiptLineItemMap.get(inte).Payment_Type__c;
                        rece.Mode_of_Payment__c = receiptLineItemMap.get(inte).Mode_of_Payment__c;
                        rece.Cheque_Date__c = receiptLineItemMap.get(inte).Cheque_Date__c;
                        rece.Cheque_no_Transaction_Number__c = receiptLineItemMap.get(inte).Cheque_no_Transaction_Number__c;
                        rece.Approval_Status_Picklist__c = 'Approved';
                        receiptsToCreate.add(rece);
                        
                        paymentScheduleToPendingAmount.put(payIt.Id, paymentScheduleToPendingAmount.get(payIt.Id) - amountToReceive);
                        
                        Receipt_Line_Item__c updatedReceiptLineItem = receiptLineItemMap.get(inte);
                        updatedReceiptLineItem.Received_Amount__c -= amountToReceive;
                        receiptLineItemMap.put(inte, updatedReceiptLineItem);
                    }
                }
            }
        }
        
        // ===============================
        // 2. TDS Branches
        //    'TDS from Bank' — bank-deducted TDS, informational; allocated across
        //                      schedules using each schedule's Pending_Tds_Amount__c
        //                      so the per-schedule rollup Total_TDS_From_Bank__c
        //                      attributes correctly.
        //    'TDS Refund'    — Trifecta refunds bank-deducted TDS to the customer;
        //                      allocated across schedules using each schedule's
        //                      Pending_TDS_Refund__c (= Total_TDS_From_Bank__c -
        //                      Total_TDS_Refund_Issued__c). Cannot exceed what bank
        //                      has deducted on a given schedule.
        //    'TDS Challan Entry' — challan from customer; decrements Pending_Tds_Amount__c
        //    'TDS' (legacy)  — preserved for backward compatibility, behaves like 'TDS Challan Entry'
        // ===============================

        // (a) TDS from Bank — split across schedules by Pending_Tds_Amount__c
        Decimal totalTdsFromBank = 0;
        Receipt_Line_Item__c tdsFromBankSrc = null;
        for (Integer i = 0; i < polist.size(); i++) {
            if (polist[i].Payment_Type__c == 'TDS from Bank' &&
                polist[i].Received_Amount__c != null && polist[i].Received_Amount__c > 0) {
                totalTdsFromBank += polist[i].Received_Amount__c;
                if (tdsFromBankSrc == null) {
                    tdsFromBankSrc = polist[i];
                }
            }
        }

        if (totalTdsFromBank > 0 && tdsFromBankSrc != null) {
            Decimal remaining = totalTdsFromBank;
            for (Payment_Schedule__c ps : payList) {
                if (remaining <= 0) {
                    break;
                }
                if (ps.Pending_Tds_Amount__c != null && ps.Pending_Tds_Amount__c > 0) {
                    Decimal amt = Math.min(ps.Pending_Tds_Amount__c, remaining);
                    remaining -= amt;
                    receiptsToCreate.add(buildTdsRli(bk.Id, 'TDS from Bank', amt, ps.Id, tdsFromBankSrc));
                }
            }
            // Excess — attribute to last schedule (matches TDS Challan Entry overflow pattern)
            if (remaining > 0 && !payList.isEmpty()) {
                receiptsToCreate.add(buildTdsRli(
                    bk.Id, 'TDS from Bank', remaining,
                    payList[payList.size() - 1].Id, tdsFromBankSrc
                ));
            }
        }

        // (b) TDS Refund — creates Refund__c records (NOT Receipt_Line_Item__c).
        // Architect direction: a refund is not a receipt; it lives on Refund__c and
        // decrements Pending_TDS_Refund__c via the Total_TDS_Refund_Issued_From_Refund__c
        // rollup maintained by RefundTrigger.
        List<Refund__c> refundsToInsert = new List<Refund__c>();
        Decimal totalTdsRefund = 0;
        Receipt_Line_Item__c tdsRefundSrc = null;
        for (Integer i = 0; i < polist.size(); i++) {
            if (polist[i].Payment_Type__c == 'TDS Refund' &&
                polist[i].Received_Amount__c != null && polist[i].Received_Amount__c > 0) {
                totalTdsRefund += polist[i].Received_Amount__c;
                if (tdsRefundSrc == null) {
                    tdsRefundSrc = polist[i];
                }
            }
        }

        if (totalTdsRefund > 0 && tdsRefundSrc != null) {
            Date refundDate = String.isNotBlank(poc) ? Date.valueOf(poc) : Date.today();
            // A refund is recorded after the principal + TDS from Bank are paid, so the
            // schedule's Pending_Amount__c is 0 and it is absent from payList. Select
            // schedules by Pending_TDS_Refund__c instead so the bank-deducted TDS can be
            // refunded regardless of principal status.
            List<Payment_Schedule__c> refundSchedules = filterByType
                ? [
                    SELECT Id, S_No__c, Pending_TDS_Refund__c
                    FROM Payment_Schedule__c
                    WHERE Booking__c = :bk.Id AND Type__c = :receiptType
                    AND Pending_TDS_Refund__c > 0
                    ORDER BY S_No__c ASC
                  ]
                : [
                    SELECT Id, S_No__c, Pending_TDS_Refund__c
                    FROM Payment_Schedule__c
                    WHERE Booking__c = :bk.Id
                    AND Pending_TDS_Refund__c > 0
                    ORDER BY S_No__c ASC
                  ];
            Decimal remaining = totalTdsRefund;
            for (Payment_Schedule__c ps : refundSchedules) {
                if (remaining <= 0) {
                    break;
                }
                Decimal amt = Math.min(ps.Pending_TDS_Refund__c, remaining);
                remaining -= amt;
                refundsToInsert.add(buildTdsRefund(bk, refundDate, amt, ps.Id, tdsRefundSrc));
            }
            // Excess — attribute to last refund-eligible schedule.
            if (remaining > 0 && !refundSchedules.isEmpty()) {
                refundsToInsert.add(buildTdsRefund(
                    bk, refundDate, remaining,
                    refundSchedules[refundSchedules.size() - 1].Id, tdsRefundSrc
                ));
            }
        }

        // (c) TDS Challan Entry (and legacy 'TDS') — decrement Pending_Tds_Amount__c
        Decimal totalTdsPaid = 0;
        Receipt_Line_Item__c tdsPaidSourceLineItem = null;
        String tdsPaidStampedType = 'TDS Challan Entry';
        for (Integer i = 0; i < polist.size(); i++) {
            String pt = polist[i].Payment_Type__c;
            Boolean isPaidType = (pt == 'TDS Challan Entry' || pt == 'TDS');
            if (isPaidType && polist[i].Received_Amount__c != null && polist[i].Received_Amount__c > 0) {
                totalTdsPaid += polist[i].Received_Amount__c;
                if (tdsPaidSourceLineItem == null) {
                    tdsPaidSourceLineItem = polist[i];
                    tdsPaidStampedType = pt;
                }
            }
        }

        if (totalTdsPaid > 0 && tdsPaidSourceLineItem != null) {
            Decimal remainingTds = totalTdsPaid;
            String tdsStatusToApply = String.isNotBlank(tdsPaidSourceLineItem.TDS_Status__c)
                ? tdsPaidSourceLineItem.TDS_Status__c
                : null;

            for (Payment_Schedule__c paymentSchedule : payList) {
                if (remainingTds <= 0) {
                    break;
                }
                if (paymentSchedule.Pending_Tds_Amount__c != null && paymentSchedule.Pending_Tds_Amount__c > 0) {
                    Decimal amountToReceive = Math.min(paymentSchedule.Pending_Tds_Amount__c, remainingTds);
                    remainingTds -= amountToReceive;

                    Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                    rece.Booking__c = bk.Id;
                    rece.Name = 'Against TDS';
                    rece.Payment_Type__c = tdsPaidStampedType;
                    rece.TDS_Status__c = tdsStatusToApply;
                    rece.Payment_Schedule__c = paymentSchedule.Id;
                    rece.Received_Amount__c = amountToReceive;
                    rece.Amount__c = amountToReceive;
                    rece.Bank_Name__c = tdsPaidSourceLineItem.Bank_Name__c;
                    rece.Branch__c = tdsPaidSourceLineItem.Branch__c;
                    rece.Drawn_On__c = tdsPaidSourceLineItem.Drawn_On__c;
                    rece.Mode_of_Payment__c = tdsPaidSourceLineItem.Mode_of_Payment__c;
                    rece.Cheque_Date__c = tdsPaidSourceLineItem.Cheque_Date__c;
                    rece.Cheque_no_Transaction_Number__c = tdsPaidSourceLineItem.Cheque_no_Transaction_Number__c;
                    rece.Challan_Reference_Number__c = tdsPaidSourceLineItem.Challan_Reference_Number__c;
                    rece.Approval_Status_Picklist__c = 'Approved';

                    if (amountToReceive > 0) {
                        receiptsToCreate.add(rece);
                    }
                }
            }

            // Excess TDS Challan Entry — adjust against last Payment Schedule (interest-overflow pattern)
            if (remainingTds > 0 && !payList.isEmpty()) {
                System.debug('Excess TDS Challan Entry Amount: ' + remainingTds);
                Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                rece.Booking__c = bk.Id;
                rece.Name = 'Against TDS';
                rece.Payment_Type__c = tdsPaidStampedType;
                rece.TDS_Status__c = tdsStatusToApply;
                rece.Payment_Schedule__c = payList[payList.size() - 1].Id;
                rece.Received_Amount__c = remainingTds;
                rece.Amount__c = remainingTds;
                rece.Bank_Name__c = tdsPaidSourceLineItem.Bank_Name__c;
                rece.Branch__c = tdsPaidSourceLineItem.Branch__c;
                rece.Drawn_On__c = tdsPaidSourceLineItem.Drawn_On__c;
                rece.Mode_of_Payment__c = tdsPaidSourceLineItem.Mode_of_Payment__c;
                rece.Cheque_Date__c = tdsPaidSourceLineItem.Cheque_Date__c;
                rece.Cheque_no_Transaction_Number__c = tdsPaidSourceLineItem.Cheque_no_Transaction_Number__c;
                rece.Challan_Reference_Number__c = tdsPaidSourceLineItem.Challan_Reference_Number__c;
                rece.Approval_Status_Picklist__c = 'Approved';
                receiptsToCreate.add(rece);
            }
        }
        
        // ===============================
        // 3. Additional Amount (placeholder for future)
        // ===============================
        
        // ===============================
        // 4. Interest Amount Calculation
        // ===============================
        for (Payment_Schedule__c paymentSchedule : payList) {
            if (interestAmount == null || interestAmount <= 0) {
                break;
            }
            if (interestAmount != 0 && interestAmount != null
                && paymentSchedule.Interest_Pending_Amount__c != null
                && paymentSchedule.Interest_Pending_Amount__c > 0)
            {
                Decimal amountToReceive = Math.min(paymentSchedule.Interest_Pending_Amount__c, interestAmount);
                interestAmount -= amountToReceive;
                
                Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                rece.Booking__c = bk.Id;
                rece.Name = 'Against Interest';
                rece.Payment_Type__c = 'Interest';
                rece.Payment_Schedule__c = paymentSchedule.Id;
                rece.Received_Amount__c = amountToReceive;
                rece.Amount__c = amountToReceive;
                rece.Bank_Name__c = polist[0].Bank_Name__c;
                rece.Mode_of_Payment__c = polist[0].Mode_of_Payment__c;
                rece.Branch__c = polist[0].Branch__c;
                rece.Cheque_no_Transaction_Number__c = polist[0].Cheque_no_Transaction_Number__c;
                rece.Cheque_Date__c = polist[0].Cheque_Date__c;
                rece.Drawn_On__c = polist[0].Drawn_On__c;
                rece.Approval_Status_Picklist__c = 'Approved';
                if (amountToReceive > 0) {
                    receiptsToCreate.add(rece);
                }
            }
        }
        
        // Handle excess Interest — adjust against last Payment Schedule
        if (interestAmount != null && interestAmount > 0) {
            System.debug('Excess Interest Amount: ' + interestAmount);
            Integer paymentScheduleSize = payList.size();
            Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
            rece.Booking__c = bk.Id;
            rece.Name = 'Against Interest';
            rece.Payment_Type__c = 'Interest';
            rece.Payment_Schedule__c = payList[paymentScheduleSize - 1].Id;
            rece.Received_Amount__c = interestAmount;
            rece.Amount__c = interestAmount;
            rece.Bank_Name__c = polist[0].Bank_Name__c;
            rece.Mode_of_Payment__c = polist[0].Mode_of_Payment__c;
            rece.Branch__c = polist[0].Branch__c;
            rece.Cheque_no_Transaction_Number__c = polist[0].Cheque_no_Transaction_Number__c;
            rece.Cheque_Date__c = polist[0].Cheque_Date__c;
            rece.Drawn_On__c = polist[0].Drawn_On__c;
            rece.Approval_Status_Picklist__c = 'Approved';
            receiptsToCreate.add(rece);
        }
        
        // =======================================
        // 5. CREATE RECEIPT
        //
        // The Aura UI now enforces that a single save carries exactly one
        // logical bucket: a principal line (optionally with a TDS from Bank
        // line), OR a standalone Interest line, OR a standalone TDS Challan
        // line. (TDS Refund saves produce a Refund__c, not a Receipt.) So we
        // emit exactly one Receipt__c per save and stamp its category.
        // =======================================
        Set<String> tdsExcludedTypes = new Set<String>{
            'TDS', 'TDS from Bank', 'TDS Refund', 'TDS Challan Entry'
        };

        List<Receipt__c> receiptsToInsert = new List<Receipt__c>();

        if (!receiptsToCreate.isEmpty()) {
            Receipt__c receipt = new Receipt__c();
            receipt.Remarks__c = remark;
            receipt.Receipt_date__c = Date.valueOf(poc);
            receipt.Booking__c = recid;
            receipt.Finance_User__c = bk.Finance_Lead__c;
            receipt.Approval_status__c = 'Approved';
            receipt.Type__c = filterByType ? receiptType : bk.Project_Type__c;
            receipt.Receipt_Payment_Type__c = deriveReceiptPaymentType(receiptsToCreate);

            receiptsToInsert.add(receipt);
            insert receiptsToInsert;

            for (Receipt_Line_Item__c line : receiptsToCreate) {
                line.Receipt__c = receipt.Id;
            }
            insert receiptsToCreate;
        }
        if (!refundsToInsert.isEmpty()) {
            insert refundsToInsert;
        }

        // Stage attached files: create ContentVersion + ContentDocumentLink to
        // every Receipt created in this transaction (Villas split → both
        // Land & Construction receipts get the same file).
        if (String.isNotBlank(stagedFiles)) {
            List<Object> raw = (List<Object>) JSON.deserializeUntyped(stagedFiles);
            if (raw != null && !raw.isEmpty()) {
                List<ContentVersion> versions = new List<ContentVersion>();
                for (Object o : raw) {
                    Map<String, Object> w = (Map<String, Object>) o;
                    String fileName = (String) w.get('name');
                    String b64 = (String) w.get('base64');
                    if (String.isBlank(fileName) || String.isBlank(b64)) {
                        continue;
                    }
                    ContentVersion cv = new ContentVersion();
                    cv.Title = fileName;
                    cv.PathOnClient = fileName;
                    cv.VersionData = EncodingUtil.base64Decode(b64);
                    cv.IsMajorVersion = true;
                    versions.add(cv);
                }
                if (!versions.isEmpty()) {
                    insert versions;

                    Set<Id> versionIds = new Set<Id>();
                    for (ContentVersion cv : versions) {
                        versionIds.add(cv.Id);
                    }
                    Map<Id, Id> versionToDocument = new Map<Id, Id>();
                    for (ContentVersion cv : [
                        SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :versionIds
                    ]) {
                        versionToDocument.put(cv.Id, cv.ContentDocumentId);
                    }

                    // Link files to whichever records this transaction created:
                    // Receipt__c rows if any, else Refund__c rows (TDS-Refund-only flow).
                    List<SObject> linkTargets = new List<SObject>();
                    if (!receiptsToInsert.isEmpty()) {
                        linkTargets.addAll((List<SObject>) receiptsToInsert);
                    } else if (!refundsToInsert.isEmpty()) {
                        linkTargets.addAll((List<SObject>) refundsToInsert);
                    }
                    List<ContentDocumentLink> links = new List<ContentDocumentLink>();
                    for (SObject r : linkTargets) {
                        for (Id vId : versionToDocument.keySet()) {
                            ContentDocumentLink cdl = new ContentDocumentLink();
                            cdl.ContentDocumentId = versionToDocument.get(vId);
                            cdl.LinkedEntityId = (Id) r.get('Id');
                            cdl.ShareType = 'V';
                            cdl.Visibility = 'AllUsers';
                            links.add(cdl);
                        }
                    }
                    if (!links.isEmpty()) {
                        insert links;
                    }
                }
            }
        }

        return bk.Id;
    }

    // Stamp the receipt's category from its line items.
    // Priority: principal > Interest > TDS Challan > TDS from Bank.
    private static String deriveReceiptPaymentType(List<Receipt_Line_Item__c> lines) {
        Set<String> principalTypes = new Set<String>{
            'Flat Amount', 'Villa Amount', 'Row House Amount',
            'Plot Amount', 'Booking Amount', 'GST Amount'
        };
        for (Receipt_Line_Item__c l : lines) {
            if (principalTypes.contains(l.Payment_Type__c)) {
                return l.Payment_Type__c;
            }
        }
        for (Receipt_Line_Item__c l : lines) {
            if (l.Payment_Type__c == 'Interest') {
                return 'Interest';
            }
        }
        for (Receipt_Line_Item__c l : lines) {
            if (l.Payment_Type__c == 'TDS Challan Entry' || l.Payment_Type__c == 'TDS') {
                return 'TDS Challan Entry';
            }
        }
        for (Receipt_Line_Item__c l : lines) {
            if (l.Payment_Type__c == 'TDS from Bank') {
                return 'TDS from Bank';
            }
        }
        return null;
    }

    private static Refund__c buildTdsRefund(Booking__c bk, Date refundDate,Decimal amount, Id scheduleId,Receipt_Line_Item__c src) {
        Refund__c r = new Refund__c();
        r.Booking__c = bk.Id;
        r.Refund_Type__c = 'TDS Refund';
        r.Refund_Amount__c = amount;
        r.Refund_Date__c = refundDate;
        r.Payment_Schedule__c = scheduleId;
        r.Payment_Mode__c = src.Mode_of_Payment__c; 
        r.Bank_Name__c = src.Bank_Name__c;    
        r.Branch_Name__c = src.Branch__c;                                        
        r.Transaction_ChequeNo__c = src.Cheque_no_Transaction_Number__c;                                        
        r.Drawn_On__c = src.Drawn_On__c; 
        r.Cheque_Date__c = src.Cheque_Date__c; 
        return r;
    }

    private static Receipt_Line_Item__c buildTdsRli(Id bookingId, String paymentType,
                                                    Decimal amount, Id scheduleId,
                                                    Receipt_Line_Item__c src) {
        Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
        rece.Booking__c = bookingId;
        rece.Name = paymentType;
        rece.Payment_Type__c = paymentType;
        rece.TDS_Status__c = src.TDS_Status__c;
        rece.Payment_Schedule__c = scheduleId;
        rece.Received_Amount__c = amount;
        rece.Amount__c = amount;
        rece.Bank_Name__c = src.Bank_Name__c;
        rece.Branch__c = src.Branch__c;
        rece.Drawn_On__c = src.Drawn_On__c;
        rece.Mode_of_Payment__c = src.Mode_of_Payment__c;
        rece.Cheque_Date__c = src.Cheque_Date__c;
        rece.Cheque_no_Transaction_Number__c = src.Cheque_no_Transaction_Number__c;
        rece.Challan_Reference_Number__c = src.Challan_Reference_Number__c;
        rece.Approval_Status_Picklist__c = 'Approved';
        return rece;
    }

}