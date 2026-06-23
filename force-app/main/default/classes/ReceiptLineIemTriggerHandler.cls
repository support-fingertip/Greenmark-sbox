/****************************************************************
* Class Name   : ReceiptLineIemTriggerHandler
* Company      : Fingertipplus
* Created Date : 06-02-2026
* @description : This handler class contains all business logic
*                executed from Receipt_Line_Item__c trigger such as:
*                - Interest calculation on payment schedule
*                - Creation of Interest Amount Line Items
*                - Updating last payment date and time on schedule
*
* @author      : Durga Prasad
*
* Change Log:
* ----------------------------------------------------------------
* Ver | Author        | Date        | Description
* ----------------------------------------------------------------
* 1.0 | Durga Prasad | 04-02-2026  | Initial version
* ----------------------------------------------------------------
*****************************************************************/
public class ReceiptLineIemTriggerHandler {

    /**
     * Method Name  : afterInsert
     * Description  : Executes business logic after Receipt_Line_Item__c insert.
     *
     * Functionality:
     * 1. Collects inserted receipt line item Ids
     * 2. Calls approvedReceiptsHandler for further processing
     *
     * Used From:
     * - Receipt_Line_Item__c Trigger (after insert)
     */
    public static void afterInsert(List<Receipt_Line_Item__c> newReceiptlineItemList) {

        Set<Id> newReceiptlineItemIds = new Set<Id>();

        for (Receipt_Line_Item__c rcp : newReceiptlineItemList) {
            newReceiptlineItemIds.add(rcp.Id);
        }

        if (!newReceiptlineItemIds.isEmpty()) {
            approvedReceiptsHandler(newReceiptlineItemIds);
        }
      
        
    }


      /**
     * Method Name  : approvedReceiptsHandler
     * Description  : Handles payment schedule update and
     *                interest calculation after receipt approval.
     *
     * Functionality:
     * 1. Fetches Receipt_Line_Item__c linked to provided receipts.
     * 2. Retrieves related Payment_schedule__c records.
     * 3. For Payment schedules with Include_Interest__c = true:
     *      - Creates Interest_Amount_Line_Item__c record
     *      - Sets interest start date from last payment date
     *        or payment due date.
     *      - Sets interest end date as today.
     * 4. Updates on Payment Schedule:
     *      - Last_Payment_Date__c
     *      - Last_Payment_Time__c
     * 5. Inserts interest line items and updates schedules in bulk.
     *
     * Parameters:
     * @param receiptIds - Set of Receipt__c record Ids
     *
     * Used From:
     * - afterInsert method of ReceiptTriggerHandler
    */ 
    public static void approvedReceiptsHandler(Set<Id> newReceiptlineItemIds) {
        
        List<Receipt_Line_Item__c> recLinIds = [
            SELECT id, Name, Receipt__r.Receipt_date__c, Booking__c,
            Payment_schedule__c, Received_Amount__c,
            Payment_schedule__r.PaymentDueDate__c,
            Payment_schedule__r.Last_Payment_Date__c,
            Payment_schedule__r.Interest_Percent__c,
            Payment_Type__c,
            Payment_schedule__r.Include_Interest__c
            FROM Receipt_Line_Item__c
            WHERE Id IN :newReceiptlineItemIds
            AND Payment_Type__c NOT IN ('Interest', 'TDS from Bank', 'TDS Refund')
        ];
        
        // One Schedule - Many Receipt Lines
        Map<Id, List<Receipt_Line_Item__c>> scheduleToReceipts = new Map<Id, List<Receipt_Line_Item__c>>();
        
        for (Receipt_Line_Item__c rli : recLinIds) {
            if (!scheduleToReceipts.containsKey(rli.Payment_schedule__c)) {
                scheduleToReceipts.put(rli.Payment_schedule__c, new List<Receipt_Line_Item__c>());
            }
            scheduleToReceipts.get(rli.Payment_schedule__c).add(rli);
        }
        
        List<Payment_schedule__c> payList1 = [
            SELECT id, name, Booking__c, PaymentDueDate__c,
            Last_Payment_Date__c, Include_Interest__c,
            Interest_Percent__c, Interest_Amount__c,
            Pending_Amount__c
            FROM Payment_schedule__c
            WHERE id IN :scheduleToReceipts.keySet()
        ];
        
        List<Interest_Amount_Line_Item__c> IntAmtLiEs = new List<Interest_Amount_Line_Item__c>();
        
        Date todayDate = Date.today();
        
        //  Process each schedule and its MULTIPLE receipts
        for (Payment_schedule__c pay : payList1) {
            
            List<Receipt_Line_Item__c> relatedReceipts = scheduleToReceipts.get(pay.Id);
            
            Date latestReceiptDate = pay.Last_Payment_Date__c;
            
            for (Receipt_Line_Item__c recipetItem : relatedReceipts) {
                
                // Track latest receipt date
                if (latestReceiptDate == null ||
                    recipetItem.Receipt__r.Receipt_date__c > latestReceiptDate) {
                        latestReceiptDate = recipetItem.Receipt__r.Receipt_date__c;
                    }
                
                //  Interest condition check
                if (
                    recipetItem.Payment_schedule__r.Include_Interest__c == true &&
                    recipetItem.Payment_schedule__r.PaymentDueDate__c != null &&
                    recipetItem.Received_Amount__c != null &&
                    recipetItem.Payment_schedule__r.Interest_Percent__c != null &&
                    recipetItem.Receipt__r.Receipt_date__c >
                    recipetItem.Payment_schedule__r.PaymentDueDate__c
                ) {
                    
                    Interest_Amount_Line_Item__c IntLine =
                        new Interest_Amount_Line_Item__c();
                    
                    Decimal days =
                        recipetItem.Payment_schedule__r.PaymentDueDate__c
                        .daysBetween(recipetItem.Receipt__r.Receipt_date__c);
                    
                    IntLine.Interest_Amount__c =(recipetItem.Received_Amount__c*recipetItem.Payment_schedule__r.Interest_Percent__c*days)/36500;
                    
                    // Start Date Logic
                    if (recipetItem.Payment_schedule__r.Last_Payment_Date__c == null) {
                        IntLine.Interest_Start_Date__c = recipetItem.Payment_schedule__r.PaymentDueDate__c;
                    } else {
                        IntLine.Interest_Start_Date__c = recipetItem.Payment_schedule__r.Last_Payment_Date__c;
                    }
                    
                    IntLine.Interest_End_Date__c = todayDate;
                    IntLine.Interest_Percent__c = recipetItem.Payment_schedule__r.Interest_Percent__c;
                    
                    IntLine.Payment_Schedule__c = recipetItem.Payment_Schedule__c;
                    
                    IntLine.Booking__c = recipetItem.Booking__c;
                    IntLine.Principal_Amount__c = recipetItem.Received_Amount__c;
                    
                    IntAmtLiEs.add(IntLine);
                }
            }
            
            // Update with latest receipt date
            pay.Last_Payment_Date__c = latestReceiptDate;
            pay.Last_Payment_Time__c = System.now();
        }
        
        if (!IntAmtLiEs.isEmpty()) {
            insert IntAmtLiEs;
        }
        
        update payList1;
    }
}