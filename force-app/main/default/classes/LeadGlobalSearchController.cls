public without sharing class LeadGlobalSearchController {

    @AuraEnabled(cacheable=true)
    public static List<LeadSearchWrapper> searchLead(String searchText) {

        if (String.isBlank(searchText)) {
            return new List<LeadSearchWrapper>();
        }

        String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Profile.Name;
        Boolean showLostDates = new Set<String>{
            'CP Coordinator', 'CP Head', 'CRM Executive', 'System Administrator'
        }.contains(profileName);

        String leadIdKey = 'Ld-' + searchText;

        Map<Id, Lead> leadMap = new Map<Id, Lead>();

        //  Search ALL Leads (without sharing)
        List<Lead> leads = [
            SELECT Id, Name, Phone__c, Secondary_Phone__c, Email, Lead_ID__c,
                   Lead_Status__c, Allocated_Project__c,Primary_Phone1__c,Secondary_Phone1__c,
                   Last_Unqualified_At__c, Closed_Lost_At__c,
                   Owner.Name
            FROM Lead
            WHERE Name LIKE :('%' + searchText + '%')
               OR Phone__c = :searchText
               OR Secondary_Phone__c = :searchText
               OR Email = :searchText
               OR Lead_ID__c = :leadIdKey
               OR  Lead_ID__c = :searchText
            LIMIT 20
        ];

        for (Lead ld : leads) {
            leadMap.put(ld.Id, ld);
        }
        // If no direct Lead → search Related Source
        if (leadMap.isEmpty()) {
            List<Related_Source__c> rsList = [
                SELECT SLead__c,
                SLead__r.Id, SLead__r.Name, SLead__r.Phone__c,
                SLead__r.Secondary_Phone__c, SLead__r.Email,
                SLead__r.Lead_ID__c, SLead__r.Lead_Status__c,
                SLead__r.Allocated_Project__c,
                SLead__r.Primary_Phone1__c,
                SLead__r.Secondary_Phone1__c,
                SLead__r.Last_Unqualified_At__c,
                SLead__r.Closed_Lost_At__c,
                SLead__r.Owner.Name
                FROM Related_Source__c
                WHERE Phone__c = :searchText
                   OR Secondary_Phone__c = :searchText
                LIMIT 20
            ];

            for (Related_Source__c rs : rsList) {
                if (rs.SLead__c != null) {
                    leadMap.put(rs.SLead__c, rs.SLead__r);
                }
            }
        }

        if (leadMap.isEmpty()) {
            return new List<LeadSearchWrapper>();
        }

  
        Map<Id, Boolean> accessMap = new Map<Id, Boolean>();

        for (UserRecordAccess ura : [
            SELECT RecordId, HasReadAccess
            FROM UserRecordAccess
            WHERE UserId = :UserInfo.getUserId()
              AND RecordId IN :leadMap.keySet()
        ]) {
            accessMap.put(ura.RecordId, ura.HasReadAccess);
        }

        List<LeadSearchWrapper> result = new List<LeadSearchWrapper>();

        for (Lead ld : leadMap.values()) {
            Boolean hasAccess = accessMap.containsKey(ld.Id)
                ? accessMap.get(ld.Id)
                : false;

            result.add(new LeadSearchWrapper(ld, hasAccess, showLostDates));
        }

        return result;
    }

    //  Wrapper
    public class LeadSearchWrapper {
        @AuraEnabled public Id leadId;
        @AuraEnabled public String name;
        @AuraEnabled public String phone;
        @AuraEnabled public String email;
        @AuraEnabled public String status;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String project;
        @AuraEnabled public Boolean showOpenLead;
        @AuraEnabled public DateTime leadLostDate;
        @AuraEnabled public DateTime closedLostDate;
        @AuraEnabled public Boolean showLostDates;

        public LeadSearchWrapper(Lead ld, Boolean hasAccess, Boolean showLostDates) {
            leadId = ld.Id;
            name = ld.Name;
            phone = ld.Primary_Phone1__c;
            email = ld.Email;
            status = ld.Lead_Status__c;
            ownerName = ld.Owner.Name;
            project = ld.Allocated_Project__c;
            showOpenLead = hasAccess;
            this.showLostDates = showLostDates && (ld.Lead_Status__c =='Lead Lost' ||  Ld.Lead_Status__c =='Closed Lost');
            if (showLostDates && (ld.Lead_Status__c =='Lead Lost' ||  Ld.Lead_Status__c =='Closed Lost')) {
                leadLostDate = ld.Last_Unqualified_At__c;
                closedLostDate = ld.Closed_Lost_At__c;
            }
            else
            {
                leadLostDate = null;
                closedLostDate = null;
            }
      
        }
    }
}