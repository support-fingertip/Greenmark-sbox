@isTest
private class CancelDemandNoteControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create Payment Schedule
        Payment_Schedule__c paymentSchedule = new Payment_Schedule__c(
            Demanded_Date__c = Date.today(),
            Due_Date_Extension__c = 5,
            Is_Demanded__c = true
        );
        insert paymentSchedule;
        Booking__c bk = TestDataFactory.createBooking('Apartments');
        // Create Demand Raised
        Demand_Raised__c demand = new Demand_Raised__c(
            Is_Cancelled__c = false,
            Demand_Status__c = 'Demand Raised',
            Payment_schedule__c = paymentSchedule.Id,
            Booking__c =bk.Id 
        );
        insert demand;
    }
    

    @isTest
    static void testCancelDemandNote_Success() {
        Demand_Raised__c demand = [SELECT Id FROM Demand_Raised__c LIMIT 1];
        
        Test.startTest();
            CancelDemandNoteController.cancelDemandNote(demand.Id, 'Customer requested cancellation');
        Test.stopTest();
        
        Demand_Raised__c updatedDemand = [SELECT Id, Is_Cancelled__c, Cancellation_Reason__c, Demand_Status__c 
                                          FROM Demand_Raised__c WHERE Id = :demand.Id];
        Payment_Schedule__c updatedSchedule = [SELECT Id, Demanded_Date__c, Due_Date_Extension__c, Is_Demanded__c 
                                               FROM Payment_Schedule__c LIMIT 1];
     
    }
    

    @isTest
    static void testCancelDemandNote_BlankReason() {
        Demand_Raised__c demand = [SELECT Id FROM Demand_Raised__c LIMIT 1];
        
        Test.startTest();
            CancelDemandNoteController.cancelDemandNote(demand.Id, '');
        Test.stopTest();
        
        Demand_Raised__c updatedDemand = [SELECT Id, Is_Cancelled__c, Cancellation_Reason__c, Demand_Status__c 
                                          FROM Demand_Raised__c WHERE Id = :demand.Id];
        

    }
    

    @isTest
    static void testCancelDemandNote_NullReason() {
        Demand_Raised__c demand = [SELECT Id FROM Demand_Raised__c LIMIT 1];
        
        Test.startTest();
            CancelDemandNoteController.cancelDemandNote(demand.Id, null);
        Test.stopTest();
        
        Demand_Raised__c updatedDemand = [SELECT Id, Cancellation_Reason__c 
                                          FROM Demand_Raised__c WHERE Id = :demand.Id];
        
    }
    

    @isTest
    static void testCancelDemandNote_InvalidId() {
        Test.startTest();
            try {
                CancelDemandNoteController.cancelDemandNote(null, 'Test');
            } catch (Exception e) {
            }
        Test.stopTest();
    }
    
}