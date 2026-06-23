trigger TicketTrigger on Ticket__c (before insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        TicketTriggerHandler.beforeInsert(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        TicketTriggerHandler.handleAfterUpdate(
            Trigger.new,
            Trigger.oldMap
        );
    }
}