public with sharing class LeadStatusController {
    
    public static Boolean markleadUnqualified = false;
    
    @AuraEnabled
    public static DataBox getLeadRecordTypeName(Id leadId) {
        DataBox dt = new DataBox();
        Lead lead = [SELECT RecordType.Name,Name,Lead_Status__c,Open_Reason__c,Allocated_Reason__c,No_Of_Times_Unqualified__c,
                    Budget_Qualified__c, Possession__c, Configuration__c, Location_Qualified__c,Lead_Lost_Reasons__c,OwnerId,Previous_Stage__c
                     FROM Lead WHERE Id = :leadId LIMIT 1];
        
          List<Call_Detail__c> calls = [
             SELECT Id, Lead__c, OwnerId, Lead__r.OwnerId
             FROM Call_Detail__c
             WHERE Lead__c = :leadId and OwnerId =: lead.OwnerId
         ];
        
        dt.recordTypeName = lead.RecordType.Name;
        dt.openReason = GetPicklistValues.extractPicklistValues('Lead','Open_Reason__c');
        dt.qualificationReason = GetPicklistValues.extractPicklistValues('Lead','Allocated_Reason__c');
        dt.leadLostReason = GetPicklistValues.extractPicklistValues('Lead','Lead_Lost_Reasons__c');
        dt.closedLostReason = GetPicklistValues.extractPicklistValues('Lead','Closed_Lost_Reason__c');
        dt.quatationReason = GetPicklistValues.extractPicklistValues('Lead','Quotation_Reason__c'); 
        dt.curLead = lead;
        dt.callCount = calls.size() > 0 ? calls.size() : 0;
        
        return dt;
    }
    
    @AuraEnabled
    public static String updateLeadWithStatus(
        Id leadId, String status, DateTime scheduleDate, String rating, String othercom,
        String openreason, String alloctreason, boolean budget, boolean possession,
        boolean configuration, boolean location, Datetime svProposedDate
    ) {
        String returnmessage = '';
        
        Lead leadRecord = [
            SELECT Id, Status, RecordTypeId, RecordType.Name, Rating, Lead_Status__c,
            Unqualified_Reason__c, Last_Unqualified_At__c, Remark__c, OwnerId,
            Last_Unqualified_by__c, Mark_Unqualified__c, No_Of_Times_Unqualified__c,
            Lead_Assigned__c, Allocated_Project__c, No_of_Site_Visit__c,
            Budget_Qualified__c, Possession__c, Configuration__c, Location_Qualified__c
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];
        
        
        List<Lead_Unqualification__c> lqlst = new List<Lead_Unqualification__c>();
        
        try {
            List<Site_Visit__c> siteVisitList = [
                SELECT Id, Status__c
                FROM Site_Visit__c
                WHERE SLead__c = :leadId
            ];
            
            Boolean hasCompletedVisit = false;
            Boolean hasScheduledVisit = false;
            Boolean hasSvProposedVisit = false;
            Site_Visit__c svProposedSiteVist;
            
            List<Site_Visit__c> newSiteVistToUpsert = new List<Site_Visit__c>();
            
            for (Site_Visit__c sv : siteVisitList) {
                if (sv.Status__c == 'Completed' || sv.Status__c == 'Verified by GRE') hasCompletedVisit = true;
                else if (sv.Status__c == 'Scheduled' || sv.Status__c == 'Rescheduled') hasScheduledVisit = true;
                else if (sv.Status__c == 'SV Proposed') {
                    svProposedSiteVist = sv;
                    hasSvProposedVisit = true;
                }
            }

            // Open
            if (status == 'Open') {
                leadRecord.Open_Reason__c = openreason;
            }
            
            // Follow Ups
            if (status == 'Pre Sales Follow Up' || status == 'Sales Follow up') {
                insert new Follow_Up__c(
                    SLead__c = leadId,
                    Scheduled_Date__c = scheduleDate,
                    Subject__c = 'Follow up for ' + othercom,
                    Status__c = 'Scheduled'
                );
            }
            
            // Qualified → SV Proposed
            if (status == 'Qualified') {
                leadRecord.Budget_Qualified__c = budget;
                leadRecord.Possession__c = possession;
                leadRecord.Configuration__c = configuration;
                leadRecord.Location_Qualified__c = location;
                leadRecord.Allocated_Reason__c = alloctreason;
                
                if (alloctreason == 'SV Proposed') {

                    if (hasScheduledVisit) return 'Schduled_Visit_Existed';
                    if (hasSvProposedVisit) return 'SV_Proposed_Already_Exists';
                    String visitType = hasCompletedVisit ? 'Revisit' : 'First Site Visit';

                    Site_Visit__c sv = new Site_Visit__c(
                        SLead__c = leadId,
                        Status__c = 'SV Proposed',
                        Site_Visit_Type__c = visitType,
                        Project__c = leadRecord.Allocated_Project__c,
                        SV_Proposed_Date_Time__c = svProposedDate
                    );
                    newSiteVistToUpsert.add(sv);
                }
            }
            
            //  SV Scheduled
            if (status == 'SV Scheduled') {

                if (hasScheduledVisit) return 'Schduled_Visit_Existed';
                
                String visitType = hasCompletedVisit ? 'Revisit' : 'First Site Visit';
                
                if (svProposedSiteVist != null) {
                    svProposedSiteVist.Status__c = 'Scheduled';
                    svProposedSiteVist.Date__c = scheduleDate;
                    svProposedSiteVist.Site_Visit_Type__c = visitType;
                    svProposedSiteVist.Project__c = leadRecord.Allocated_Project__c;
                    svProposedSiteVist.Comments__c = othercom;
                    newSiteVistToUpsert.add(svProposedSiteVist);  
                }
                else {
                    Site_Visit__c newVisit = new Site_Visit__c(
                        SLead__c = leadId,
                        Date__c = scheduleDate,
                        Status__c = 'Scheduled',
                        Site_Visit_Type__c = visitType,
                        Project__c = leadRecord.Allocated_Project__c,
                        Comments__c = othercom
                    );
                    newSiteVistToUpsert.add(newVisit);
                }
            }
            
            // Quotation
            if (status == 'Quotation') {
                leadRecord.Quotation_Reason__c = rating;
            }
            
            leadRecord.Lead_Status__c = status;
            
            //  Lead Lost
            if (status == 'Lead Lost') {
                leadRecord.Lead_Lost_Reasons__c = rating;
                leadRecord.Last_Unqualified_At__c = System.now();
                leadRecord.Last_Unqualified_by__c = UserInfo.getUserId();
                leadRecord.Mark_Unqualified__c = true;
                leadRecord.No_Of_Times_Unqualified__c += 1;
                
                leadRecord.Lead_Assigned__c = false;
                leadRecord.Reasons_in_Detail__c = othercom;
                
                
                Lead_Unqualification__c lq = new Lead_Unqualification__c(
                    User__c = UserInfo.getUserId(),
                    Unqualified_Reason__c = (rating == 'Other') ? rating + ' : ' + othercom : rating,
                    Unqualified_At__c = System.now(),
                    Lead__c = leadRecord.Id,
                    Type__c = 'Pre Sales'
                );
                lqlst.add(lq);
                
                /*if (leadRecord.RecordType.Name == 'Pre Sales' && leadRecord.No_Of_Times_Unqualified__c < 3) {
                    markleadUnqualified = true;
                }*/
            }
            
            // Closed Lost
            if (status == 'Closed Lost') {
                User ur = [SELECT Id, ManagerId FROM User WHERE Id = :leadRecord.OwnerId];
                
                leadRecord.OwnerId = ur.ManagerId;
                leadRecord.Closed_Lost_Reason__c = rating;
                leadRecord.Reasons_in_Detail__c = othercom;
                leadRecord.Closed_Lost_At__c = System.now();
                leadRecord.Owner_Update_on_Closed_Lost_Sales__c = true;
                
                Lead_Unqualification__c lq = new Lead_Unqualification__c(
                    User__c = UserInfo.getUserId(),
                    Unqualified_Reason__c = rating + ' : ' + othercom,
                    Unqualified_At__c = System.now(),
                    Lead__c = leadRecord.Id,
                    Type__c = 'Sales'
                );
                lqlst.add(lq);
            }
            
            //Booked
            if(status =='Booked')
            {
                
                list<Quote__c> approvedQuations = [select id from Quote__c where SLead__c =:leadId and 
                                                   (Quote_status__c ='Management User Approved' OR Quote_status__c ='Converted' OR
                                                    Quote_status__c ='Sent to Customer') ];
                boolean noApprovedQuation = approvedQuations.size() > 0 ? false : true;
                
                if (noApprovedQuation) return 'Approved_Quation_Not_Existed';
                
                
                
                list<Booking__c> bookingsList = [select id from Booking__c where SLead__c =:leadId ];
                
                boolean nobookings = bookingsList.size() > 0 ? false : true;
                
                if (nobookings) return 'Booking_Not_Found';
                
            }
            
            if (!lqlst.isEmpty()) insert lqlst;
            
            update leadRecord;
            if(!newSiteVistToUpsert.isEmpty())
            {
                upsert newSiteVistToUpsert;
            }
            returnmessage = 'Updated Successully';
            
        } catch (Exception e) {
            return e.getMessage();
        }
        
        return returnmessage;
    }
    
    // Fix: Make DataBox class BEFORE using it
    public class DataBox {
        @AuraEnabled public String recordTypeName;
        @AuraEnabled public List<String> openReason;
        @AuraEnabled public List<String> qualificationReason;
        @AuraEnabled public List<String> leadLostReason;
        @AuraEnabled public List<String> closedLostReason;
        @AuraEnabled public List<String> quatationReason;
        @AuraEnabled public Lead curLead;
        @AuraEnabled public Integer callCount;
    }
}