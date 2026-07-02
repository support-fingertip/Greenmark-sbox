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
            // Kenyt.AI booking confirmation (BRD 4.12.2 #4) - no-op until template configured/active
            KenytWhatsAppService.send('BOOKING_CONFIRMED', trigger.newMap.keySet(), 'Booking__c');
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