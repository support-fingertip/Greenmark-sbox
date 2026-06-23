trigger RelatedSourceTrigger on Related_Source__c (after insert) {
    
   if(trigger.IsInsert && Trigger.IsAfter){
      

        Map<Id,Id> rsMap = new Map<Id,Id>();
        Set<Id> leadIds = new Set<Id>();
        Set<Id> otpSendingLeadIds = new Set<Id>();
        List<Related_Source__c>UpdateList=new List<Related_Source__c>();
        for(Related_Source__c r:trigger.new){
            if(r.Channel_Partner__c != null){
                rsMap.put(r.SLead__c,r.CP_Owner_ID__c);
                
            }
         
        }
            if(rsMap.size()>0){
            manulaSharingClass.manualShareLeadVisit(rsMap);
          // SourceManagerClass.SMmethod(rsMap.keyset());
        }
     
}
}