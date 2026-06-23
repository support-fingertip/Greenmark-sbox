public class DemandRaisedTriggerHandler {
    public static void onAfterInsert(List<Demand_Raised__c> newDemands) {
        if (newDemands == null || newDemands.isEmpty()) {
            return;
        }

        // Collect all Demand_Raised__c Ids
        Set<Id> demandIds = new Set<Id>();
        for (Demand_Raised__c d : newDemands) {
            demandIds.add(d.Id);
        }

        // Query demands with required Booking__r fields
        List<Demand_Raised__c> demandsWithBooking = [
            SELECT Id, Booking__c, Booking__r.Mobile__c,Booking__r.Owner_Email__c, Booking__r.First_Applicant_Name__c, Booking__r.Unit_No__c, Booking__r.CRM_Executive_Contact_No__c, Payment_Due_Date__c, Grand_Total__c, Project_Block_Name__c
            FROM Demand_Raised__c
            WHERE Id IN :demandIds
        ];

        WhatsappController controller = new WhatsappController(demandsWithBooking, '8');
        System.enqueueJob(controller);
        
        
        SMSHandler smsctrl = new SMSHandler(demandsWithBooking,'8');
        System.enqueueJob(smsctrl);
        
    }
}