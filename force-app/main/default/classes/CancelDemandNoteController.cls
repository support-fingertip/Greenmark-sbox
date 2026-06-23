public class CancelDemandNoteController {
    @AuraEnabled
    public static void cancelDemandNote(Id recId,String reason) {
        Demand_Raised__c demand = [SELECT Id,Name,Cancellation_Reason__c,Is_Cancelled__c,Demand_Status__c,Payment_schedule__c
                                   FROM Demand_Raised__c WHERE Id = :recId LIMIT 1];
        demand.Is_Cancelled__c = true;
        demand.Cancellation_Reason__c = reason;
        demand.Demand_Status__c = 'Demand Cancelled';
        update demand;
        
        Payment_Schedule__c paymentSchdule = [select Id,Name from Payment_Schedule__c where Id =:demand.Payment_schedule__c limit 1];
        paymentSchdule.Demanded_Date__c = null;
        paymentSchdule.Due_Date_Extension__c = 0;
        paymentSchdule.Is_Demanded__c = false;
        update paymentSchdule;
        
    }
}