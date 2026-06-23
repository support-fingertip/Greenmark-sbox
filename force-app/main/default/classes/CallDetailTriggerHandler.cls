public class CallDetailTriggerHandler {
	public static void beforeInsert(list<Call_Detail__c> newCallList)
    {
        for(Call_Detail__c cd: newCallList)
        {
            if(cd.Lead_Project_Name__c != null)
            {
                cd.Project_Name__c = cd.Lead_Project_Name__c;
            }
            if(cd.Lead_Record_Type__c != null)
            {
                cd.Lead_Stage__c = cd.Lead_Record_Type__c;
            }
        }
    }
    public static void afterInsert(list<Call_Detail__c> newCallList)
    {
        Set<Id> leadIds = new Set<Id>();
        for(Call_Detail__c cd: newCallList)
        {
            if(cd.Lead__c != null)
            {
                leadIds.add(cd.Lead__c);
            }
        }
        
        if(!leadIds.isEmpty())   
        {      
            // Query all site visits for these leads
            List<Call_Detail__c> allCalls = [
                SELECT Id, Lead__c, createdDate
                FROM Call_Detail__c
                WHERE Lead__c IN :leadIds
                ORDER BY createdDate ASC
            ];
            Map<Id, DateTime> firstCallMap = new Map<Id, DateTime>();
            Map<Id, DateTime> lastCallMap  = new Map<Id, DateTime>();
            
            
            // Loop through all visits in ORDER of Date__c (ASC)
            for (Call_Detail__c sv : allCalls) {
                Id leadId = sv.Lead__c;
                // First visit (since list is sorted ASC, first encountered is the earliest)
                if (!firstCallMap.containsKey(leadId)) {
                    // Assume Date__c is Date or DateTime; handle safely
                    firstCallMap.put(leadId, (DateTime) sv.createdDate);
                }
                // Last visit (updates continuously, so last one is latest)
                lastCallMap.put(leadId, (DateTime) sv.createdDate);
            }
            
            // Query leads to update
            List<Lead> leadsToUpdate = [
                SELECT Id
                FROM Lead
                WHERE Id IN :leadIds
            ];
            
            // Set the values
            for (Lead ld : leadsToUpdate) {
                ld.First_Call_Time__c = firstCallMap.get(ld.Id);
                ld.Last_Call_Time__c  = lastCallMap.get(ld.Id);
            }
            
            database.update(leadsToUpdate,false);
        }
    }
}