trigger SiteVisitTrigger on Site_Visit__c (before insert,After Update, after insert,before Update) {
    if(Trigger.isBefore)
    {
        if(trigger.isInsert)
        {
            SiteVisitTriggerHandler.beforeInsert(Trigger.New);
        }
        else if(trigger.isUpdate){
            SiteVisitTriggerHandler.beforeUpdate(Trigger.New,Trigger.oldMap);
        }
    }
    if(Trigger.isAfter){
        if(trigger.isInsert || trigger.isUpdate){
            if(trigger.isInsert)
            {
                SiteVisitTriggerHandler.afterInsert(Trigger.New);
            }
            
            if(Trigger.isUpdate)
            {
                SiteVisitTriggerHandler.AfterUpdate(Trigger.New,Trigger.oldMap);
            }
            
            if(label.Enable_whatsapp_notifications == 'TRUE'){
                
                List<Site_Visit__c> proposed = new List<Site_Visit__c>();
                List<Site_Visit__c> scheduled = new List<Site_Visit__c>();
                List<Site_Visit__c> completed = new List<Site_Visit__c>();
                for(Site_Visit__c vis: trigger.new){
                    Boolean isNew = Trigger.isInsert;
                    Boolean statusChanged = Trigger.isUpdate 
                        && vis.Status__c != Trigger.oldMap.get(vis.Id).Status__c;
                    
                    if ( (isNew || statusChanged) && vis.Status__c == 'SV Proposed' ) {
                        proposed.add(vis);
                    }
                    
                    if ( (isNew || statusChanged) && vis.Status__c == 'Scheduled' ) {
                        scheduled.add(vis);
                    }
                    
                    if ( (isNew || statusChanged) && vis.Status__c == 'Completed' ) {
                        completed.add(vis);
                    }
                }
                if(proposed.size() > 0){
                    proposed = [select Id,Name,SLead__r.Name,SLead__r.Phone__c,Project__c,SV_Proposed_Date_Time__c from Site_Visit__c where Id IN: proposed];
                    WhatsappController ctrl = new WhatsappController(proposed,'3');
                    System.enqueueJob(ctrl);
                    SMSHandler smsctrl = new SMSHandler(proposed,'3');
                    System.enqueueJob(smsctrl);
                }
                if(scheduled.size() > 0){
                    scheduled = [select Id,Name,SLead__r.Name,SLead__r.Phone__c,Project__c,Date__c from Site_Visit__c where Id IN: scheduled];
                    WhatsappController ctrl = new WhatsappController(scheduled,'4');
                    System.enqueueJob(ctrl);
                      SMSHandler smsctrl = new SMSHandler(scheduled,'4');
                    System.enqueueJob(smsctrl);
                }
                if(completed.size() > 0){
                    completed = [select Id,Name,SLead__r.Name,SLead__r.Phone__c,Project__c,SV_Completed_Date_Time__c,Owner.Name from Site_Visit__c where Id IN: completed];
                    WhatsappController ctrl = new WhatsappController(completed,'5');
                    System.enqueueJob(ctrl);
                      SMSHandler smsctrl = new SMSHandler(completed,'5');
                    System.enqueueJob(smsctrl);
                }
            }

            // Kenyt.AI site-visit messages (BRD 4.12.2) - no-op until templates configured/active
            if(Trigger.isInsert){
                // #2 Appointment confirmation / Site Visit creation
                KenytWhatsAppService.send('SV_CREATED', Trigger.newMap.keySet(), 'Site_Visit__c');
            }
            if(Trigger.isUpdate){
                // #8 Post site-visit completion (thank you + feedback)
                Set<Id> svCompleted = new Set<Id>();
                for(Site_Visit__c vis : Trigger.new){
                    if(vis.Status__c == 'Completed'
                       && vis.Status__c != Trigger.oldMap.get(vis.Id).Status__c){
                        svCompleted.add(vis.Id);
                    }
                }
                if(!svCompleted.isEmpty()){
                    KenytWhatsAppService.send('SV_POST', svCompleted, 'Site_Visit__c');
                }
            }

        }
    }

}