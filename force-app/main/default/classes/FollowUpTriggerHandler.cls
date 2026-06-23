public class FollowUpTriggerHandler {
    
    public static void beforeInsert(list<Follow_up__c> newFollowups)
    {
        for(Follow_up__c flp : newFollowups)
        {
            flp.Project_Name1__c = flp.Project_Name__c;
            if(flp.Lead_Record_Type_Name__c != null)
            {
                flp.Lead_Stage__c = flp.Lead_Record_Type_Name__c;
            }
        }
    }
    public static void afterUpdate(list<Follow_up__c> newFollowups, Map<Id,Follow_up__c> oldFollowupMap)
    {
        List<Follow_up__c> completedFollowUps = new List<Follow_up__c>();
        for (Follow_up__c flp : newFollowups) {
            
            Follow_up__c oldfp = oldFollowupMap.get(flp.Id);
            
            // Mark lead for folloup Done update
            if (flp.SLead__c != null && oldfp.Status__c != flp.Status__c && flp.Status__c == 'Completed') 
            {    
                completedFollowUps.add(flp);
            }
        }
        
        if (!completedFollowUps.isEmpty()) {
            updateLeadNotesFromSiteVisits(completedFollowUps);
        }
    }
    
    public static void updateLeadNotesFromSiteVisits(List<Follow_up__c> completedFollowups) {
        
        if (completedFollowups.isEmpty()) return;
        
        Set<Id> leadIds = new Set<Id>();
        for (Follow_up__c flp : completedFollowups) {
            if (flp.Slead__c != null && flp.Comments__c != null) {
                leadIds.add(flp.Slead__c);
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
        for (Follow_up__c flp : completedFollowups) {
            if (!leadNotesMap.containsKey(flp.Slead__c)) {
                leadNotesMap.put(flp.Slead__c, new List<String>());
            }
            
            leadNotesMap.get(flp.Slead__c).add(
                 currentUser.Name +
                ' [' + formattedTime + ']: ' +
                flp.Comments__c
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
                    '\nFollow-Up Summary ' + noteCount + ': ' + note;
                noteCount++;
            }
            
            leadsToUpdate.add(ld);
        }
        
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }
    
}