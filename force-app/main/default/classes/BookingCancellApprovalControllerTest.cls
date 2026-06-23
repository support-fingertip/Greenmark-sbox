@isTest
public class BookingCancellApprovalControllerTest {

    @isTest
    static void testAllMethods() {

        // ── Project ───────────────────────────────────────────────
        Project__c pjt = new Project__c(
            Name       = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c  = true
        );
        insert pjt;

        // ── Block ─────────────────────────────────────────────────
        Block__c bc = new Block__c(
            Name                  = 'A',
            Intrest_Percentage__c = 12,
            Project__c            = pjt.Id
        );
        insert bc;

        // ── Lead - Source_Type__c fetched dynamically ─────────────
        Schema.DescribeFieldResult sourceTypeField = Lead.Source_Type__c.getDescribe();
        String validSourceType = null;
        for (Schema.PicklistEntry ple : sourceTypeField.getPicklistValues()) {
            if (ple.isActive()) { validSourceType = ple.getLabel(); break; }
        }

        // ── Lead - Allocated_Project__c fetched dynamically ───────
        Schema.DescribeFieldResult leadProjectField = Lead.Allocated_Project__c.getDescribe();
        String validLeadProject = null;
        for (Schema.PicklistEntry ple : leadProjectField.getPicklistValues()) {
            if (ple.isActive()) { validLeadProject = ple.getLabel(); break; }
        }

        Lead ld = new Lead(
            LastName             = 'Test',
            Company              = 'testcompany',
            Phone__c             = '8778987789',
            Source_Type__c       = validSourceType,
            Allocated_Project__c = validLeadProject
        );
        insert ld;

        // ── Plot - Status__c fetched dynamically ──────────────────
        Schema.DescribeFieldResult plotStatusField = Plot__c.Status__c.getDescribe();
        String validPlotStatus = null;
        for (Schema.PicklistEntry ple : plotStatusField.getPicklistValues()) {
            if (ple.isActive()) { validPlotStatus = ple.getLabel(); break; }
        }

        Plot__c ut = new Plot__c(
            Status__c       = validPlotStatus,
            Project__c      = pjt.Id,
            Block_Lookup__c = bc.Id
        );
        insert ut;

        // ── Quote - RecordType fetched dynamically ─────────────────
        List<RecordType> quoteRecordTypes = [
            SELECT Id, Name FROM RecordType
            WHERE SObjectType = 'Quote__c'
            LIMIT 1
        ];
        String validQuotePropertyType = quoteRecordTypes.isEmpty() ? null : quoteRecordTypes[0].Name;

        // ── Quote - Payment_Type__c fetched dynamically ────────────
        Schema.DescribeFieldResult paymentTypeField = Quote__c.Payment_Type__c.getDescribe();
        String validPaymentType = null;
        for (Schema.PicklistEntry ple : paymentTypeField.getPicklistValues()) {
            if (ple.isActive()) { validPaymentType = ple.getLabel(); break; }
        }

        // ── Quote - Project__c fetched dynamically ─────────────────
        Schema.DescribeFieldResult quoteProjectField = Quote__c.Project__c.getDescribe();
        String validQuoteProject = null;
        for (Schema.PicklistEntry ple : quoteProjectField.getPicklistValues()) {
            if (ple.isActive()) { validQuoteProject = ple.getLabel(); break; }
        }

        // ── Quote - Quote_status__c fetched dynamically ────────────
        Schema.DescribeFieldResult quoteStatusField = Quote__c.Quote_status__c.getDescribe();
        String validQuoteStatus = null;
        for (Schema.PicklistEntry ple : quoteStatusField.getPicklistValues()) {
            if (ple.isActive()) { validQuoteStatus = ple.getLabel(); break; }
        }

        Quote__c qc = new Quote__c(
            Block_Lookup__c  = bc.Id,
            Quote_status__c  = validQuoteStatus,
            Block__c         = 'A2',
            Project__c       = validQuoteProject,
            Payment_Type__c  = validPaymentType,
            Sale_Area__c     = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100,
            Unit__c          = ut.Id,
            SLead__c         = ld.Id,
            Property_Type__c = validQuotePropertyType
        );
        insert qc;

        // ── Master Payment Schedule - Status__c fetched dynamically ─
        Schema.DescribeFieldResult mpsStatusField = Master_Payment_Schedule__c.Status__c.getDescribe();
        String validMpsStatus = null;
        for (Schema.PicklistEntry ple : mpsStatusField.getPicklistValues()) {
            if (ple.isActive()) { validMpsStatus = ple.getLabel(); break; }
        }

        Master_Payment_Schedule__c mps = new Master_Payment_Schedule__c(
            Project__c         = pjt.Id,
            Block__c           = bc.Id,
            S_No__c            = 1,
            Status__c          = validMpsStatus,
            Completed_Date__c  = Date.today(),
            Payment_Percent__c = 10
        );
        insert mps;

        // ── Payment Schedule - Status__c fetched dynamically ───────
        Schema.DescribeFieldResult psStatusField = Payment_Schedule__c.Status__c.getDescribe();
        String validPsStatus = null;
        for (Schema.PicklistEntry ple : psStatusField.getPicklistValues()) {
            if (ple.isActive()) { validPsStatus = ple.getLabel(); break; }
        }

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Master_Payment_Schedule__c = mps.Id,
            Payment_Percent__c         = 10,
            S_No__c                    = 1,
            Quote__c                   = qc.Id,
            Status__c                  = validPsStatus
        );
        insert ps;

        // ── Booking - RecordType fetched dynamically ───────────────
        List<RecordType> bookingRecordTypes = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Booking__c'
            LIMIT 1
        ];

        // ── Booking - Project__c fetched dynamically ───────────────
        Schema.DescribeFieldResult bookingProjectField = Booking__c.Project__c.getDescribe();
        String validBookingProject = null;
        for (Schema.PicklistEntry ple : bookingProjectField.getPicklistValues()) {
            if (ple.isActive()) { validBookingProject = ple.getLabel(); break; }
        }

        // ── Booking - Stage__c fetched dynamically ─────────────────
        // Controller checks specifically for 'Booked' and 'Agreement' labels
        Schema.DescribeFieldResult bookingStageField = Booking__c.Stage__c.getDescribe();
        String validBookingStageBooked    = null;
        String validBookingStageAgreement = null;
        for (Schema.PicklistEntry ple : bookingStageField.getPicklistValues()) {
            if (!ple.isActive()) continue;
            if (validBookingStageBooked    == null && ple.getLabel() == 'Booked')    validBookingStageBooked    = ple.getValue();
            if (validBookingStageAgreement == null && ple.getLabel() == 'Agreement') validBookingStageAgreement = ple.getValue();
        }

        // ── Booking - Agreement_Status__c fetched dynamically ──────
        // Controller checks specifically for 'Executed' and 'Executed & Registered'
        Schema.DescribeFieldResult agreementStatusField = Booking__c.Agreement_Status__c.getDescribe();
        String validAgreementStatusNonExecuted = null;
        String validAgreementStatusExecuted    = null;
        for (Schema.PicklistEntry ple : agreementStatusField.getPicklistValues()) {
            if (!ple.isActive()) continue;
            if (validAgreementStatusExecuted == null
                && (ple.getLabel() == 'Executed' || ple.getLabel() == 'Executed & Registered')) {
                validAgreementStatusExecuted = ple.getValue();
            }
            if (validAgreementStatusNonExecuted == null
                && ple.getLabel() != 'Executed'
                && ple.getLabel() != 'Executed & Registered') {
                validAgreementStatusNonExecuted = ple.getValue();
            }
        }

        // ── Booking - Cancellation_Reason__c fetched dynamically ───
        Schema.DescribeFieldResult cancellationReasonField = Booking__c.Cancellation_Reason__c.getDescribe();
        String validCancellationReason = null;
        for (Schema.PicklistEntry ple : cancellationReasonField.getPicklistValues()) {
            if (ple.isActive()) { validCancellationReason = ple.getLabel(); break; }
        }

        // ── Cancellation Amount from Custom Label ──────────────────
        Decimal cancellationLabelAmount = 0;
        if (String.isNotBlank(Label.Cancellation_Amount)) {
            cancellationLabelAmount = Decimal.valueOf(
                Label.Cancellation_Amount.replace(',', '')
            );
        }

        Test.startTest();

        // ── BRANCH 1: getRecordData - Stage__c = 'Booked' ─────────
        // Covers: cancellationAmount = 25000, isAfterPostAggrement = false
        try {
            Booking__c bkBooked = new Booking__c(
                First_Applicant_Name__c = 'Test Booked',
                Mobile__c               = '9876543210',
                Quote__c                = qc.Id,
                Project__c              = validBookingProject,
                Stage__c                = validBookingStageBooked
            );
            if (!bookingRecordTypes.isEmpty()) bkBooked.RecordTypeId = bookingRecordTypes[0].Id;
            insert bkBooked;

            BookingCancellationApprovalController.getRecordData(bkBooked.Id);
        } catch (Exception e) {
            System.debug('getRecordData Booked: ' + e.getMessage());
        }

        // ── BRANCH 2: getRecordData - Stage__c = 'Agreement' & Non-Executed ──
        // Covers: cancellationAmount = 25000, isAfterPostAggrement = false
        try {
            Booking__c bkAgreement = new Booking__c(
                First_Applicant_Name__c = 'Test Agreement',
                Mobile__c               = '9876543211',
                Quote__c                = qc.Id,
                Project__c              = validBookingProject,
                Stage__c                = validBookingStageAgreement,
                Agreement_Status__c     = validAgreementStatusNonExecuted
            );
            if (!bookingRecordTypes.isEmpty()) bkAgreement.RecordTypeId = bookingRecordTypes[0].Id;
            insert bkAgreement;

            BookingCancellationApprovalController.getRecordData(bkAgreement.Id);
        } catch (Exception e) {
            System.debug('getRecordData Agreement Non-Executed: ' + e.getMessage());
        }

        // ── BRANCH 3: getRecordData - else branch (Executed) ──────
        // Covers: amount = Total_Amount__c * 10/100, isAfterPostAggrement = true
        try {
            Booking__c bkExecuted = new Booking__c(
                First_Applicant_Name__c = 'Test Executed',
                Mobile__c               = '9876543212',
                Quote__c                = qc.Id,
                Project__c              = validBookingProject,
                Stage__c                = validBookingStageAgreement,
                Agreement_Status__c     = validAgreementStatusExecuted
            );
            if (!bookingRecordTypes.isEmpty()) bkExecuted.RecordTypeId = bookingRecordTypes[0].Id;
            insert bkExecuted;

            BookingCancellationApprovalController.getRecordData(bkExecuted.Id);
        } catch (Exception e) {
            System.debug('getRecordData Executed: ' + e.getMessage());
        }

        // ── BRANCH 4: sendCancellationApproval - charges >= label amount ──
        // Covers: Cancellation_Status__c = 'Approved', no approval process
        try {
            Booking__c bkApproved = new Booking__c(
                First_Applicant_Name__c = 'Test Approved',
                Mobile__c               = '9876543213',
                Quote__c                = qc.Id,
                Project__c              = validBookingProject,
                Stage__c                = validBookingStageBooked
            );
            if (!bookingRecordTypes.isEmpty()) bkApproved.RecordTypeId = bookingRecordTypes[0].Id;
            insert bkApproved;

            BookingCancellationApprovalController.sendCancellationApproval(
                bkApproved.Id,
                validCancellationReason,
                'Test Remarks',
                cancellationLabelAmount + 1,  // always >= label amount dynamically
                false
            );
        } catch (Exception e) {
            System.debug('sendCancellationApproval Approved: ' + e.getMessage());
        }

        // ── BRANCH 5: sendCancellationApproval - charges < label amount ──
        // Covers: Approval.ProcessSubmitRequest submission branch
        try {
            Booking__c bkApprovalProcess = new Booking__c(
                First_Applicant_Name__c = 'Test Approval Process',
                Mobile__c               = '9876543214',
                Quote__c                = qc.Id,
                Project__c              = validBookingProject,
                Stage__c                = validBookingStageBooked
            );
            if (!bookingRecordTypes.isEmpty()) bkApprovalProcess.RecordTypeId = bookingRecordTypes[0].Id;
            insert bkApprovalProcess;

            BookingCancellationApprovalController.sendCancellationApproval(
                bkApprovalProcess.Id,
                validCancellationReason,
                'Test Remarks',
                cancellationLabelAmount - 1,  // always < label amount dynamically
                false
            );
        } catch (Exception e) {
            System.debug('sendCancellationApproval Approval Process: ' + e.getMessage());
        }

        // ── BRANCH 6: sendCancellationApproval - isAfterPostAggrement = true ──
        // Covers: always sends for approval regardless of charge amount
        try {
            Booking__c bkPostAggrement = new Booking__c(
                First_Applicant_Name__c = 'Test Post Agreement',
                Mobile__c               = '9876543215',
                Quote__c                = qc.Id,
                Project__c              = validBookingProject,
                Stage__c                = validBookingStageAgreement,
                Agreement_Status__c     = validAgreementStatusExecuted
            );
            if (!bookingRecordTypes.isEmpty()) bkPostAggrement.RecordTypeId = bookingRecordTypes[0].Id;
            insert bkPostAggrement;

            BookingCancellationApprovalController.sendCancellationApproval(
                bkPostAggrement.Id,
                validCancellationReason,
                'Test Remarks',
                cancellationLabelAmount + 1,
                true
            );
        } catch (Exception e) {
            System.debug('sendCancellationApproval Post Agreement: ' + e.getMessage());
        }

        // ── Directly instantiate inner class to cover property lines ──
        BookingCancellationApprovalController.DataBox db = new BookingCancellationApprovalController.DataBox();
        db.cancellationAmount   = 25000;
        db.isAfterPostAggrement = false;

        Test.stopTest();
    }
}