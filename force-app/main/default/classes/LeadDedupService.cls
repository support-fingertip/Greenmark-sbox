public with sharing class LeadDedupService {

    // Wrapper for lead groups
    public class LeadGroup {
        public Id mainLeadId;
        public List<Lead> duplicates = new List<Lead>();
    }

    // Entry method (can run in anonymous)
    public static void consolidateDuplicateLeads() {
        // Step 1: Find groups of duplicate phone numbers
        List<AggregateResult> agg = [
            SELECT Phone__c phone, COUNT(Id) dupCount
            FROM Lead  WHERE Phone__c != null  GROUP BY Phone__c  HAVING COUNT(Id) > 1];

        if (agg.isEmpty()) {
            System.debug('No duplicates found.');
            return;
        }

        // Step 2: For each phone group, get all leads
        for (AggregateResult ar : agg) {
            String phone = (String) ar.get('phone');
            List<Lead> leads = [
                SELECT Id, Name, Phone__c,Allocated_Project__c,Tertiary_Source__c,Email,Sub_Source__c,Lead_source__c
                FROM Lead WHERE Phone__c = :phone ORDER BY CreatedDate ASC ];

            if (leads.size() < 2) continue;

            Lead mainLead = leads[0];
            List<Related_Source__c> sourcesToInsert = new List<Related_Source__c>();
             List<Lead> allDupLeadsToDelete = new List<Lead>();
            for (Integer i = 1; i < leads.size(); i++) {
                
                 Lead dup = leads[i];
                allDupLeadsToDelete.add(dup);
                sourcesToInsert.add(new Related_Source__c(
                    SLead__c     = mainLead.Id,
                    Phone__c    = dup.Phone__c,
                    Allocated_Project__c  = dup.Allocated_Project__c,
                    Source__c   = dup.Lead_source__c,
                    scheck__c=true,
                    Sub_Source__c= dup.Tertiary_Source__c
                ));

            }
            
             if (!sourcesToInsert.isEmpty()) {
            insert sourcesToInsert;
        }
        if (!allDupLeadsToDelete.isEmpty()) {
            delete allDupLeadsToDelete;
        }
        }
    }
    
     public static void consolidateDuplicateLeads2() {
        // Step 1: Find duplicate phone groups
        List<AggregateResult> agg = [
            SELECT Phone__c phone, COUNT(Id) dupCount
            FROM Lead
            WHERE Phone__c != null
            GROUP BY Phone__c
            HAVING COUNT(Id) > 1
        ];

        if (agg.isEmpty()) {
            System.debug('No duplicates found.');
            return;
        }

        // collect duplicate phone numbers
        Set<String> duplicatePhones = new Set<String>();
        for (AggregateResult ar : agg) {
            duplicatePhones.add((String)ar.get('phone'));
        }

        // Step 2: Query all leads for those phones in a single SOQL
        List<Lead> leads = [
             SELECT Id, Name, Phone__c,Allocated_Project__c,Tertiary_Source__c,Email,Sub_Source__c,Lead_source__c
               FROM Lead
            WHERE Phone__c IN :duplicatePhones
            ORDER BY Phone__c, CreatedDate ASC
        ];

        // Step 3: Group leads by phone number
        Map<String, List<Lead>> leadsByPhone = new Map<String, List<Lead>>();
        for (Lead l : leads) {
            if (!leadsByPhone.containsKey(l.Phone__c)) {
                leadsByPhone.put(l.Phone__c, new List<Lead>());
            }
            leadsByPhone.get(l.Phone__c).add(l);
        }

        // Step 4: Build related sources and collect duplicates
        List<Related_Source__c> allSourcesToInsert = new List<Related_Source__c>();
        List<Lead> allDupLeadsToDelete = new List<Lead>();

        for (String phone : leadsByPhone.keySet()) {
            List<Lead> groupLeads = leadsByPhone.get(phone);
            if (groupLeads.size() < 2) continue;

            Lead mainLead = groupLeads[0];
            for (Integer i = 1; i < groupLeads.size(); i++) {
                Lead dup = groupLeads[i];
                allDupLeadsToDelete.add(dup);

                allSourcesToInsert.add(new Related_Source__c(
                    SLead__c     = mainLead.Id,
                    Phone__c    = dup.Phone__c,
                    Allocated_Project__c  = dup.Allocated_Project__c,
                    Source__c   = dup.Lead_source__c,
                    scheck__c=true,
                    Sub_Source__c= dup.Tertiary_Source__c
                ));
            }
        }

        // Step 5: DML (only once each)
        if (!allSourcesToInsert.isEmpty()) {
            insert allSourcesToInsert;
        }
        if (!allDupLeadsToDelete.isEmpty()) {
            delete allDupLeadsToDelete;
        }

        System.debug('Consolidated ' + allDupLeadsToDelete.size() +
                     ' duplicates into ' + allSourcesToInsert.size() + ' Related Source records.');
    }
    
    
}