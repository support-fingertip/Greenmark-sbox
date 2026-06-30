trigger QuoteTrigger on Quote__c (before insert,after insert,after update) {
    if(trigger.isInsert)
    {
        if(trigger.isBefore)
        {
            QuoteApprovalHandler.beforeInsert(trigger.New);
        }
        else
        {
            // Kenyt.AI quotation sent (BRD 4.12.2 #3) - no-op until template configured/active
            KenytWhatsAppService.send('QUOTE_SENT', trigger.newMap.keySet(), 'Quote__c');
        }
    }
    /*
    if (Trigger.isAfter &&  Trigger.isUpdate) {
         List<Quote__c> quotesToProcess = new List<Quote__c>();
        
        for (Quote__c newQuote : Trigger.new) {
            if (newQuote.Discount_Price__c != Trigger.oldMap.get(newQuote.Id).Discount_Price__c && newQuote.Discount_Price__c > 100) {
                quotesToProcess.add(newQuote);
            }
        }
        if (!quotesToProcess.isEmpty()) {
            system.debug('Called Approval Process');
            QuoteApprovalHandler.processQuotes(quotesToProcess);
        }
    }
*/
}