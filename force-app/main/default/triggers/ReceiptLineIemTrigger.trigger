/**
* Trigger : ReceiptTrigger
* Handler : ReceiptLineIemTriggerHandler
* Purpose : Delegates all business logic to handler class
*           to maintain trigger best practices.
* @author      : Durga Prasad
*
* Change Log:
* ----------------------------------------------------------------
* Ver | Author        | Date        | Description
* ----------------------------------------------------------------
* 1.0 | Durga Prasad | 04-02-2026  | Initial version
* ----------------------------------------------------------------
*/
trigger ReceiptLineIemTrigger on Receipt_Line_Item__c (after insert) {
    if(trigger.isInsert)
    {
        if(trigger.isAfter)
        {
            ReceiptLineIemTriggerHandler.afterInsert(trigger.new);      
        }
    }
}