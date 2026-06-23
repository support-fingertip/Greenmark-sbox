public without sharing class SiteVisitFormController {
    public class DataBox
    {
        @AuraEnabled public List<String> projects = new List<String> ();
        @AuraEnabled public List<String> siteVisitRatings = new List<String> ();
        @AuraEnabled public Map<String, String> countryMap = new Map<String, String> ();
        @AuraEnabled public Map<String, Map<String, String>> sourceToSubSoruce = new  Map<String, Map<String, String>>();
        @AuraEnabled public Lead Lead;
        @AuraEnabled public Site_Visit__c siteVisit;
        
        @AuraEnabled public list<Channel_Partner__c> channelPatnerList;
        @AuraEnabled public list<User> CpUsersList;
        
        @AuraEnabled public boolean autoMapSoucingMember;
        @AuraEnabled public boolean autoMapChannelPartner;
    }
    @AuraEnabled
    public static DataBox getData() {
        DataBox dt = new DataBox();
        dt.projects = GetPicklistValues.extractPicklistValues('Lead','Allocated_Project__c');
        dt.siteVisitRatings = GetPicklistValues.extractPicklistValues('Site_Visit__c','Site_Visit_rating__c');
        Map<String, String> countryMap = new Map<String, String>();
        List<Country_Code_Mapping__mdt> countryMetadata = [SELECT Label, CountryCode__c FROM Country_Code_Mapping__mdt ];
        for (Country_Code_Mapping__mdt country : countryMetadata) {
            countryMap.put(country.Label, country.CountryCode__c);
        }
        dt.countryMap = countryMap;
        dt.sourceToSubSoruce = getDependentMap(new Lead(), 'Source_Type__c', 'Lead_source__c');
        dt.channelPatnerList = [select Id,Name from Channel_Partner__c where Active__c = true];
        dt.CpUsersList = [select Id,Name from User where Profile.Name ='CP Sourcing Member'];
        return dt;
    }
    @AuraEnabled
    public static String checkLeadWithPhoneProject(String project_name, String searchText) {
        Boolean isLeadExists;
        String jsonResponse;
        String leadIdPrefix = searchText;
        String leadIdWithoutPrefix = 'Ld-'+searchText;
        String leadIdPrefixWithProject = leadIdPrefix + project_name;
        String leadIdWithoutPrefixWithProject = leadIdWithoutPrefix + project_name;
        
        String searchTextProject = searchText + project_name;
        if (searchText != null && project_name != null) {
            List<Lead> leadList = [SELECT Name,Status,Lead_Status__c,Site_Visit_Conducted_Date__c,Lead_source__c,
                                   Lead_Age__c,Lead_OwnerSecondary__c,Lead_OwnerSecondary__r.Name,Owner.Name,PhoneProject__c,
                                   Secondary_Phone_Project__c, Phone__c, Email, Secondary_Phone__c, Allocated_Project__c
                                   FROM Lead WHERE (PhoneProject__c = :searchTextProject or Secondary_Phone_Project__c =:searchTextProject
                                                    Or SecondaryEmailProject__c =:searchTextProject OR PrimaryEmailProject__c =:searchTextProject OR
                                                    LeadIdProject__c =:leadIdPrefixWithProject OR LeadIdProject__c =:leadIdWithoutPrefixWithProject  )
                                   LIMIT 1 ];
            
            List<Related_Source__c> reList = [SELECT SLead__r.Id,SLead__r.Lead_source__c,SLead__r.Site_Visit_Conducted_Date__c,
                                              SLead__r.Lead_Age__c,SLead__r.Lead_OwnerSecondary__c,SLead__r.Lead_OwnerSecondary__r.Name,
                                              SLead__r.Owner.Name,SLead__r.Status,SLead__r.Lead_Status__c,SLead__r.Name,SLead__r.Phone__c,
                                              PhoneProject__c,SecondaryPhoneProject__c
                                              FROM Related_Source__c WHERE 
                                              (PhoneProject__c = :searchTextProject or SecondaryPhoneProject__c =:searchTextProject) LIMIT 1 ];
            String leadname;
            String OwnerName;
            String leadId;
            String phone;
            String leadStatus;
            if (!leadList.isEmpty()) {
                Lead ld = leadList[0];
                leadname = ld.Name;
                phone = ld.Phone__c;
                leadId = ld.Id;
                
                if(ld.Lead_Status__c != 'Lead Lost' && ld.Lead_Status__c != 'Closed Lost'){
                    leadStatus = 'Active Lead Exist';
                    isLeadExists = true;
                }
                else{
                    leadStatus = 'Lead exists but In-Active';
                    isLeadExists = true;
                }
            }
            else if(!reList.isEmpty()){
                Related_Source__c rd = reList[0];
                leadname = rd.SLead__r.Name;
                phone = rd.SLead__r.Phone__c;
                leadId = rd.SLead__r.Id;
                if(rd.SLead__r.Lead_Status__c != 'Lead Lost' || rd.SLead__r.Lead_Status__c != 'Closed Lost'){
                    leadStatus = 'Active Lead Exist';
                    isLeadExists = true;
                }
                else{
                    leadStatus = 'Lead exists but In-Active';
                    isLeadExists = true;
                }
            } 
            else {
                leadStatus = 'No Lead Exists';
                isLeadExists = false;
            }
            jsonResponse = '{';
            if(isLeadExists == true){
                jsonResponse += '"leadId":"' + leadId + '",';
                jsonResponse += '"leadname":"' + leadname + '",';
                jsonResponse += '"phone":"' + phone + '",';
                jsonResponse += '"leadStatus":"' + leadStatus + '"';
            }
            else{
                jsonResponse += '"leadStatus":"' + leadStatus + '"';
            }
            jsonResponse += '}';
        }
        return jsonResponse;
    }
    @AuraEnabled
    public static DataBox getLead(String leadId) {
        DataBox dt = new DataBox();
        dt.Lead =  [select id,LastName,Name,Phone__c,Lead_Owner_Full_Name__c,OwnerId,Lead_Owner_Profile__c,Source_Type__c,Lead_source__c,Secondary_Phone__c,Credit_Channel_Partner__c,
                    Credit_Channel_Partner__r.Name,Sourcing_Member__r.Name,Sourcing_Member__c, Email,Lead_ID__c, Secondary_Email__c,Lead_Status__c,
                    Credit_Source__c,Credit_Sub_Source__c from Lead where Id =: leadId Limit 1];
        list<Site_Visit__c> siteVisitList = [select Id,Name,Date__c,Site_Visit_Create_Owner__c,SDate__c from Site_Visit__c
                                             where SLead__c =:leadId and (Status__c ='Scheduled' OR Status__c ='Rescheduled') limit 1];
        // Assign Site Visit (null if not found)
        dt.siteVisit = (siteVisitList.isEmpty() ? null : siteVisitList[0]);
        dt.autoMapSoucingMember = dt.Lead.Lead_Owner_Profile__c == 'CP Sourcing Member';
        dt.autoMapChannelPartner = dt.Lead.Credit_Source__c == 'Channel Partner';
        return dt;
    }
    /**
    * Creates or updates a Site Visit based on the provided details.
    * @param remark Notes or feedback for the visit.
    * @param svDate Date and time of the site visit.
    * @param selectedProject Associated project ID.
    * @param mobileOrLeadId Mobile number or Lead ID used to identify the lead.
    * @param selectedUser (Optional) User ID who attended the visit.
    */
    @AuraEnabled
    public static void createSv(String remark, Datetime svDate, String selectedProject, String leadId, String selectedRating,String sourcingMember, String channelPartner,String location) {
        
        System.debug('Input Params => Remark: ' + remark + ', SV Date: ' + svDate + ', Project: ' + selectedProject +
                     ',leadId: ' + leadId + ', selectedRating: ' + selectedRating);
        //=====================
      	//Lead Pushing to Sales
      	//=====================
        Lead ld = [SELECT Id,Lead_Status__c,Pre_sales_user__c,OwnerId,Lead_Transfer_Note__c,RecordTypeId,Sales_user__c,
                   Lead_Assigned__c,Allocated_Project__c,Pushed_On__c,Pushed_By__c,Lead_Owner_Profile__c,Push_To_Sales__c
                   FROM Lead WHERE Id=:LeadId];
        ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        ld.Pushed_On__c = system.now();
        ld.Pushed_By__c = UserInfo.getUserId();
        //If Lead is in Sales not Closed lost Stage if pre sales user also sales user 
        //then lead owner will become the sales user
        //if lead is in sales and closed lost or pre sales it will push to sales
        if(ld.Lead_Owner_Profile__c == 'Sales' && ld.Lead_Status__c != 'Closed Lost')
        {
            ld.Lead_Assigned__c = true;
            ld.Sales_User__c = ld.OwnerId;
            ld.Push_To_Sales__c = false;
        }
        else
        {
            ld.Lead_Assigned__c = false;
            ld.Push_To_Sales__c = true;
        }
        ld.IsPushed__c=true;
        ld.Lead_Transfer_Note__c= remark;
        update ld;
        
        //====================================
        //Mark schduled Followups as completed
        //====================================
        try {
            List<Follow_up__c> followupList = [
                SELECT Id, Name, Status__c
                FROM Follow_up__c
                WHERE SLead__c =:leadId AND Status__c = 'Scheduled' 
            ];
            if (!followupList.isEmpty()) {
                for (Follow_up__c follow : followupList) {
                    follow.Status__c = 'Completed';
                    follow.Comments__c = 'Completed By System from GRE';
                }
                update followupList;
            }
        }
        catch (Exception followupEx) {
            System.debug('Follow-up update failed: ' + followupEx.getMessage());
        }
        
        //===========================
        //Site Visit Update and Create
        ////==========================
        list<Site_visit__c> siteVisitList = [ SELECT Id, SV_Completed_Date_Time__c, Status__c, OwnerId, Feedback__c, SLead__c,
                                             Revisit_Count__c,Revisit_Details__c FROM Site_visit__c WHERE SLead__c  =:leadId];              
        
        // Initialize control flags
        Boolean hasCompletedVisit = false;
        Boolean hasScheduledVisit = false;
        Boolean hasSvProposedVisit = false;
        
        Site_Visit__c visit = new Site_Visit__c();
        // Analyze existing visits
        for (Site_Visit__c sv : siteVisitList) {
            if (sv.Status__c == 'Completed' || sv.Status__c == 'Verified by GRE') {
                hasCompletedVisit = true;
            }else if (sv.Status__c == 'Scheduled'  || sv.Status__c == 'Rescheduled') {
                hasScheduledVisit = true;
                visit = sv;
            }else if(sv.Status__c == 'SV Proposed')
            {
                visit = sv;
                hasSvProposedVisit = true;
            }
        }
        
        if(hasScheduledVisit)
        {
            visit.GRE_Verified_Time__c = svDate;
            visit.Site_Visit_Entry_Time__c = svDate;
            visit.Status__c = 'Verified by GRE';
            if(ld.Sales_user__c != null)
            {
                visit.OwnerId = ld.Sales_user__c;
            }
            visit.Comments__c = remark;
            visit.Project__c = selectedProject;
            visit.Location__c = location;
            if(channelPartner != null && channelPartner != '')
            {
                visit.Channel_Partner__c = channelPartner;
            }
            if(sourcingMember != null && sourcingMember != '')
            {
                visit.Sourcing_Member__c = sourcingMember;
            }
            update visit;   
        }
        else if(hasSvProposedVisit)
        {
            visit.GRE_Verified_Time__c = svDate;
            visit.Site_Visit_Entry_Time__c = svDate;
            visit.Date__c = svDate;
            if(ld.Sales_user__c != null)
            {
                visit.OwnerId = ld.Sales_user__c;
            }
            visit.Status__c = 'Verified by GRE';
            visit.Comments__c = remark;
            visit.Project__c = selectedProject;
            visit.Location__c = location;
            if(channelPartner != null && channelPartner != '')
            {
                visit.Channel_Partner__c = channelPartner;
            }
            if(sourcingMember != null && sourcingMember != '')
            {
                visit.Sourcing_Member__c = sourcingMember;
            }
            update visit;   
        }
        else
        {
            // Determine visit type
            String visitType = hasCompletedVisit ? 'Revisit' : 'First Site Visit';
            
            // Create new visit record
            Site_Visit__c newVisit = new Site_Visit__c();
            newVisit.SLead__c = leadId;
            newVisit.Date__c = svDate;
            newVisit.GRE_Verified_Time__c = svDate;
            newVisit.Site_Visit_Entry_Time__c = svDate;
            if(ld.Sales_user__c != null)
            {
                newVisit.OwnerId = ld.Sales_user__c;
            }
            newVisit.Status__c = 'Verified by GRE';
            newVisit.Site_Visit_Type__c = visitType;
            newVisit.Project__c = selectedProject;
            newVisit.Comments__c = remark;
            newVisit.Location__c = location;
            if(channelPartner != null && channelPartner != '')
            {
                newVisit.Channel_Partner__c = channelPartner;
            }
            if(sourcingMember != null && sourcingMember != '')
            {
                newVisit.Sourcing_Member__c = sourcingMember;
            }
            insert newVisit;
        }
        
    }
    @AuraEnabled
    public static void leadNotExists(Id leadId,String selectedRating, String remark) {
        //Once lead is created it will create new visit
        Lead ld = [select id,name,Lead_source__c,Sub_Source__c,Pre_sales_user__c,Sales_user__c,Allocated_Project__c,OwnerId from Lead where Id =: leadId];
        Site_Visit__c sv = new Site_Visit__c();
        sv.SLead__c = ld.Id;
        sv.Date__c = Datetime.now().addMinutes(1);
        sv.Source__c = ld.Lead_source__c;
        sv.OwnerId = ld.OwnerId;
        sv.Project__c = ld.Allocated_Project__c;
        sv.GRE_Verified_Time__c = Datetime.now().addMinutes(1);
        sv.Site_Visit_Entry_Time__c = Datetime.now().addMinutes(1);
        sv.Status__c = 'Verified by GRE';
        sv.Comments__c = remark;
        insert sv;
        
        //ld.OwnerId = ld.Sales_User__c;
        //ld.Pre_sales_user__c = ld.Sales_User__c;
        ld.Lead_Status__c = 'SV Scheduled';
        ld.Site_Visit_Conducted_Date__c = system.now();
        update ld;
    }

    
    //To get dependent picklist and picklist values
    @AuraEnabled
    public static Map<String, Map<String, String>> getDependentMap(SObject objDetail, String contrFieldApiName, String depFieldApiName) {
        Map<String, Map<String, String>> objResults = new Map<String, Map<String, String>>();
        
        Schema.sObjectType objType = objDetail.getSObjectType();
        if (objType == null) return objResults;
        
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        if (!objFieldMap.containsKey(contrFieldApiName) || !objFieldMap.containsKey(depFieldApiName)) return objResults;
        
        Schema.SObjectField ctrlField = objFieldMap.get(contrFieldApiName);
        Schema.SObjectField depField = objFieldMap.get(depFieldApiName);
        
        List<Schema.PicklistEntry> ctrlEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(depField.getDescribe().getPicklistValues());
        
        List<String> ctrlValues = new List<String>();
        for (Schema.PicklistEntry ple : ctrlEntries) {
            String label = ple.getLabel();
            String value = ple.getValue();
            objResults.put(value, new Map<String, String>());
            ctrlValues.add(value);
        }
        
        Integer index = 0;
        for (PicklistEntryWrapper depEntry : depEntries) {
            String depLabel = depEntry.label;
            String depValue = depEntry.value;
            String validForBits = base64ToBits(depEntry.validFor);
            
            for (Integer i = 0; i < validForBits.length(); i++) {
                if (validForBits.mid(i, 1) == '1') {
                    objResults.get(ctrlValues.get(i)).put(depLabel, depValue);
                }
            }
        }
        
        
        return objResults;
    }
    public static List<Map<String, String>> extractPicklistValues(String objectName, String fieldName) {
        // Get the global describe map
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        
        // Check if the object exists
        if (!schemaMap.containsKey(objectName)) {
            return new List<Map<String, String>>();
        }
        
        Schema.DescribeSObjectResult objDescribe = schemaMap.get(objectName).getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        
        // Check if the field exists in the object
        if (!fieldMap.containsKey(fieldName)) {
            return new List<Map<String, String>>();
        }
        
        Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldName).getDescribe();
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();
        
        if (fieldResult != null && fieldResult.getType() == Schema.DisplayType.Picklist) {
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                picklistValues.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                        'value' => entry.getValue()
                        });
            }
        }
        return picklistValues;
    }
    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';
        String validForBits = '';
        
        for (Integer i = 0; i < validFor.length(); i++) {
            Integer val = base64Chars.indexOf(validFor.mid(i, 1));
            validForBits += decimalToBinary(val).leftPad(6, '0');
        }
        return validForBits;
    }
    public static final String base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            bits = String.valueOf(Math.mod(val, 2)) + bits;
            val = val / 2;
        }
        return bits;
    }
    public static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>) JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }
    public class PicklistEntryWrapper {
        public String label {get;set;}
        public String value {get;set;}
        public String validFor {get;set;}
    }
    
}