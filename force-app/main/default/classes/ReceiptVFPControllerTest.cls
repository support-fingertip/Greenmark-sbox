@isTest
private class ReceiptVFPControllerTest {

    private static String getPicklistValue(SObjectField field, String keyword) {
        List<Schema.PicklistEntry> entries = field.getDescribe().getPicklistValues();
        String fallback = null;
        for (Schema.PicklistEntry e : entries) {
            if (fallback == null) fallback = e.getValue();
            if (e.getValue().toLowerCase().contains(keyword.toLowerCase())) return e.getValue();
        }
        return fallback;
    }

    @TestSetup
    static void setupData() {
        // 1. Setup Project
        Project__c proj = new Project__c(Name = 'Trifecta Vanto', Project__c = 'Trifecta Vanto', Active__c = true);
        insert proj;

        // 2. Setup Block
        Block__c blk = new Block__c(
            Name = 'A',
            Project__c = proj.Id,
            Intrest_Percentage__c = 12,
            Company_Name__c = 'TRIFECTA PROJECTS PVT LTD',
            Land_Company_Name__c = 'TRIFECTA LAND PVT LTD',
            Construction_Company_Name__c = 'TRIFECTA CONSTRUCTION PVT LTD',
            Company_Address__c = '123 Test Street, Bangalore',
            Project_Address__c = '456 Project Road, Bangalore',
            Email__c = 'block@trifecta.com'
        );
        insert blk;

        // 3. Setup Plot
        Plot__c plot = new Plot__c(
            Name = 'P1',
            Block_Lookup__c = blk.Id,
            Status__c = 'Available',
            Project__c = proj.Id,
            Block__c = 'A2' 
        );
        insert plot;

        // 4. Setup Lead (Include Lead_ID__c if it's a field)
        Lead ld = new Lead(
            LastName = 'Test Lead', 
            Company = 'Test Co', 
            Source_Type__c = getPicklistValue(Lead.Source_Type__c, 'google'),
            Phone__c = '9876543210'
        );
        insert ld;

        // 5. Setup Quote
        Quote__c qc = new Quote__c(
            Block_Lookup__c = blk.Id,
            Block__c = 'A2',
            Quote_status__c = 'Drafted',
            Project__c = 'Trifecta Vanto',
            Unit__c = plot.Id,
            SLead__c = ld.Id
        );
        insert qc;

        // 6. Setup Bookings
        String projectTypeApartment = getPicklistValue(Booking__c.Project_Type__c, 'apartment');
        String projectTypeVilla = 'Villas'; // Explicitly use 'Villas' to hit the If branch

        Booking__c bookingApt = new Booking__c(
            Quote__c = qc.Id,
            Plot__c = plot.Id,
            Project1__c = proj.Id,
            Project_Type__c = projectTypeApartment,
            First_Applicant_Name__c = 'Test Customer'
        );
        insert bookingApt;

        Booking__c bookingVilla = new Booking__c(
            Quote__c = qc.Id,
            Plot__c = plot.Id,
            Project1__c = proj.Id,
            Project_Type__c = projectTypeVilla,
            First_Applicant_Name__c = 'Villa Customer'
        );
        insert bookingVilla;

        // 7. Setup Co-Applicant
        insert new Co_Applicant__c(
            Name = 'Co App', 
            Booking__c = bookingApt.Id, 
            Primary_Phone__c = '9876543210',
            Email__c = 'test@test.com'
        );

        // 8. Payment Schedule
        Payment_Schedule__c ps = new Payment_Schedule__c(Name = 'Booking', Booking__c = bookingApt.Id, Quote__c = qc.Id);
        insert ps;

        // 9. Receipts
        Receipt__c rcApt = new Receipt__c(Receipt_Name__c = 'REC-APT-001', Booking__c = bookingApt.Id, Type__c = 'Construction');
        insert rcApt;

        Receipt__c rcVillaLand = new Receipt__c(Receipt_Name__c = 'REC-VILLA-LAND', Booking__c = bookingVilla.Id, Type__c = 'Land');
        insert rcVillaLand;

        Receipt__c rcVillaConst = new Receipt__c(Receipt_Name__c = 'REC-VILLA-CONST', Booking__c = bookingVilla.Id, Type__c = 'Construction');
        insert rcVillaConst;

        // 10. Line Items 
        insert new List<Receipt_Line_Item__c>{
            new Receipt_Line_Item__c(
                Received_Amount__c = 10000, 
                Receipt__c = rcApt.Id, 
                Booking__c = bookingApt.Id, 
                Payment_Type__c = 'Flat Amount', 
                Payment_schedule__c = ps.Id
            ),
            new Receipt_Line_Item__c(
                Received_Amount__c = 500, 
                Receipt__c = rcApt.Id, 
                Booking__c = bookingApt.Id, 
                Payment_Type__c = 'TDS', // This will be excluded by your query, covering the 'AND' logic
                Payment_schedule__c = ps.Id
            )
        };
    }

    @isTest
    static void testApartmentReceipt() {
        Receipt__c rc = [SELECT Id FROM Receipt__c limit 1];
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(rc);
        ReceiptVFPController ctrl = new ReceiptVFPController(sc);
        Test.stopTest();
        
        System.assertNotEquals(null, ctrl.receiptInfo);
        System.assertEquals('TRIFECTA PROJECTS PVT LTD', ctrl.receiptInfo.companyName);
        System.assert(ctrl.totalReceivedAmount > 0);
    }

    @isTest
    static void testVillaLandReceipt() {
        Receipt__c rc = [SELECT Id FROM Receipt__c WHERE Receipt_Name__c = 'REC-VILLA-LAND' LIMIT 1];
        
        Test.startTest();
        ReceiptVFPController ctrl = new ReceiptVFPController(new ApexPages.StandardController(rc));
        Test.stopTest();
        
        System.assertEquals('TRIFECTA LAND PVT LTD', ctrl.receiptInfo.companyName);
    }

    @isTest
    static void testVillaConstructionReceipt() {
        Receipt__c rc = [SELECT Id FROM Receipt__c WHERE Receipt_Name__c = 'REC-VILLA-CONST' LIMIT 1];
        
        Test.startTest();
        ReceiptVFPController ctrl = new ReceiptVFPController(new ApexPages.StandardController(rc));
        Test.stopTest();
        
        System.assertEquals('TRIFECTA CONSTRUCTION PVT LTD', ctrl.receiptInfo.companyName);
    }

    @isTest
    static void testWrapperAndNullChecks() {
        // This covers the empty constructor and property setters
        ReceiptVFPController.ReceiptInfoWrapper wrap = new ReceiptVFPController.ReceiptInfoWrapper();
        wrap.receiptNo = 'R-100';
        wrap.customerId = 'C-100';
        wrap.customerName = 'Test';
        wrap.unitNo = 'U-100';
        wrap.block = 'B-100';
        wrap.receiptDate = '2026-02-06';
        wrap.project = 'Project';
        wrap.projectAddress = 'Address';
        wrap.email = 'email@test.com';
        wrap.contactNo = '1234567890';
        wrap.webAddress = 'www.test.com';
        wrap.companyAddress = 'Co Address';
        wrap.companyName = 'Co Name';
        
        System.assertEquals('R-100', wrap.receiptNo);
    }
}