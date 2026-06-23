@IsTest
public class TestDataFactory {

    // ────────────────── Project / Block / Lead / Plot / Quote ──────────────────

    public static Project__c createProject() {
        Project__c p = new Project__c(
            Name        = 'Trifecta Vanto',
            Project__c  = 'Trifecta Vanto',
            Active__c   = true
        );
        insert p;
        return p;
    }

    public static Block__c createBlock(Id projectId) {
        Block__c b = new Block__c(
            Name                  = 'A',
            Intrest_Percentage__c = 12,
            Project__c            = projectId
        );
        insert b;
        return b;
    }

    public static Lead createLead() {
        Lead l = new Lead(
            LastName             = 'Test',
            Company              = 'testcompany',
            Phone__c             = '8778987789',
            Source_Type__c       = 'Google',
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert l;
        return l;
    }

    public static Plot__c createPlot(Id projectId) {
        Plot__c pt = new Plot__c(
            Status__c  = 'Available',
            Project__c = projectId
        );
        insert pt;
        return pt;
    }

    public static Plot__c createPlot(Id projectId, Id blockId) {
        Plot__c pt = new Plot__c(
            Status__c        = 'Available',
            Project__c       = projectId,
            Block_Lookup__c  = blockId
        );
        insert pt;
        return pt;
    }

    public static Quote__c createQuote(Id blockId, Id plotId, Id leadId) {
        Quote__c q = new Quote__c(
            Block_Lookup__c  = blockId,
            Quote_status__c  = 'Drafted',
            Project__c       = 'Trifecta Vanto',
            Payment_Type__c  = 'Standard',
            Sale_Area__c     = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100,
            Unit__c          = plotId,
            SLead__c         = leadId
        );
        insert q;
        return q;
    }

    // ────────────────── Booking ──────────────────

    /** projectType must be one of: 'Apartments', 'Villas', 'Plots', 'Row House'. */
    public static Booking__c createBooking(String projectType) {
        Project__c pjt = createProject();
        Block__c   bc  = createBlock(pjt.Id);
        Lead       ld  = createLead();
        // Link the plot to the block so the Booking.Block_Id__c formula
        // (CASESAFEID(Plot__r.Block_Lookup__c)) resolves.
        Plot__c    ut  = createPlot(pjt.Id, bc.Id);
        Quote__c   qc  = createQuote(bc.Id, ut.Id, ld.Id);
        return createBooking(projectType, pjt, bc, ld, ut, qc);
    }

    public static Booking__c createBooking(
        String projectType,
        Project__c pjt, Block__c bc, Lead ld, Plot__c ut, Quote__c qc
    ) {
        Booking__c book = new Booking__c(
            Applicant_Name__c       = 'Test User',
            First_Applicant_Name__c = 'Test User',
            Project1__c             = pjt.Id,
            Plot__c                 = ut.Id,
            Quote__c                = qc.Id,
            SLead__c                = ld.Id,
            Booking_Date__c         = Date.today(),
            Booking_Amount__c       = 50000,
            Email__c                = 'customer@example.com',
            Mobile__c               = '9000000001',
            Project_Type__c         = projectType,
            Project__c              = 'Trifecta Vanto',
            // Block_Id__c is a formula (CASESAFEID(Plot__r.Block_Lookup__c)) and
            // cannot be set directly. Use the writable Block__c lookup instead.
            Block__c                = bc.Id,
            Mode_Of_Payment__c      = 'Cheque',
            Funding_Type__c         = 'Self',
            Stage_Status__c         = 'In Progress',
            CRM_Manager__c = UserInfo.getUserId()
        );
        Id rtId = getBookingRecordTypeId(recordTypeDevNameFor(projectType));
        if (rtId != null) book.RecordTypeId = rtId;
        insert book;
        return book;
    }

    // ────────────────── Payment Schedules / Master Payment Schedule ──────────────────

    public static List<Payment_Schedule__c> createPaymentSchedules(Id bookingId, Integer count) {
        List<Payment_Schedule__c> list0 = new List<Payment_Schedule__c>();
        for (Integer i = 1; i <= count; i++) {
            list0.add(new Payment_Schedule__c(
                Name               = 'Milestone ' + i,
                Booking__c         = bookingId,
                S_No__c            = i,
                Payment_percent__c = (count == 2) ? 100 : (100.0 / count),
                Is_Demanded__c     = false
            ));
        }
        insert list0;
        return list0;
    }

    public static Master_Payment_Schedule__c createMasterPaymentSchedule(Id blockId) {
        Master_Payment_Schedule__c m = new Master_Payment_Schedule__c(
            Name               = 'Master Milestone 1',
            Block__c           = blockId,
            S_No__c            = 1,
            Payment_Percent__c = 10
        );
        insert m;
        return m;
    }

    // ────────────────── Receipt / Receipt Line Item / Demand ──────────────────

    public static Receipt__c createReceipt(Id bookingId) {
        Receipt__c r = new Receipt__c(
            Booking__c       = bookingId,
            Receipt_Date__c  = Date.today(),
            Amount_Received__c = 10000
        );
        insert r;
        return r;
    }

    public static Receipt_Line_Item__c createReceiptLineItem(Id receiptId, Id psId, Id bookingId) {
        Receipt_Line_Item__c rli = new Receipt_Line_Item__c(
            Booking__c                   = bookingId,
            Receipt__c                   = receiptId,
            Payment_Schedule__c          = psId,
            Name                         = 'Flat Amount',
            Payment_Type__c              = 'Flat Amount',
            Received_Amount__c           = 5000,
            Amount__c                    = 5000,
            Approval_Status_Picklist__c  = 'Approved'
        );
        insert rli;
        return rli;
    }

    public static Demand_Raised__c createDemand(Id bookingId, Id psId) {
        Demand_Raised__c d = new Demand_Raised__c(
            Booking__c           = bookingId,
            Payment_schedule__c  = psId,
            Demand_Name__c       = 'Test Milestone',
            Demanded_Date__c     = Date.today(),
            Due_Date__c          = Date.today().addDays(30),
            Grand_Total__c       = 1000,
            Grand_Total_in_Words__c = 'Rupees One Thousand Only'
        );
        insert d;
        return d;
    }

    // ────────────────── Record type helpers ──────────────────

    public static Id getBookingRecordTypeId(String devName) {
        Map<String, Schema.RecordTypeInfo> infos =
            Schema.SObjectType.Booking__c.getRecordTypeInfosByDeveloperName();
        Schema.RecordTypeInfo info = infos.get(devName);
        return info == null ? null : info.getRecordTypeId();
    }

    /** Map project type picklist value to Booking__c record type DeveloperName. */
    public static String recordTypeDevNameFor(String projectType) {
        if (projectType == 'Villas')     return 'Villas';
        if (projectType == 'Apartments') return 'Apartments';
        if (projectType == 'Plots')      return 'Plots';
        if (projectType == 'Row House')  return 'Row_House';
        return null;
    }
}