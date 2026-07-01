public with sharing class LeadHistoryController {

    public class LeadWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String phone;
        @AuraEnabled public String project;
        @AuraEnabled public String status;
        @AuraEnabled public String ownerName;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String recordUrl;
    }

    public class LeadHistoryResult {
        @AuraEnabled public String phone;
        @AuraEnabled public List<LeadWrapper> leads = new List<LeadWrapper>();
    }

    /**
     * Returns every other Lead that shares the current Lead's Phone__c,
     * newest first. The current record is excluded so the result represents
     * the lead's previous history for that phone number.
     */
    @AuraEnabled(cacheable=true)
    public static LeadHistoryResult getLeadHistory(Id recordId) {
        LeadHistoryResult result = new LeadHistoryResult();

        if (recordId == null) {
            return result;
        }

        Lead current = [SELECT Id, Phone__c FROM Lead WHERE Id = :recordId LIMIT 1];
        result.phone = current.Phone__c;

        if (String.isBlank(current.Phone__c)) {
            return result;
        }

        for (Lead l : [
            SELECT Id, Name, Phone__c, Allocated_Project__c, Lead_Status__c, Owner.Name, CreatedDate
            FROM Lead
            WHERE Phone__c = :current.Phone__c AND Id != :recordId
            ORDER BY CreatedDate DESC
        ]) {
            LeadWrapper w = new LeadWrapper();
            w.id = l.Id;
            w.name = l.Name;
            w.phone = l.Phone__c;
            w.project = l.Allocated_Project__c;
            w.status = l.Lead_Status__c;
            w.ownerName = l.Owner.Name;
            w.createdDate = l.CreatedDate;
            w.recordUrl = '/lightning/r/Lead/' + l.Id + '/view';
            result.leads.add(w);
        }

        return result;
    }
}