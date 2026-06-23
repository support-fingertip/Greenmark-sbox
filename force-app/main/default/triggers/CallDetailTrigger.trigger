trigger CallDetailTrigger on Call_Detail__c (after update,before insert,After Insert) {
    
    if(trigger.isInsert)
    {
        if(trigger.isBefore)
        {
            CallDetailTriggerHandler.beforeInsert(trigger.new);
        }
        else 
        {
            CallDetailTriggerHandler.afterInsert(trigger.new);
        }
    }
    
    if(trigger.isUpdate)
    {
        if(Trigger.isAfter){
            Set<Id> leadIds = new Set<Id>();
            for(Call_Detail__c cd: trigger.new){
                if(cd.Status__c != trigger.oldMap.get(cd.id).Status__c && cd.Status__c == 'Customer Busy'){
                    leadIds.add(cd.Lead__c);
                }
            }
            List<Lead> newLeads = [select Id,Name,Phone__c,Allocated_Project__c from Lead where Id IN: leadIds];
            WhatsappController ctrl = new WhatsappController(newLeads,'2');
            System.enqueueJob(ctrl);
        }
    }
}