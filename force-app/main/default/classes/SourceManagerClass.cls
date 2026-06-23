public class SourceManagerClass
{
   Public static void SMmethod(Set <ID> Leadids)
    {
        Map<Id, Set<Id>> leadToSourceManagersMap = new Map<Id, Set<Id>>();
        
        for (Related_Source__c rs : [SELECT Id, SLead__c FROM Related_Source__c]) 
        {
            if (!leadToSourceManagersMap.containsKey(rs.SLead__c)) {
                leadToSourceManagersMap.put(rs.SLead__c, new Set<Id>());
            }
           // leadToSourceManagersMap.get(rs.SLead__c).add(rs.Channel_Partner__r.Source_Manager__c);
        }
       
        List<Lead> leadsToUpdate = new List<Lead>();
        for (Id leadId : leadIds) {
            Lead lead = new Lead(Id = leadId);
            if (leadToSourceManagersMap.containsKey(leadId)) {
                lead.Source_Manager_Id_s__c = String.join(new List<Id>(leadToSourceManagersMap.get(leadId)), ';');
            } else {
                lead.Source_Manager_Id_s__c = '';
            }
            leadsToUpdate.add(lead);
        }
        
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }
}