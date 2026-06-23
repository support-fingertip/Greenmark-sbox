public class newSiteVisitController {
     public class DataBox
    {
        @AuraEnabled public String recordTypeName;
        @AuraEnabled public List<String> projects = new List<String> ();
        @AuraEnabled public List<String> status = new List<String> ();
        @AuraEnabled public List<String> siteVisitTypes = new List<String> ();
        @AuraEnabled public Lead lead;
        @AuraEnabled public String siteVisitType;
        @AuraEnabled public String ownerId;
        @AuraEnabled public boolean schduledVisitExisted;
    }
    @AuraEnabled
    public static DataBox getLeadDetails(string leadId)
    {
        DataBox dt = new DataBox();
        Lead lead = [SELECT RecordType.Name,Allocated_Project__c,OwnerId,Id,Name FROM Lead WHERE Id = :leadId LIMIT 1];
        dt.lead = lead;
        list<Site_Visit__c> lstVisits = [select id,Status__c from Site_Visit__c where Slead__c =:leadId ];
        
        list<Site_visit__c> siteVisitList = [ SELECT Id, SV_Completed_Date_Time__c, Status__c, OwnerId, Feedback__c, SLead__c,
                                             Revisit_Count__c,Revisit_Details__c FROM Site_visit__c WHERE SLead__c  =:leadId]; 
        Boolean hasScheduledVisit = false;
        // Analyze existing visits
        for (Site_Visit__c sv : siteVisitList) {
            if (sv.Status__c == 'Scheduled' || sv.Status__c == 'Rescheduled') {
                hasScheduledVisit = true;
            }
        }

        
        
        
        dt.schduledVisitExisted = hasScheduledVisit ? true :false;
        dt.recordTypeName = lead.RecordType.Name;
        dt.siteVisitType = lstVisits.isEmpty() ? 'First Site Visit' : 'Revisit';
        dt.projects = GetPicklistValues.extractPicklistValues('Site_Visit__c','Project__c');
        dt.status = GetPicklistValues.extractPicklistValues('Site_Visit__c','Status__c');
        dt.siteVisitTypes = GetPicklistValues.extractPicklistValues('Site_Visit__c','Site_Visit_Type__c');
        return dt;
    }
    @Testvisible
    private static List<String> getPicklistValuesForField(String objectName, String fieldName) {
        List<String> picklistValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            picklistValues.add(entry.getLabel());
        }
        return picklistValues;
    }
    @AuraEnabled
    public static String saveSiteVisit(Site_Visit__c siteVisitData) {
        list<Site_visit__c> siteVisitList = [ SELECT Id, SV_Completed_Date_Time__c, Status__c, OwnerId, Feedback__c, SLead__c,
                                             Revisit_Count__c,Revisit_Details__c FROM Site_visit__c WHERE SLead__c  =:siteVisitData.SLead__c]; 
        
        lead ld = new lead();
        ld.Id = siteVisitData.SLead__c;
        ld.Lead_Status__c = 'SV Scheduled';
        update ld;
        
        
        // Initialize control flags
        Boolean hasCompletedVisit = false;
        Boolean hasScheduledVisit = false;
        Boolean hasSvProposedVisit = false;
        Site_Visit__c svProposedSiteVist;
        
        // Analyze existing visits
        for (Site_Visit__c sv : siteVisitList) {
            if (sv.Status__c == 'Completed'  || sv.Status__c == 'Verified by GRE') {
                hasCompletedVisit = true;
            } else if (sv.Status__c == 'Scheduled' || sv.Status__c =='Rescheduled' ) {
                hasScheduledVisit = true;
            }
            else if (sv.Status__c == 'SV Proposed') {
                svProposedSiteVist = sv;
                hasSvProposedVisit = true;
            }
        }
        
        // Prevent duplicate scheduling
        if (hasScheduledVisit) {
            return 'Schduled_Visit_Existed';
        }
        
        
        String visitType = hasCompletedVisit ? 'Revisit' : 'First Site Visit';
        if (svProposedSiteVist != null) {
            svProposedSiteVist.Status__c = 'Scheduled';
            svProposedSiteVist.Date__c = siteVisitData.Date__c;
            svProposedSiteVist.Site_Visit_Type__c = visitType;
            svProposedSiteVist.Project__c = siteVisitData.Project__c;
            svProposedSiteVist.Comments__c = siteVisitData.Comments__c;
            update svProposedSiteVist;
        }
        else{
            // Determine visit type
            siteVisitData.Site_Visit_Type__c = visitType;
            insert siteVisitData;
        }
        
        
       
        
        return siteVisitData.SLead__c;
    }
    
}