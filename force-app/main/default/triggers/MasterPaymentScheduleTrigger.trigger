trigger MasterPaymentScheduleTrigger on Master_Payment_Schedule__c (after Update) 
{
	if(trigger.isUpdate)
    {
        if(trigger.isAfter)
        {
            MasterPaymentScheduleTriggerHandler.afterUpdate(trigger.New,trigger.OldMap);
        }
    }
}