trigger BookingTrigger on Booking__c (after insert,before Insert, before update,after Update) {
    if(trigger.isinsert)
    {
        if(trigger.isBefore)
        {
            BookingTriggerHandler.beforeInsert(trigger.new);
        }
        else
        {
            BookingTriggerHandler.afterInsert(trigger.new);
        }
        
    }
    if(trigger.isUpdate)
    {
        if(trigger.isBefore)
        {
            BookingTriggerHandler.beforeUpdate(trigger.new,trigger.oldMap);
        }
        else
        {
            BookingTriggerHandler.afterUpdate(trigger.new,trigger.oldMap);
        }
    }
}