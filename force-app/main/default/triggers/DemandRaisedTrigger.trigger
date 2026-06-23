trigger DemandRaisedTrigger on Demand_Raised__c (after insert) {
    DemandRaisedTriggerHandler.onAfterInsert(Trigger.new);
}