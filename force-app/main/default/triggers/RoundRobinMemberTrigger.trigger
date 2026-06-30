trigger RoundRobinMemberTrigger on Round_Robin_Member__c (after update) {
    if(Trigger.isAfter && Trigger.isUpdate){
        RoundRobinMemberTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}
