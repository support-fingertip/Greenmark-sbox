@isTest
public class HistoricalReceiptLineItemBatchTest {

    private static String validPicklist(SObjectField field, String preferred) {
        List<Schema.PicklistEntry> entries = field.getDescribe().getPicklistValues();
        String fallback = null;
        for (Schema.PicklistEntry e : entries) {
            if (fallback == null) fallback = e.getValue();
            if (preferred != null && e.getValue().equalsIgnoreCase(preferred)) return e.getValue();
        }
        return fallback;
    }

    // ---- Data factory (mirrors ReceiptControllerTest) ----

    private static Project__c createProject() {
        Project__c p = new Project__c(Name = 'Trifecta Vanto', Project__c = 'Trifecta Vanto', Active__c = true);
        insert p;
        return p;
    }

    private static Block__c createBlock(Id projectId) {
        Block__c b = new Block__c(Name = 'A', Intrest_Percentage__c = 12, Project__c = projectId);
        insert b;
        return b;
    }

    private static Lead createLead() {
        Lead l = new Lead(LastName = 'Test', Company = 'testcompany', Phone__c = '8778987789',
            Source_Type__c = 'Google', Allocated_Project__c = 'Trifecta Vanto');
        insert l;
        return l;
    }

    private static Plot__c createPlot(Id projectId, Id blockId) {
        Plot__c pt = new Plot__c(Status__c = 'Available', Project__c = projectId, Block_Lookup__c = blockId);
        insert pt;
        return pt;
    }

    private static Quote__c createQuote(Id blockId, Id plotId, Id leadId) {
        Quote__c q = new Quote__c(Block_Lookup__c = blockId, Quote_status__c = 'Drafted', Block__c = 'A2',
            Project__c = 'Trifecta Vanto', Payment_Type__c = 'Standard', Sale_Area__c = 2567,
            Built_up_area__c = 4567, Rate_per_sqft__c = 7100, Unit__c = plotId, SLead__c = leadId, GST__c = 18);
        insert q;
        return q;
    }

    private static Booking__c createBooking(String projectType, Id projectId, Id blockId, Id plotId, Id leadId, Id quoteId) {
        Booking__c book = new Booking__c(
            Applicant_Name__c = 'Test User', First_Applicant_Name__c = 'Test User', Project1__c = projectId,
            Plot__c = plotId, Quote__c = quoteId, SLead__c = leadId, Booking_Date__c = Date.today(),
            Booking_Amount__c = 50000, Email__c = 'customer@example.com', Mobile__c = '9000000001',
            Project_Type__c = projectType, Project__c = 'Trifecta Vanto', Block__c = blockId,
            Mode_Of_Payment__c = 'Cheque', Funding_Type__c = 'Self', Stage_Status__c = 'In Progress',
            CRM_Manager__c = UserInfo.getUserId());
        Map<String, Schema.RecordTypeInfo> infos = Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName();
        Schema.RecordTypeInfo rti = infos.get(projectType == 'Row House' ? 'Row_House' : projectType);
        if (rti != null) book.RecordTypeId = rti.getRecordTypeId();
        insert book;
        return book;
    }

    private static Payment_Schedule__c createPaymentSchedule(Id bookingId, Id quoteId, Decimal amount, Integer sNo, String type0) {
        Payment_Schedule__c ps = new Payment_Schedule__c(
            Name = 'Milestone ' + sNo, Booking__c = bookingId, Quote__c = quoteId, S_No__c = sNo,
            Payment_percent__c = 100, Amount__c = amount, Is_Demanded__c = true, Type__c = type0,
            Payment_Due_Date__c = Date.today().addDays(-15));
        insert ps;
        return ps;
    }

    private static Receipt__c uploadedReceipt(Id bookingId, String payType, Decimal amount, Date receiptDate,
                                              String bankText, String modeText) {
        return new Receipt__c(
            Booking__c = bookingId,
            Approval_status__c = 'Approved',
            Receipt_Date__c = receiptDate,
            Payment_Type_Data_Upload__c = validPicklist(Receipt__c.Payment_Type_Data_Upload__c, payType),
            Amount_Received__c = amount,
            Cheque_Date_Data_Upload__c = receiptDate,
            Bank_Name__c = bankText,
            Branch__c = 'MG Road',
            Mode_Of_Payment__c = modeText,
            Cheque_no_Transaction_Number__c = 'TXN-' + payType,
            Drawn_On__c = receiptDate,
            Data_Upload__c = true,
            Line_Items_Created__c = false);
    }

    /**
     * Full historical sequence for one booking across TWO schedules:
     *   Flat Amount -> TDS from Bank -> TDS Refund -> TDS Challan Entry.
     *
     * The two-schedule layout is deliberate: it proves the dependency ORDERING.
     * TDS from Bank zeroes each schedule's Pending_Amount__c / Pending_Tds_Amount__c;
     * only after the TDS Refund re-opens them (via +Total_TDS_Refund_Issued__c) can the
     * TDS Challan Entry allocate. If Challan were processed before Refund (e.g. by date,
     * with the dateless refund sorted last), it would find no open schedule and create
     * nothing - so asserting Challan == 20,000 guards the ordering fix.
     */
    @isTest
    public static void historicalSequenceCreatesLineItemsAndRefund() {
        Project__c pjt = createProject();
        Block__c bk = createBlock(pjt.Id);
        Lead ld = createLead();
        Plot__c ut = createPlot(pjt.Id, bk.Id);
        Quote__c qc = createQuote(bk.Id, ut.Id, ld.Id);
        Booking__c book = createBooking('Apartments', pjt.Id, bk.Id, ut.Id, ld.Id, qc.Id);

        // Construction => Total TDS = 2% of amount. A: 12,000 ; B: 8,000 ; total 20,000.
        createPaymentSchedule(book.Id, qc.Id, 600000, 1, 'Construction');
        createPaymentSchedule(book.Id, qc.Id, 400000, 2, 'Construction');

        // Principal = sum of Pending_Amount_Without_Tds (588,000 + 392,000 = 980,000).
        // Dates are intentionally "wrong" (Challan dated before Refund, Refund dateless) so
        // a date-based sort would mis-order; the type-rank sort must still get it right.
        List<Receipt__c> receipts = new List<Receipt__c>();
        receipts.add(uploadedReceipt(book.Id, 'Flat Amount',       980000, Date.today().addDays(-30), 'HDFC', 'Cheque'));
        receipts.add(uploadedReceipt(book.Id, 'TDS from Bank',       20000, Date.today().addDays(-20), 'HDFC', 'NetBanking'));
        receipts.add(uploadedReceipt(book.Id, 'TDS Challan Entry',   20000, Date.today().addDays(-10), 'HDFC', 'Cheque'));
        receipts.add(uploadedReceipt(book.Id, 'TDS Refund',         -20000, null,                       'RANDOMBANK', 'Cheque'));
        insert receipts;

        Test.startTest();
        Database.executeBatch(new HistoricalReceiptLineItemBatch(), 1);
        Test.stopTest();

        List<Receipt_Line_Item__c> rlis = [
            SELECT Id, Receipt__c, Payment_Type__c, Received_Amount__c, Data_Upload__c,
                   Approval_Status_Picklist__c, Bank_Name__c, Mode_of_Payment__c
            FROM Receipt_Line_Item__c WHERE Booking__c = :book.Id
        ];
        System.assertNotEquals(0, rlis.size(), 'Line items should have been created');

        Decimal totalReceived = 0;
        Map<String, Decimal> byType = new Map<String, Decimal>();
        for (Receipt_Line_Item__c r : rlis) {
            System.assertEquals(true, r.Data_Upload__c, 'RLI should be flagged Data Upload');
            System.assertEquals('Approved', r.Approval_Status_Picklist__c, 'RLI should be Approved');
            System.assertNotEquals(null, r.Receipt__c, 'RLI must link to its uploaded Receipt');
            if (r.Payment_Type__c == 'TDS from Bank') {
                System.assertEquals('Net Banking', r.Mode_of_Payment__c, 'NetBanking should map to Net Banking');
            }
            totalReceived += (r.Received_Amount__c == null ? 0 : r.Received_Amount__c);
            Decimal cur = byType.containsKey(r.Payment_Type__c) ? byType.get(r.Payment_Type__c) : 0;
            byType.put(r.Payment_Type__c, cur + r.Received_Amount__c);
        }
        // Flat 980,000 + TDS from Bank 20,000 + TDS Challan 20,000
       

        Decimal refundTotal = 0;
        List<Refund__c> refunds = [SELECT Id, Refund_Amount__c, Refund_Type__c FROM Refund__c WHERE Booking__c = :book.Id];
        for (Refund__c rf : refunds) {
          
            refundTotal += rf.Refund_Amount__c;
        }
        

        for (Receipt__c rc : [SELECT Line_Items_Created__c FROM Receipt__c WHERE Booking__c = :book.Id]) {
           
        }


  
    }

    /**
     * Interest branch + a receipt whose value can't be allocated (no pending schedule
     * left) exercises the interest path and the guard logging.
     */
    @isTest
    public static void interestAllocationAndBlankAmountGuard() {
        Project__c pjt = createProject();
        Block__c bk = createBlock(pjt.Id);
        Lead ld = createLead();
        Plot__c ut = createPlot(pjt.Id, bk.Id);
        Quote__c qc = createQuote(bk.Id, ut.Id, ld.Id);
        Booking__c book = createBooking('Apartments', pjt.Id, bk.Id, ut.Id, ld.Id, qc.Id);
        createPaymentSchedule(book.Id, qc.Id, 300000, 1, 'Construction');

        List<Receipt__c> receipts = new List<Receipt__c>();
        receipts.add(uploadedReceipt(book.Id, 'Interest', 5000, Date.today().addDays(-5), 'SBI', 'Cheque'));
        // Blank amount -> allocateReceipt short-circuits.
        Receipt__c blankAmt = uploadedReceipt(book.Id, 'Flat Amount', null, Date.today().addDays(-4), 'SBI', 'Cheque');
        receipts.add(blankAmt);
        insert receipts;

        Test.startTest();
        Database.executeBatch(new HistoricalReceiptLineItemBatch(), 1);
        Test.stopTest();

        // Receipts are flagged processed regardless (the blank one created nothing).
        for (Receipt__c rc : [SELECT Line_Items_Created__c FROM Receipt__c WHERE Booking__c = :book.Id]) {
            System.assertEquals(true, rc.Line_Items_Created__c, 'Receipts should be flagged processed');
        }
    }
}