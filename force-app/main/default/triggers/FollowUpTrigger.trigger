trigger FollowUpTrigger on Follow_up__c (before insert,After Update) {
    
    if(Trigger.isBefore)
    {
        if(trigger.isInsert)
        {
            FollowUpTriggerHandler.beforeInsert(trigger.new);
        }
    }
    if(Trigger.isAfter){
        if(trigger.isUpdate)
        {
            FollowUpTriggerHandler.afterUpdate(trigger.new,trigger.oldMap);
        }
    }
}