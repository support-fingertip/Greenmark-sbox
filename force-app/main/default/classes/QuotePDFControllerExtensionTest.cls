@isTest
private class QuotePDFControllerExtensionTest {
    
    @isTest
    public static void setupTestData() {
        
        Project__c pjt = new Project__c();
        pjt.Name = 'Zuari Garden City';
        pjt.Project__c = 'Zuari Garden City';
        pjt.Active__c = true;
        insert pjt;
        
        Block__c bc = new Block__c();
        bc.Name='A';
        bc.Project__c=pjt.id;
        insert bc;
        
        Lead ld = new Lead();
        ld.LastName = 'Test';
        ld.Company = 'testcompany';
        ld.Phone__c = '8778987789';
        ld.Allocated_Project__c = 'Zuari Garden City';
        insert ld;
        
        
        // Create test Unit
        PLot__c testUnit = new PLot__c(
            Name = 'Test Unit 101',
            Project__c=pjt.id,
            Block_Lookup__c = bc.Id,
            Balcony_Area_Sq_ft__c = 50,
            Terrace_Area_Sq_ft__c = 20,
            SitOut_Area_Sq_ft__c = 10
        );
        insert testUnit;
        
        // Create test Lead
        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Status = 'Open'
        );
        insert testLead;
        
        // Create test Quote
        Quote__c testQuote = new Quote__c(
            
            SLead__c = testLead.Id,
            Project__c = 'Zuari Garden City',
            BHK_Type__c = '2BHK+ 2T',
            Unit__c = testUnit.Id,
            Super_Built_UpArea__c = 100,
            Carpet_Area__c = 80,
            Balcony_Area_Sq_ft__c = 50,
            Rate_per_sqft__c = 5000,
            Clubhouse_Charges__c = 100000,
            Generator_Charges__c = 50000,
            Piped_Gas_Charges__c = 30000,
            Legal_Fees__c = 25000,
            Type_of_Car_Parking__c = 'Single Covered',
            Floor_Rise_Charges_Rate__c = 1000
        );
        insert testQuote;
        
           Quote__c testQuote1 = [SELECT Id, GRAND_TOTAL__c FROM Quote__c where id =: testQuote.id LIMIT 1];
        
        Test.StartTest(); 
        ApexPages.StandardController sc = new ApexPages.StandardController(testQuote);
        QuotePDFControllerExtension testAccPlan = new QuotePDFControllerExtension(sc);
        
        
        PageReference pageRef = Page.CostSheet; // Add your VF page Name here
        pageRef.getParameters().put('id', String.valueOf(testQuote.Id));
        Test.setCurrentPage(pageRef);
        
       /*
        testAccPlan.formatCurrency(testQuote.GRAND_TOTAL__c);
        String formattedValue = testAccPlan.formatCurrency(testQuote.GRAND_TOTAL__c);
        String aString = testAccPlan.formattedGrandTotal;
        String aString1 = testAccPlan.formattedDiscountedTotal;
        String aString2 = testAccPlan.formattedRatePerSqft;
        String aString3 = testAccPlan.formattedGSTAgreement;
        String aString4 = testAccPlan.formattedStampCharges;
        String formattedAgreementValue = testAccPlan.formattedAgreementValue;
        String formattedLegalFees = testAccPlan.formattedLegalFees;
        String formattedGasCharges = testAccPlan.formattedGasCharges;
        String formattedGeneratorCharges = testAccPlan.formattedGeneratorCharges;
        String formattedClubCharges = testAccPlan.formattedClubCharges;
        String formattedWaterElectricity = testAccPlan.formattedWaterElectricity;
        String formattedSubTotal = testAccPlan.formattedSubTotal;
        String formattedGSTOther = testAccPlan.formattedGSTOther;
        String formattedRatePerSqft1 = testAccPlan.formattedRatePerSqft1;
        String formattedOnPossession = testAccPlan.formattedOnPossession;
        String formattedFloorRiseCharges = testAccPlan.formattedFloorRiseCharges;
        String formattedRateSqFt = testAccPlan.formattedRateSqFt;
        String formattedRateSqFtDiscount = testAccPlan.formattedRateSqFtDiscount;
        String formattedBaseValueDiscount = testAccPlan.formattedBaseValueDiscount;
        String formattedTerraceValue = testAccPlan.formattedTerraceValue;
        String formattedSitOutValue = testAccPlan.formattedSitOutValue;
        String formattedAgreementValueAfterGST = testAccPlan.formattedAgreementValueAfterGST;
        String formattedAgreementValueAfterGSTDiscount = testAccPlan.formattedAgreementValueAfterGSTDiscount;
        String formattedOtherChargesAfterGST = testAccPlan.formattedOtherChargesAfterGST;
        String formattedGrandTotalDiscount = testAccPlan.formattedGrandTotalDiscount;
        String formattedGuidelineValue = testAccPlan.formattedGuidelineValue;
        String formattedTotalMaintenanceCharge = testAccPlan.formattedTotalMaintenanceCharge;
        String formattedOtherPayables = testAccPlan.formattedOtherPayables;
        String formattedOnBooking = testAccPlan.formattedOnBooking;
        String formattedPaymentRequiredOnBooking = testAccPlan.formattedPaymentRequiredOnBooking;
        String formattedPaymentRequiredOnBookingDiscount = testAccPlan.formattedPaymentRequiredOnBookingDiscount;
        String formattedTDSAmount = testAccPlan.formattedTDSAmount;
        String formattedTDSAmountDiscount = testAccPlan.formattedTDSAmountDiscount;
        String formattedFrankingCharges = testAccPlan.formattedFrankingCharges;
        String formattedFrankingChargesDiscount = testAccPlan.formattedFrankingChargesDiscount;
        String formattedBalancePayable = testAccPlan.formattedBalancePayable;
        String formattedBalancePayableDiscount = testAccPlan.formattedBalancePayableDiscount;
        String formattedUponAgreement = testAccPlan.formattedUponAgreement;
        String formattedUponAgreementDiscount = testAccPlan.formattedUponAgreementDiscount;
        String formattedOnPossessionDiscount = testAccPlan.formattedOnPossessionDiscount;
        String formattedAgreementValue1 = testAccPlan.formattedAgreementValue1;
        String formattedBaseValue = testAccPlan.formattedBaseValue;
        */
        Test.StopTest();
    }
    
    
    
    
}