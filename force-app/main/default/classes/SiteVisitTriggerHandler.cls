public  without sharing class SiteVisitTriggerHandler {
   
    public static void beforeInsert(List<Site_Visit__c> newSiteVisits)
    {
        for (Site_Visit__c sv : newSiteVisits) {
            if (sv.Lead_Record_Type_Name__c != null) {
                sv.Lead_Stage__c =sv.Lead_Record_Type_Name__c;
                
            }
            if(sv.Credit_Source__c != null)
            {
                sv.Credit_Source_for_Sharing__c = sv.Credit_Source__c;
            }
        }
    }
    public static void afterInsert(List<Site_Visit__c> newSiteVisits)
    {
       list<Site_Visit__c> verifiedbyGRESitevisits = new list<Site_Visit__c> ();
        // Collect Lead Ids
        Set<Id> leadIds = new Set<Id>();
        for (Site_Visit__c sv : newSiteVisits) {
            if (sv.SLead__c != null) {
                leadIds.add(sv.SLead__c);
                if(sv.Status__c == 'Verified by GRE')
                {
                     verifiedbyGRESitevisits.add(sv);
                }
            }
        }
        
        if(!leadIds.isEmpty())   
        {
            // Query all site visits for these leads
            List<Site_Visit__c> allVisits = [
                SELECT Id, SLead__c, Date__c
                FROM Site_Visit__c
                WHERE SLead__c IN :leadIds
                ORDER BY Date__c ASC
            ];
            system.debug('allVisits'+allVisits.size());
            
            // Prepare aggregate maps
            Map<Id, Integer> visitCountMap = new Map<Id, Integer>();
            Map<Id, DateTime> firstVisitMap = new Map<Id, DateTime>();
            Map<Id, DateTime> lastVisitMap  = new Map<Id, DateTime>();
            
            // Loop through all visits in ORDER of Date__c (ASC)
            for (Site_Visit__c sv : allVisits) {
                
                Id leadId = sv.SLead__c;
                
                // Count total visits
                visitCountMap.put(leadId,
                                  visitCountMap.containsKey(leadId) ? visitCountMap.get(leadId) + 1 : 1
                                 );
                
                // First visit (since list is sorted ASC, first encountered is the earliest)
                if (!firstVisitMap.containsKey(leadId)) {
                    // Assume Date__c is Date or DateTime; handle safely
                    firstVisitMap.put(leadId, (DateTime) sv.Date__c);
                }
                
                // Last visit (updates continuously, so last one is latest)
                lastVisitMap.put(leadId, (DateTime) sv.Date__c);
            }
            
            // Query leads to update
            List<Lead> leadsToUpdate = [
                SELECT Id
                FROM Lead
                WHERE Id IN :leadIds
            ];
            
            // Set the values
            for (Lead ld : leadsToUpdate) {
                ld.No_of_Site_Visit__c = visitCountMap.get(ld.Id);
                ld.First_Site_Visit_Date_Time__c = firstVisitMap.get(ld.Id);
                ld.Last_Site_Visit_Date_Time__c  = lastVisitMap.get(ld.Id);
            }
            
            database.update(leadsToUpdate,false);
        }
        if(!verifiedbyGRESitevisits.isEmpty())
        {
            system.debug('verifiedbyGRESitevisits-->'+verifiedbyGRESitevisits);
            // Get Notification Type
            CustomNotificationType notificationType = [
                SELECT Id 
                FROM CustomNotificationType 
                WHERE DeveloperName = 'GRE_Verified_Site_Visit_Notification'
                LIMIT 1
            ];
            
            // Loop through verified site visits
            for (Site_Visit__c sv : verifiedbyGRESitevisits) {
                
                // Build dynamic title with Lead Name
                String leadName = sv.Lead_Name__c != null ? sv.Lead_Name__c : 'Lead';
                String title = leadName + ' - Site Visit Verified by GRE';
                
                // Body message (optional extra details)
                String body = 'Lead Name : ' + leadName +
                    '\nLead Phone : ' + (sv.Lead_Phone_Number__c != null ? sv.Lead_Phone_Number__c : 'N/A') +
                    '\nPlease proceed with the next steps.';
                
                // Send Custom Notification
                CustomNotificationService.notificationSend(
                    title,
                    sv.Id,
                    body,
                    new Set<String>{ sv.OwnerId },
                    notificationType.Id
                );
            }

        }
    }
    public static void beforeUpdate(List<Site_Visit__c> newList, Map<Id, Site_Visit__c> oldMap) 
    {
        for (Site_Visit__c sv : newList) {
            if(oldMap.get(sv.Id).OwnerId != sv.OwnerId)
            {
                sv.Owner_Changed__c = true;
            }
        }
    }  
    public static void AfterUpdate(List<Site_Visit__c> newList, Map<Id, Site_Visit__c> oldMap)
    {
        
        Set<Id> leadsForStatusUpdate = new Set<Id>();
        Set<Id> leadsForVisitRecalc  = new Set<Id>();
        list<Site_Visit__c> verifiedbyGRESitevisits = new list<Site_Visit__c> ();
        List<Site_Visit__c> completedSiteVisits = new List<Site_Visit__c>();
        
        for (Site_Visit__c sv : newList) {
            
            Site_Visit__c oldSv = oldMap.get(sv.Id);
            
            // Mark lead for SV Done update
            if (sv.Slead__c != null && oldSv.Status__c != sv.Status__c) 
            {
                if(sv.Status__c == 'Completed')
                {
                    leadsForStatusUpdate.add(sv.Slead__c);
                    completedSiteVisits.add(sv);
                }
                else if(sv.Status__c == 'Verified by GRE')
                {
                    verifiedbyGRESitevisits.add(sv);
                }
              
            }
            
            // Mark lead for recalculation when date changed
            if (sv.Slead__c != null &&
                oldSv.Date__c != sv.Date__c &&
                sv.Date__c != null)
            {
                leadsForVisitRecalc.add(sv.Slead__c);
            }
        }
        
        // ------------------------------------
        // 1) UPDATE Lead Status (SV Done)
        // ------------------------------------
        if (!leadsForStatusUpdate.isEmpty()) {
            
            List<Lead> leads = [
                SELECT Id
                , Lead_Status__c
                FROM Lead
                WHERE Id IN :leadsForStatusUpdate
                AND Lead_Record_Type__c = 'Sales'
            ];
            
            for (Lead ld : leads) {
                ld.Lead_Status__c = 'SV Done';
            }
            
            update leads;
        }
        
        
        // ------------------------------------
        // 2) UPDATE Last Note On (SV Done)
        // ------------------------------------
        if (!completedSiteVisits.isEmpty()) {
            updateLeadNotesFromSiteVisits(completedSiteVisits);
        }
        
        // ------------------------------------
        // 3) Recalculate Visit Counts & Dates
        // ------------------------------------
        if (!leadsForVisitRecalc.isEmpty()) {
            
            // Get all visits for the impacted leads
            List<Site_Visit__c> allVisits = [
                SELECT Id, SLead__c, Date__c
                FROM Site_Visit__c
                WHERE SLead__c IN :leadsForVisitRecalc
                ORDER BY SLead__c ASC, Date__c ASC
            ];
            
            Map<Id, Integer> visitCountMap = new Map<Id, Integer>();
            Map<Id, DateTime> firstVisitMap = new Map<Id, DateTime>();
            Map<Id, DateTime> lastVisitMap  = new Map<Id, DateTime>();
            
            for (Site_Visit__c sv : allVisits) {
                
                Id leadId = sv.SLead__c;
                
                // Count
                visitCountMap.put(leadId,
                                  (visitCountMap.containsKey(leadId) ? visitCountMap.get(leadId) + 1 : 1)
                                 );
                
                // First Visit (first in sorted ASC list)
                if (!firstVisitMap.containsKey(leadId)) {
                    firstVisitMap.put(leadId, (DateTime) sv.Date__c);
                }
                
                // Last Visit (keep replacing, so last is newest)
                lastVisitMap.put(leadId, (DateTime) sv.Date__c);
            }
            
            List<Lead> leadsToUpdate = [
                SELECT Id
                FROM Lead
                WHERE Id IN :leadsForVisitRecalc
            ];
            
            for (Lead ld : leadsToUpdate) {
                ld.No_of_Site_Visit__c             = visitCountMap.get(ld.Id);
                ld.First_Site_Visit_Date_Time__c   = firstVisitMap.get(ld.Id);
                ld.Last_Site_Visit_Date_Time__c    = lastVisitMap.get(ld.Id);
            }
            
            update leadsToUpdate;
        }
        
        // ------------------------------------
        // 4) Send notification if it is verified by GRE
        // ------------------------------------
        if(!verifiedbyGRESitevisits.isEmpty())
        {
            system.debug('verifiedbyGRESitevisits-->'+verifiedbyGRESitevisits);
            // Get Notification Type
            CustomNotificationType notificationType = [
                SELECT Id 
                FROM CustomNotificationType 
                WHERE DeveloperName = 'GRE_Verified_Site_Visit_Notification'
                LIMIT 1
            ];
            
            // Loop through verified site visits
            for (Site_Visit__c sv : verifiedbyGRESitevisits) {
                
                // Build dynamic title with Lead Name
                String leadName = sv.Lead_Name__c != null ? sv.Lead_Name__c : 'Lead';
                String title = leadName + ' - Site Visit Verified by GRE';
                
                // Body message (optional extra details)
                String body = 'Lead Name : ' + leadName +
                    '\nLead Phone : ' + (sv.Lead_Phone_Number__c != null ? sv.Lead_Phone_Number__c : 'N/A') +
                    '\nPlease proceed with the next steps.';
                
                // Send Custom Notification
                CustomNotificationService.notificationSend(
                    title,
                    sv.Id,
                    body,
                    new Set<String>{ sv.OwnerId },
                    notificationType.Id
                );
            }
            
        }
    }
    
    public static void updateLeadNotesFromSiteVisits(List<Site_Visit__c> completedVisits) {
        
        if (completedVisits.isEmpty()) return;
        
        Set<Id> leadIds = new Set<Id>();
        for (Site_Visit__c sv : completedVisits) {
            if (sv.Slead__c != null && sv.Site_Visit_Remarks__c != null) {
                leadIds.add(sv.Slead__c);
            }
        }
        
        if (leadIds.isEmpty()) return;
        
        Map<Id, Lead> leadMap = new Map<Id, Lead>([
            SELECT Id, Last_Note__c
            FROM Lead
            WHERE Id IN :leadIds
        ]);
        
        User currentUser = [
            SELECT Id, Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        
        Datetime dt = Datetime.now();
        String formattedTime = dt.format('dd-MM-yy HH:mm a');
        
        Map<Id, List<String>> leadNotesMap = new Map<Id, List<String>>();
        
        // Group site visit remarks per lead
        for (Site_Visit__c sv : completedVisits) {
            if (!leadNotesMap.containsKey(sv.Slead__c)) {
                leadNotesMap.put(sv.Slead__c, new List<String>());
            }
            
            leadNotesMap.get(sv.Slead__c).add(
                 currentUser.Name +
                ' [' + formattedTime + ']: ' +
                sv.Site_Visit_Remarks__c
            );
        }
        
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for (Id leadId : leadNotesMap.keySet()) {
            
            Lead ld = leadMap.get(leadId);
            if (ld == null) continue;
            
            Integer noteCount = 1;
            if (ld.Last_Note__c != null && !ld.Last_Note__c.trim().equals('')) {
                noteCount = ld.Last_Note__c.split('\n').size() + 1;
            } else {
                ld.Last_Note__c = '';
            }
            
            for (String note : leadNotesMap.get(leadId)) {
                ld.Last_Note__c +=
                    '\nSite Visit Summary ' + noteCount + ': ' + note;
                noteCount++;
            }
            
            leadsToUpdate.add(ld);
        }
        
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }
}