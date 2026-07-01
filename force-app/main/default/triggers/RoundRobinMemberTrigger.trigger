// Notifies the executive when their round-robin member record is deactivated (BRD 4.1.9) v2.
trigger RoundRobinMemberTrigger on Round_Robin_Member__c (after update) {
    if(Trigger.isAfter && Trigger.isUpdate){
        RoundRobinMemberTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}
