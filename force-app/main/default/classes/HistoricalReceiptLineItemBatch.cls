/**
 * HistoricalReceiptLineItemBatch
 *
 * One-time / on-demand migration batch that generates Receipt_Line_Item__c (and Refund__c
 * for TDS Refund) records for HISTORICAL receipts that were uploaded as header-only records
 * via Data Loader.
 *
 * Live receipts are created through the Aura UI -> ReceiptController.insertReceiptLineItems,
 * which allocates the entered amount across the booking's Payment_Schedule__c records and
 * inserts the line items. For historical bookings the client could only supply receipt-level
 * data, so receipts were loaded with the line-item values parked on upload fields
 * (Payment_Type_Data_Upload__c, Amount_Received__c, Cheque_Date_Data_Upload__c, ...) and
 * flagged with Data_Upload__c = true.
 *
 * This batch reads those receipts ONE BOOKING AT A TIME (run with scope size 1), allocates
 * each receipt's amount across the booking's schedules exactly like the UI does, and links
 * the generated line items to the already-existing Receipt__c. Because the schedule
 * Pending_* fields are formulas over roll-up summaries of the line items (and Refund__c),
 * the schedules adjust automatically once the line items are inserted - we never write to the
 * schedules directly. Roll-ups recalculate synchronously within the transaction, so each
 * receipt is inserted before the next receipt re-queries the (now adjusted) schedules.
 *
 * Idempotency: every processed receipt is stamped Line_Items_Created__c = true, so re-running
 * the batch is a no-op for already-processed receipts.
 *
 * Invoke:  Database.executeBatch(new HistoricalReceiptLineItemBatch(), 1);
 */
global without sharing class HistoricalReceiptLineItemBatch implements Database.Batchable<SObject>, Database.Stateful {

    // Principal payment types allocate against Pending_Amount_Without_Tds__c (mirrors ReceiptController).
    private static final Set<String> PRINCIPAL_TYPES = new Set<String>{
        'Booking Amount', 'Flat Amount', 'Villa Amount', 'Plot Amount', 'Row House Amount'
    };

    // Valid Receipt_Line_Item__c.Bank_Name__c picklist values (Receipt.Bank_Name__c is free text).
    private static final Set<String> VALID_BANKS = new Set<String>{
        'SBI', 'HDFC', 'ICICI', 'AXIS', 'IDBI', 'KOTAK', 'TATA', 'UNION'
    };

    // Valid Receipt_Line_Item__c.Mode_of_Payment__c picklist values (restricted).
    private static final Set<String> VALID_MODES = new Set<String>{
        'Cheque', 'Net Banking', 'RTGS', 'IMPS', 'DD', 'UPI', 'Credit Card', 'Debit Card'
    };

    // Stateful counters for the finish() summary log.
    private Integer receiptsProcessed = 0;
    private Integer bookingsFailed = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Finance_Lead__c, Project_Type__c
            FROM Booking__c
            WHERE Id IN (
                SELECT Booking__c FROM Receipt__c
                WHERE Data_Upload__c = true AND Line_Items_Created__c = false
            )
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Booking__c> scope) {
        for (Booking__c bk : scope) {
            try {
                processBooking(bk);
            } catch (Exception e) {
                // Isolate failures so one bad booking does not abort the whole batch.
                bookingsFailed++;
                System.debug(LoggingLevel.ERROR,
                    'HistoricalReceiptLineItemBatch failed for booking ' + bk.Id + ': '
                    + e.getMessage() + '\n' + e.getStackTraceString());
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'HistoricalReceiptLineItemBatch finished. Receipts processed: ' + receiptsProcessed
            + ', bookings failed: ' + bookingsFailed);
    }

    // ---------------------------------------------------------------------------------------
    // Per-booking processing
    // ---------------------------------------------------------------------------------------
    private void processBooking(Booking__c bk) {
        List<Receipt__c> receipts = [
            SELECT Id, Booking__c, Receipt_Date__c, Type__c, CreatedDate,
                   Payment_Type_Data_Upload__c, Amount_Received__c, Cheque_Date_Data_Upload__c,
                   Bank_Name__c, Branch__c, Mode_Of_Payment__c, Drawn_On__c,
                   Cheque_no_Transaction_Number__c
            FROM Receipt__c
            WHERE Booking__c = :bk.Id AND Data_Upload__c = true AND Line_Items_Created__c = false
            ORDER BY CreatedDate ASC
        ];
        if (receipts.isEmpty()) {
            return;
        }

        // Order by payment-type dependency, NOT by date. The TDS lifecycle is:
        //   Principal -> TDS from Bank -> TDS Refund -> TDS Challan Entry
        // TDS from Bank zeroes Pending_Tds_Amount__c; the TDS Refund (often dateless on
        // upload) re-opens it via +Total_TDS_Refund_Issued__c, and only then can the
        // TDS Challan Entry land on the same schedule. Date ordering (with the dateless
        // refund sorted last) would run Challan before Refund and mis-allocate it.
        List<ReceiptOrder> ordered = new List<ReceiptOrder>();
        for (Receipt__c rec : receipts) {
            ordered.add(new ReceiptOrder(rec, typeRank(rec.Payment_Type_Data_Upload__c)));
        }
        ordered.sort();

        List<Receipt__c> processed = new List<Receipt__c>();
        for (ReceiptOrder ro : ordered) {
            // Inserts this receipt's line items / refunds before the next receipt re-queries
            // the schedules, so the roll-up driven pending amounts are already adjusted.
            allocateReceipt(bk, ro.rec);
            ro.rec.Line_Items_Created__c = true;
            processed.add(ro.rec);
            receiptsProcessed++;
        }
        update processed;
    }

    // Dependency-aware processing order within a booking. Lower rank is processed first.
    private static Integer typeRank(String rawType) {
        String payType = (rawType == null) ? null : rawType.trim();
        if (String.isBlank(payType)) {
            return 99;
        }
        if (PRINCIPAL_TYPES.contains(payType)) {
            return 1;
        }
        if (payType == 'TDS from Bank') {
            return 2;
        }
        if (payType == 'TDS Refund') {
            return 3;   // must precede TDS Challan Entry so Pending_Tds_Amount__c re-opens
        }
        if (payType == 'TDS Challan Entry' || payType == 'TDS') {
            return 4;
        }
        if (payType == 'Interest') {
            return 5;
        }
        return 99;
    }

    // Sortable wrapper: primary key = payment-type rank, secondary = receipt date
    // (nulls last), tertiary = CreatedDate, so installments of the same type stay in
    // chronological order.
    private class ReceiptOrder implements Comparable {
        Receipt__c rec;
        Integer rank;
        Date rdate;
        Datetime created;

        ReceiptOrder(Receipt__c rec, Integer rank) {
            this.rec = rec;
            this.rank = rank;
            this.rdate = rec.Receipt_Date__c;
            this.created = rec.CreatedDate;
        }

        public Integer compareTo(Object o) {
            ReceiptOrder other = (ReceiptOrder) o;
            if (rank != other.rank) {
                return rank < other.rank ? -1 : 1;
            }
            if (rdate != other.rdate) {
                if (rdate == null) return 1;
                if (other.rdate == null) return -1;
                return rdate < other.rdate ? -1 : 1;
            }
            if (created != null && other.created != null && created != other.created) {
                return created < other.created ? -1 : 1;
            }
            return 0;
        }
    }

    private void allocateReceipt(Booking__c bk, Receipt__c rec) {
        String payType = (rec.Payment_Type_Data_Upload__c == null)
            ? null : rec.Payment_Type_Data_Upload__c.trim();
        if (String.isBlank(payType) || rec.Amount_Received__c == null) {
            return;
        }
        // Uploads carry TDS Refund as a negative amount; the magnitude is what we refund.
        Decimal amount = Math.abs(rec.Amount_Received__c);
        if (amount <= 0) {
            return;
        }

        if (PRINCIPAL_TYPES.contains(payType)) {
            allocatePrincipal(bk, rec, payType, amount);
        } else if (payType == 'TDS from Bank') {
            allocateTds(bk, rec, 'TDS from Bank', 'TDS from Bank', amount);
        } else if (payType == 'TDS Challan Entry' || payType == 'TDS') {
            // Legacy 'TDS' behaves like 'TDS Challan Entry' (matches ReceiptController).
            allocateTds(bk, rec, 'Against TDS', payType, amount);
        } else if (payType == 'Interest') {
            allocateInterest(bk, rec, amount);
        } else if (payType == 'TDS Refund') {
            allocateTdsRefund(bk, rec, amount);
        } else {
            System.debug(LoggingLevel.WARN,
                'HistoricalReceiptLineItemBatch: unhandled Payment Type "' + payType
                + '" on receipt ' + rec.Id);
        }
    }

    // ---------------------------------------------------------------------------------------
    // Allocation branches (ported from ReceiptController.insertReceiptLineItems)
    // ---------------------------------------------------------------------------------------

    // Principal: split across schedules by Pending_Amount_Without_Tds__c; overflow -> last schedule.
    private void allocatePrincipal(Booking__c bk, Receipt__c rec, String payType, Decimal amount) {
        List<Payment_Schedule__c> payList = pendingSchedules(bk.Id);
        if (payList.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                'HistoricalReceiptLineItemBatch: no pending schedule for principal on receipt ' + rec.Id);
            return;
        }

        List<Receipt_Line_Item__c> toCreate = new List<Receipt_Line_Item__c>();
        Decimal remaining = amount;
        for (Payment_Schedule__c ps : payList) {
            if (remaining <= 0) {
                break;
            }
            Decimal pending = ps.Pending_Amount_Without_Tds__c;
            if (pending != null && pending > 0) {
                Decimal amt = Math.min(pending, remaining);
                remaining -= amt;
                toCreate.add(buildLine(bk, rec, ps.Id, payType, payType, amt));
            }
        }
        if (remaining > 0) {
            // Historical fidelity: preserve the full uploaded amount on the last schedule.
            toCreate.add(buildLine(bk, rec, payList[payList.size() - 1].Id, payType, payType, remaining));
        }
        if (!toCreate.isEmpty()) {
            insert toCreate;
        }
    }

    // TDS from Bank / TDS Challan Entry: split across schedules by Pending_Tds_Amount__c.
    private void allocateTds(Booking__c bk, Receipt__c rec, String lineName,
                             String stampedType, Decimal amount) {
        List<Payment_Schedule__c> payList = pendingSchedules(bk.Id);
        if (payList.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                'HistoricalReceiptLineItemBatch: no pending schedule for TDS on receipt ' + rec.Id);
            return;
        }

        List<Receipt_Line_Item__c> toCreate = new List<Receipt_Line_Item__c>();
        Decimal remaining = amount;
        for (Payment_Schedule__c ps : payList) {
            if (remaining <= 0) {
                break;
            }
            Decimal pending = ps.Pending_Tds_Amount__c;
            if (pending != null && pending > 0) {
                Decimal amt = Math.min(pending, remaining);
                remaining -= amt;
                toCreate.add(buildLine(bk, rec, ps.Id, lineName, stampedType, amt));
            }
        }
        if (remaining > 0) {
            toCreate.add(buildLine(bk, rec, payList[payList.size() - 1].Id, lineName, stampedType, remaining));
        }
        if (!toCreate.isEmpty()) {
            insert toCreate;
        }
    }

    // Interest: split across schedules by Interest_Pending_Amount__c; overflow -> last schedule.
    private void allocateInterest(Booking__c bk, Receipt__c rec, Decimal amount) {
        List<Payment_Schedule__c> payList = pendingSchedules(bk.Id);
        if (payList.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                'HistoricalReceiptLineItemBatch: no pending schedule for interest on receipt ' + rec.Id);
            return;
        }

        List<Receipt_Line_Item__c> toCreate = new List<Receipt_Line_Item__c>();
        Decimal remaining = amount;
        for (Payment_Schedule__c ps : payList) {
            if (remaining <= 0) {
                break;
            }
            Decimal pending = ps.Interest_Pending_Amount__c;
            if (pending != null && pending > 0) {
                Decimal amt = Math.min(pending, remaining);
                remaining -= amt;
                toCreate.add(buildLine(bk, rec, ps.Id, 'Against Interest', 'Interest', amt));
            }
        }
        if (remaining > 0) {
            toCreate.add(buildLine(bk, rec, payList[payList.size() - 1].Id, 'Against Interest', 'Interest', remaining));
        }
        if (!toCreate.isEmpty()) {
            insert toCreate;
        }
    }

    // TDS Refund: creates Refund__c (not line items), split by Pending_TDS_Refund__c.
    private void allocateTdsRefund(Booking__c bk, Receipt__c rec, Decimal amount) {
        List<Payment_Schedule__c> refundSchedules = [
            SELECT Id, S_No__c, Pending_TDS_Refund__c
            FROM Payment_Schedule__c
            WHERE Booking__c = :bk.Id AND Pending_TDS_Refund__c > 0
            ORDER BY S_No__c ASC
        ];
        if (refundSchedules.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                'HistoricalReceiptLineItemBatch: no TDS-refund-eligible schedule on receipt ' + rec.Id);
            return;
        }

        Date refundDate = (rec.Receipt_Date__c != null) ? rec.Receipt_Date__c : Date.today();
        List<Refund__c> toCreate = new List<Refund__c>();
        Decimal remaining = amount;
        for (Payment_Schedule__c ps : refundSchedules) {
            if (remaining <= 0) {
                break;
            }
            Decimal amt = Math.min(ps.Pending_TDS_Refund__c, remaining);
            remaining -= amt;
            toCreate.add(buildRefund(bk, rec, ps.Id, refundDate, amt));
        }
        if (remaining > 0) {
            toCreate.add(buildRefund(bk, rec, refundSchedules[refundSchedules.size() - 1].Id, refundDate, remaining));
        }
        if (!toCreate.isEmpty()) {
            insert toCreate;
        }
    }

    // ---------------------------------------------------------------------------------------
    // Builders / helpers
    // ---------------------------------------------------------------------------------------

    private List<Payment_Schedule__c> pendingSchedules(Id bookingId) {
        return [
            SELECT Id, S_No__c, Pending_Amount_Without_Tds__c, Pending_Tds_Amount__c,
                   Interest_Pending_Amount__c
            FROM Payment_Schedule__c
            WHERE Booking__c = :bookingId AND Pending_Amount__c > 0
            ORDER BY S_No__c ASC
        ];
    }

    private Receipt_Line_Item__c buildLine(Booking__c bk, Receipt__c rec, Id scheduleId,
                                           String lineName, String paymentType, Decimal amt) {
        Receipt_Line_Item__c rli = new Receipt_Line_Item__c();
        rli.Receipt__c = rec.Id;            // header already exists - do NOT create a new Receipt
        rli.Booking__c = bk.Id;
        rli.Payment_Schedule__c = scheduleId;
        rli.Name = lineName;
        rli.Payment_Type__c = paymentType;
        rli.Received_Amount__c = amt;
        rli.Amount__c = amt;
        rli.Approval_Status_Picklist__c = 'Approved';   // required so Received_Amount1__c rolls it up
        rli.Data_Upload__c = true;
        rli.Bank_Name__c = normalizeBank(rec.Bank_Name__c);
        rli.Branch__c = rec.Branch__c;
        rli.Mode_of_Payment__c = normalizeMode(rec.Mode_Of_Payment__c);
        rli.Drawn_On__c = rec.Drawn_On__c;
        rli.Cheque_Date__c = rec.Cheque_Date_Data_Upload__c;
        rli.Cheque_no_Transaction_Number__c = rec.Cheque_no_Transaction_Number__c;
        return rli;
    }

    private Refund__c buildRefund(Booking__c bk, Receipt__c rec, Id scheduleId, Date refundDate, Decimal amt) {
        Refund__c r = new Refund__c();
        r.Booking__c = bk.Id;
        r.Refund_Type__c = 'TDS Refund';
        r.Refund_Amount__c = amt;
        r.Refund_Date__c = refundDate;
        r.Payment_Schedule__c = scheduleId;
        r.Payment_Mode__c = normalizeMode(rec.Mode_Of_Payment__c);
        r.Bank_Name__c = rec.Bank_Name__c;
        r.Branch_Name__c = rec.Branch__c;
        r.Transaction_ChequeNo__c = rec.Cheque_no_Transaction_Number__c;
        r.Drawn_On__c = rec.Drawn_On__c;
        r.Cheque_Date__c = rec.Cheque_Date_Data_Upload__c;
        return r;
    }

    // Receipt.Bank_Name__c is free text; RLI.Bank_Name__c is a picklist. Map known values,
    // otherwise leave null rather than fail the insert.
    private String normalizeBank(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        String v = value.trim().toUpperCase();
        return VALID_BANKS.contains(v) ? v : null;
    }

    // Receipt.Mode_Of_Payment__c uses {Cheque, NetBanking}; RLI/Refund use {Cheque, Net Banking, ...}.
    private String normalizeMode(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        String v = value.trim();
        if (v.equalsIgnoreCase('NetBanking') || v.equalsIgnoreCase('Net Banking')) {
            return 'Net Banking';
        }
        for (String mode : VALID_MODES) {
            if (mode.equalsIgnoreCase(v)) {
                return mode;
            }
        }
        return null;
    }
}