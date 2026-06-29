trigger FollowUpTrigger on Follow_up__c (before insert,After Insert,After Update) {

    if(Trigger.isBefore)
    {
        if(trigger.isInsert)
        {
            FollowUpTriggerHandler.beforeInsert(trigger.new);
        }
    }
    if(Trigger.isAfter){
        if(trigger.isInsert)
        {
            FollowUpTriggerHandler.afterInsert(trigger.new);
        }
        if(trigger.isUpdate)
        {
            FollowUpTriggerHandler.afterUpdate(trigger.new,trigger.oldMap);
        }
    }
}