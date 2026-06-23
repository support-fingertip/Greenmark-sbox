public without sharing class RelatedSourceHandler {
    
    public static List<Lead> deleteList = new List<Lead>();
    public static List<Lead> updateList = new List<Lead>();
    public static List<Related_source__c> rsList = new List<Related_source__c>();
    public static Map<Id,Lead> matchedMap = new  Map<Id,Lead>();
    public static datetime startTime;
    public static datetime endTime;  
    
    public static void cpmethod (list<Lead> ldlst){
        Map<String, Channel_partner__c> cpMap = new Map<String, Channel_partner__c>();
        
        // Populate the map with active channel partners
        for(Channel_partner__c cp : [SELECT Id, OwnerId, ContactPerson__c, Active__c FROM Channel_partner__c WHERE Active__c = true]) {
            cpMap.put(cp.Id, cp);
        }
        
        // Iterate through each lead and update Sub_Source__c
        for(Lead ld : ldlst) {
            // Ensure that the Channel_partner__c field is not null and exists in the map
            if (ld.Channel_partner__c != null && cpMap.containsKey(ld.Channel_partner__c)) {
                ld.Sub_Source__c = cpMap.get(ld.Channel_partner__c).ContactPerson__c;
                ld.OwnerId = cpMap.get(ld.Channel_partner__c).OwnerId;
            } else {
                // Handle the case where there's no corresponding Channel Partner
                // Optionally, you can set a default value or log it
                ld.Sub_Source__c = 'Default Value'; // Or handle as needed
            }
        }
    }
    
    public static void checkMobileNumber2(List<Lead> newRecordsList) {
        Map<String, String> countryCodeMap = Utility.getAllCountryCodeMappings(true);
        
        for (Lead contact : newRecordsList) { 
            processPhoneNumber(contact, countryCodeMap, true);
            // processPhoneNumber(contact, countryCodeMap, false);
        }
    }
    @testvisible
    public static void processPhoneNumber(Lead contact, Map<String, String> countryCodeMap, Boolean isPrimary) {
        String phoneField = isPrimary ? contact.Phone__c : contact.Secondary_Phone__c;
        if (phoneField == null) return;
        
        phoneField = phoneField.replaceAll('\\s+', '');
        phoneField = contactFormatter.getformated(phoneField); 
        
        if (!phoneField.startsWith('+')) {
            // If number does not start with '+', treat as Indian number
            phoneField = ensureTenDigitNumber(phoneField);
            if (isPrimary) {
                contact.Country_Code__c = '91';
                contact.Country__c = countryCodeMap.get('91');
                contact.Phone__c = phoneField;
            } else {
                contact.Secondary_Country_Code__c = '91';
                contact.Secondary_Country__c = countryCodeMap.get('91');
                contact.Secondary_Phone__c = phoneField;
            }
            return;
        }
        system.debug(phoneField);
        //  If number starts with '+', remove '+'
        //  phoneField = phoneField.replace('\\+', ''); 
        phoneField = phoneField.replace('+', '');
        System.debug(phoneField);
        for (String countryCode : countryCodeMap.keySet()) {
            if (phoneField.startsWith(countryCode)) {
                phoneField = phoneField.replaceFirst('^' + countryCode, ''); // Remove country code
                
                //  Adjust phone number length based on country
                phoneField = ensureCorrectPhoneLength(phoneField, countryCode);
                system.debug(phoneField);
                if (isPrimary) {
                    contact.Country_Code__c = countryCode;
                    contact.Country__c = countryCodeMap.get(countryCode);
                    contact.Phone__c = phoneField;
                } else {
                    contact.Secondary_Country_Code__c = countryCode;
                    contact.Secondary_Country__c = countryCodeMap.get(countryCode);
                    contact.Secondary_Phone__c = phoneField;
                }
                return;
            }
        }
        
        //  Default to India if country is not found
        phoneField = ensureTenDigitNumber(phoneField);
        system.debug(phoneField);
        if (isPrimary) {
            contact.Country_Code__c = '91';
            contact.Country__c = countryCodeMap.get('91');
            contact.Phone__c = phoneField;
        } else {
            contact.Secondary_Country_Code__c = '91';
            contact.Secondary_Country__c = countryCodeMap.get('91');
            contact.Secondary_Phone__c = phoneField;
        }
    }
    
    // Ensures the phone number is exactly 10 digits long (for India)
    private static String ensureTenDigitNumber(String phone) {
        if (phone.length() > 10) {
            return phone.substring(phone.length() - 10); // Keep last 10 digits
        }
        return phone;
    }
    
    // Ensures phone length based on country (modify for other country rules if needed)
    private static String ensureCorrectPhoneLength(String phone, String countryCode) {
        if (countryCode == '91' && phone.length() > 10) {
            return phone.substring(phone.length() - 10); // For India, keep last 10 digits
        }
        return phone; // Otherwise, return as is (modify if you have length constraints for other countries)
    }

    // Duplication check with only contact info and project(phone+project,secondary phone+project,Email+project,Secondary Email+Project)
    public static void duplicateCheck2(List<Lead> ldList){
        Set <String> PhoneSet = new Set<String>();
        Set <String> mailSet = new Set<String>();
        for(Lead ld : ldList){
            string allocatedProject='';
            if(ld.Allocated_project__c !=null){
                allocatedProject = ld.Allocated_project__c;
            }
            if(ld.Phone__c !=null){
                PhoneSet.add(ld.Phone__c+allocatedProject);
            }
            if(ld.Secondary_Phone__c !=null){
                PhoneSet.add(ld.Secondary_Phone__c+allocatedProject);
            }
            /*if(ld.Email !=null){
                mailSet.add(ld.Email+allocatedProject);
            }
            if(ld.Secondary_Email__c !=null){
                mailSet.add(ld.Secondary_Email__c+allocatedProject);
            }*/
        }
        List<Lead> oldLeadList = [SELECT Id,PhoneProject__c,Secondary_Phone_Project__c,SecondaryEmailProject__c,
                                  EmailProject__c,Phone,Email,Secondary_phone__c,Secondary_Email__c,Phone__c FROM Lead WHERE
                                  (PhoneProject__c IN : PhoneSet OR Secondary_Phone_Project__c IN :PhoneSet 
                                  /* OR EmailProject__c IN :mailSet OR SecondaryEmailProject__c IN:mailSet*/)
                                  ORDER BY CreatedDate ASC];
        system.debug(oldLeadList.size());
        if(oldLeadList.size()>0){
            Map<string,Lead> emailMap = new Map<string,Lead>();
            
            Map<string,Lead> PhoneMap = new Map<string,Lead>();
            
            for(Lead old : oldLeadList){
                if(old.PhoneProject__c !=null){
                    PhoneMap.put(old.PhoneProject__c,old);
                }
                if(old.Secondary_Phone_Project__c !=null){
                    PhoneMap.put(old.Secondary_Phone_Project__c,old);
                }
                if(old.SecondaryEmailProject__c !=null){
                    emailMap.put(old.SecondaryEmailProject__c,old);
                } if(old.EmailProject__c !=null){
                    emailMap.put(old.EmailProject__c,old);
                }

            }
            for(Lead nld : ldList){
                string allocatedProject='';
                if(nld.Allocated_Project__c!=null){
                    allocatedProject = nld.Allocated_Project__c;
                }
                if(nld.Phone__c !=null && PhoneMap.containsKey(nld.Phone__c+allocatedProject)){
                    nld.Delete_Lead__c = true;
                    nld.Main_Lead__c = PhoneMap.get(nld.Phone__c+allocatedProject).Id;
                }else if(nld.Secondary_phone__c !=null && PhoneMap.containsKey(nld.Secondary_phone__c+allocatedProject)){
                    nld.Delete_Lead__c = true;
                    nld.Main_Lead__c = PhoneMap.get(nld.Secondary_phone__c+allocatedProject).Id;
                }
                else if(nld.Secondary_Email__c !=null && emailMap.containsKey(nld.Secondary_Email__c+allocatedProject)){
                    nld.Delete_Lead__c = true;
                    nld.Main_Lead__c = emailMap.get(nld.Secondary_Email__c+allocatedProject).Id;
                }else if(nld.Email !=null && emailMap.containsKey(nld.Email+allocatedProject)){
                    nld.Delete_Lead__c = true;
                    nld.Main_Lead__c = emailMap.get(nld.Email+allocatedProject).Id;
                }
            } 
            
        }
        else{
            List<Related_Source__c> oldList = [SELECT Id,Name,SecondaryEmailProject__c,PhoneProject__c,SecondaryPhoneProject__c,EmailProject__c,SLead__c FROM Related_Source__c 
                                               WHERE (PhoneProject__c IN : PhoneSet OR SecondaryPhoneProject__c IN :PhoneSet OR EmailProject__c IN : mailSet OR SecondaryEmailProject__c IN : mailSet) AND SLead__c!=null ORDER BY CreatedDate ASC];
            system.debug(oldList);
            Map<string,Related_Source__c> emailMap = new Map<string,Related_Source__c>();
            
            Map<string,Related_Source__c> PhoneMap = new Map<string,Related_Source__c>();
            
            if(oldList.size() >0){
                for(Related_Source__c old : oldList){
                    
                    if(old.PhoneProject__c !=null){
                        PhoneMap.put(old.PhoneProject__c,old);
                    }
                    if(old.SecondaryPhoneProject__c !=null){
                        PhoneMap.put(old.SecondaryPhoneProject__c,old);
                    }
                    /*if(old.EmailProject__c !=null){
                        emailMap.put(old.EmailProject__c,old);
                    }
                    if(old.SecondaryEmailProject__c !=null){
                        emailMap.put(old.SecondaryEmailProject__c,old);
                    }*/
                }
                
                for(Lead nld : ldList){
                    string allocatedProject='';
                    if(nld.Allocated_project__c !=null){
                        allocatedProject = nld.Allocated_project__c;
                    }
                    if(nld.Phone__c !=null && PhoneMap.containsKey(nld.Phone__c+allocatedProject)){
                        nld.Delete_Lead__c = true;
                        nld.Main_Lead__c = PhoneMap.get(nld.Phone__c+allocatedProject).SLead__c;
                    }else if(nld.Secondary_phone__c !=null && PhoneMap.containsKey(nld.Secondary_phone__c+allocatedProject)){
                        nld.Delete_Lead__c = true;
                        nld.Main_Lead__c = PhoneMap.get(nld.Secondary_phone__c+allocatedProject).SLead__c;
                    }
                   /* else if(nld.Secondary_Email__c !=null && emailMap.containsKey(nld.Secondary_Email__c+allocatedProject)){
                        nld.Delete_Lead__c = true;
                        nld.Main_Lead__c = emailMap.get(nld.Secondary_Email__c+allocatedProject).SLead__c;
                    }else if(nld.Email !=null && emailMap.containsKey(nld.Email+allocatedProject)){
                        nld.Delete_Lead__c = true; 
                        nld.Main_Lead__c = emailMap.get(nld.Email+allocatedProject).SLead__c;
                    }*/
                } 
            }
        }
    }
    

    public static void afterinsertLogic2(List<Lead> ldList){
        Map<string,Lead> newemailMap = new Map<string,Lead>();
        Map<string,Lead> newPhoneMap = new Map<string,Lead>();
        if(ldList.size()>1){
            for(Lead fnld : ldList){
                string allocatedProject='';
                if(fnld.Allocated_project__c !=null){
                    allocatedProject = fnld.Allocated_project__c;
                }
                if(fnld.Email !=null && !newemailMap.containsKey(fnld.Email+allocatedProject)){
                    newemailMap.put(fnld.Email+allocatedProject,fnld);
                }
                if(fnld.Phone__c !=null && !newPhoneMap.containsKey(fnld.Phone__c+allocatedProject)){
                    newPhoneMap.put(fnld.Phone__c+allocatedProject,fnld);
                }
                if(fnld.Secondary_Email__c !=null && !newemailMap.containsKey(fnld.Secondary_Email__c+allocatedProject)){
                    newemailMap.put(fnld.Secondary_Email__c+allocatedProject,fnld);
                }
                if(fnld.Secondary_phone__c !=null && !newPhoneMap.containsKey(fnld.Secondary_phone__c+allocatedProject)){
                    newPhoneMap.put(fnld.Secondary_phone__c+allocatedProject,fnld);
                }
            }
            system.debug(newPhoneMap.size());
            system.debug(newemailMap.size());
        }
        
        for(Lead nld : ldList){
            string allocatedProject='';
            system.debug('-------'+ nld.Delete_Lead__c);
            system.debug('-----'+ nld.Main_Lead__c);
            if(nld.Allocated_project__c !=null){
                allocatedProject = nld.Allocated_project__c;
            }
            if(nld.Delete_Lead__c && nld.Main_Lead__c !=null)
            {
                addRelatedSource(nld);
            }
            else if(nld.Phone__c !=null && NewPhoneMap.containsKey(nld.Phone__c+allocatedProject) && nld.Id !=NewPhoneMap.get(nld.Phone__c+allocatedProject).Id)
            {
                addRelatedSource2(nld,NewPhoneMap.get(nld.Phone__c+allocatedProject));
            }
            else if(nld.Email !=null && newemailMap.containsKey(nld.Email+allocatedProject) && nld.Id !=newemailMap.get(nld.Email+allocatedProject).Id)
            {
                addRelatedSource2(nld,newemailMap.get(nld.Email+allocatedProject));
            }
            else if(nld.Secondary_phone__c !=null && NewPhoneMap.containsKey(nld.Secondary_phone__c+allocatedProject) && nld.Id !=NewPhoneMap.get(nld.Secondary_phone__c+allocatedProject).Id)
            {
                addRelatedSource2(nld,NewPhoneMap.get(nld.Secondary_phone__c+allocatedProject));
            }
            else if(nld.Secondary_Email__c !=null && newemailMap.containsKey(nld.Secondary_Email__c+allocatedProject)  && nld.Id !=newemailMap.get(nld.Secondary_Email__c+allocatedProject).Id)
            {
                addRelatedSource2(nld,newemailMap.get(nld.Secondary_Email__c+allocatedProject));
            }
            else
            {
                Related_source__c rs = new Related_source__c();
                rs.SLead__c = nld.Id;
                rs.Source__c = nld.Source_Type__c;
                rs.Sub_Source__c = nld.Lead_source__c;
                rs.Primary_Source__c = nld.Source_Type__c;
                rs.Tertiary_Source__c = nld.Tertiary_Source__c;
                rs.Phone__c = nld.Phone__c;
                rs.Country_Code__c = nld.Country_Code__c;
                rs.Secondary_Phone__c = nld.Secondary_Phone__c;
                rs.Secondary_Contry_Code__c = nld.Secondary_Country_Code__c;
                rs.Email__c = nld.Email;
                rs.CP_Lookup__c = nld.Channel_Partner__c;
                rs.Secondary_Email__c = nld.Secondary_Email__c;
                rs.Description__c = nld.Last_Comment__c;
                rs.Allocated_Project__c = nld.Allocated_Project__c;
                rs.Campaign__c = nld.Campaign__c;
                rs.Campaign_Std__c = nld.Campaign_std__c;
                rs.type_of_lead__c = nld.Type_of_lead__c;
                rsList.add(rs);
                if(!matchedMap.containsKey(nld.Id)){
                    system.debug(nld.Id);
                    Lead ld = new Lead();
                    ld.Id = nld.Id;
                    ld.Last_Source_Of_Enquiry__c =nld.Source_Type__c;
                    ld.Last_Sub_Source__c =  nld.Lead_source__c;
                    ld.First_Source_Of_Enquiry__c = nld.Source_Type__c;
                    ld.First_Sub_Source__c =  nld.Lead_source__c;
                    ld.First_Contatced_On__c = system.now();
                    if(nld.Campaign__c != null){
                        ld.First_Campaign__c = nld.Campaign__c;
                        ld.Last_Campagin__c = nld.Campaign__c;
                    }
        
                    matchedMap.put(nld.Id,ld);
                }
                
            }
        }
        
        if(rsList.size() >0){
            insert rsList;
            rsList.clear();
        }
        
        if(matchedMap.size() >0){
            updateList = matchedMap.values();
            update updateList;
            matchedMap.clear();
            updateList.clear();
        }
        if(deleteList.size() >0){
            delete deleteList;
            deleteList.clear();
        }
    }
    //in Duplicate is Present exising data in system
    public static void addRelatedSource(Lead nld){
        Related_source__c rs = new Related_source__c();
        rs.SLead__c = nld.Main_Lead__c;
        rs.Source__c = nld.Source_Type__c;
        rs.Sub_Source__c = nld.Lead_source__c;
        rs.Phone__c = nld.Phone__c;
        rs.CP_Lookup__c = nld.Channel_Partner__c;
        rs.Country_Code__c = nld.Country_Code__c;
        rs.Secondary_Phone__c = nld.Secondary_Phone__c;
        rs.Secondary_Contry_Code__c = nld.Secondary_Country_Code__c;
        rs.Email__c = nld.Email;
        rs.Secondary_Email__c = nld.Secondary_Email__c;
        rs.Description__c = nld.Last_Comment__c;
        rs.Allocated_Project__c = nld.Allocated_Project__c;
        rs.Campaign__c = nld.Campaign__c;
        rs.Campaign_Std__c = nld.Campaign_std__c;
        rs.type_of_lead__c = nld.Type_of_lead__c;
        rs.Primary_Source__c = nld.Source_Type__c;
        rs.Tertiary_Source__c = nld.Tertiary_Source__c;
        if(nld.Main_lead_status__c == 'Closed Lost' || nld.Main_lead_status__c == 'Booked'|| nld.Main_lead_status__c =='Lead Lost'){
            rs.Lead_Type__c = 'Re-Opened';
        }else{
            rs.Lead_Type__c = 'Re-Engaged';
        }
        rsList.add(rs);
        deleteList.add(new Lead(Id=nld.Id));
       
        Lead ld = new Lead();
        ld.Id=nld.Main_Lead__c;
        ld.Last_Source_Of_Enquiry__c =nld.Source_Type__c;
        ld.Last_Sub_Source__c =  nld.Lead_source__c;
        if(nld.Campaign__c != null){ ld.Last_Campagin__c = nld.Campaign__c;}
        system.debug('====='+nld.Main_lead_status__c +'==='+ nld.Main_Pre_Sales_User__c );
        //It is in Lost or Closed lost or Lead age is more than 90 days it will re-opened if same lead comes again
        if(nld.Main_lead_status__c == 'Booked'|| nld.Main_lead_status__c =='Lead Lost' || nld.Main_lead_status__c == 'Closed Lost'
         ){
            string RecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
             ld.Lead_status__c ='New';
             ld.Lead_Assigned__c=false;
             ld.Lead_Transfered__c = false;
             ld.Type_of_lead__c = 'Direct Lead';
             ld.Lead_Type__c ='Re-Opened';
             ld.Assigment_count__c ='0';
             ld.No_Of_Times_Unqualified__c=0;
             ld.Allocated_Project__c = nld.Allocated_Project__c;
             ld.Last_Re_Opened_Date__c = system.now();
             ld.Re_assigned_date__c=null;
             ld.RNR_date__c=null;
             ld.status_change_date__c=null;
             ld.Last_comment__c = '';
             ld.Site_Visit_Schedule_Date__c=null;
             ld.Site_visit_Project__c = null;
             ld.Reassigned_By__c=null;
             ld.Site_Visit_Feedback__c=null;
             ld.Followup_Subject__c=null;
             ld.Next_follow_up_Date__c=null;
             ld.Next_Site_visit_Date__c=null;
             ld.Closed_Lost_Reason__c=null;
             ld.Lead_Lost_Reasons__c = null;
             ld.Reasons_in_Detail__c = null;
             ld.Remark_for_Closed_Lost__c=null;
             ld.RecordTypeId=RecTypeId;
             ld.Re_Assignment_Status__c = '';
             
             //Enquiry Date - 16/12/2025 Added by - Durga Prasad
             ld.Enquiry_Date__c = system.now();
             ld.Credit_Source__c =nld.Source_Type__c;
             ld.Credit_Sub_Source__c =  nld.Lead_source__c;
             
             //Last Channel Partner and Credit Channel Partner -19/01/2025 added by - Durga Prasad
             if(nld.Channel_Partner__c != null)
             {
                 ld.Last_Channel_Partner__c = nld.Channel_Partner__c;
                 ld.Credit_Channel_Partner__c = nld.Channel_Partner__c;
                 //If lead is Re-opened by the channel Patner Mention Lead Owner or Current User we are assigning to Owner of lead
                 ld.Lead_Assigned__c = true;
                 ld.Lead_Transfered__c = true;
                 ld.OwnerId = nld.OwnerId;
                 ld.Sourcing_Member__c = nld.OwnerId;
                 ld.Pre_Sales_User__c = nld.OwnerId;
             }
             
             //If Lead is Re-opened by GRE it shound assign to sales
             if(nld.Walking_Lead_Form__c)
             {
                 string SalesRecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
                 ld.Push_To_Sales__c = true;
                 ld.RecordTypeId=SalesRecTypeId;
                 ld.Lead_Status__c='SV Done';
             }
             
         }
        else{
            ld.Lead_Type__c ='Re-Engaged';
            ld.Re_Engaged_Date__c = system.now();
            if(nld.Main_Lead_Age__c > 45 )
            {  
                //Enquiry Date - 16/12/2025 Added by - Durga Prasad
                ld.Enquiry_Date__c = system.now();
                ld.Credit_Source__c =nld.Source_Type__c;
                ld.Credit_Sub_Source__c =  nld.Lead_source__c;
                //Last Channel Partner and Credit Channel Partner -19/01/2025 added by - Durga Prasad
                if(nld.Channel_Partner__c != null)
                {
                    ld.Last_Channel_Partner__c = nld.Channel_Partner__c;
                    ld.Credit_Channel_Partner__c = nld.Channel_Partner__c;
                }
              
            }
            
            //After 90 days if it is re-enaging we need to assign to new Executive 
            //with Pre Sales user and Lead Status as New
            if(nld.Main_Lead_Age__c > 90)
            {
                string RecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
                ld.Lead_status__c ='New';
                ld.Re_Assignment_Status__c ='Re-engaged After 90 Days (Executive Re-assignment)';
                ld.Lead_Assigned__c=false;
                ld.Lead_Transfered__c = false;
                ld.RecordTypeId=RecTypeId;
                
                //After 90 days if lead is Re-enaging with Channel Partner then we are Assigning to lead owner which they selected
                if(nld.Channel_Partner__c != null)
                {
                    ld.Lead_Assigned__c = true;
                    ld.Lead_Transfered__c = true;
                    ld.OwnerId = nld.OwnerId;
                    ld.Sourcing_Member__c = nld.OwnerId;
                    ld.Pre_Sales_User__c = nld.OwnerId;
                }
            }
            
            
        }
        matchedMap.put(nld.Main_Lead__c,ld);
 
    }
    //When the duplicate lead present in inserting data list
    public static void addRelatedSource2(Lead nld, Lead mainContact){
        Related_source__c rs = new Related_source__c();
        rs.SLead__c = mainContact.Id;
        rs.Source__c = nld.Source_Type__c;
        rs.Sub_Source__c = nld.Lead_source__c;
        rs.Phone__c = nld.Phone__c;
        rs.Country_Code__c = nld.Country_Code__c;
        rs.Secondary_Phone__c = nld.Secondary_Phone__c;
        rs.Secondary_Contry_Code__c = nld.Secondary_Country_Code__c;
        rs.Email__c = nld.Email;
        rs.CP_Lookup__c = nld.Channel_Partner__c;
        rs.Secondary_Email__c = nld.Secondary_Email__c;
        rs.Description__c = nld.Last_Comment__c;
        rs.Allocated_Project__c = nld.Allocated_Project__c;
        rs.Campaign__c = nld.Campaign__c;
        rs.Campaign_Std__c = nld.Campaign_std__c;
        rs.type_of_lead__c = nld.Type_of_lead__c;
        rs.Primary_Source__c = nld.Source_Type__c;
        rs.Tertiary_Source__c = nld.Tertiary_Source__c;
        rsList.add(rs);
        deleteList.add(new Lead(Id=nld.Id));
        
        Lead ld = new Lead();
        ld.Id=mainContact.Id;
        ld.First_Source_Of_Enquiry__c = mainContact.Source_Type__c;
        ld.First_Sub_Source__c = mainContact.Lead_source__c;
        ld.Last_Source_Of_Enquiry__c =nld.Source_Type__c;
        ld.Last_Sub_Source__c =  nld.Lead_source__c;
        if(nld.Campaign__c != null){ld.Last_Campagin__c = nld.Campaign__c;}
        ld.Last_Re_Engaged_Date__c = system.now();
        matchedMap.put(mainContact.Id,ld);
    }  
    
    public static void reassignUnqualifiedLead(List<Lead> leadsToProcess) {
        // Fetch sales user identifiers from CMDT
        List<Lead_Assignment_Config__mdt> assignmentOrder = [SELECT User_Indentifier__c  FROM Lead_Assignment_Config__mdt ];
        
        // Resolve users by Username or Alias
        Set<String> identifiers = new Set<String>();
        for (Lead_Assignment_Config__mdt mdt : assignmentOrder) {
            identifiers.add(mdt.User_Indentifier__c);
        }
        
        Map<String, Id> identifierToUserId = new Map<String, Id>();
        for (User u : [ SELECT Id, Username, Alias  FROM User  WHERE Username IN :identifiers OR Alias IN :identifiers ]) {
            identifierToUserId.put(u.Username, u.Id);
            identifierToUserId.put(u.Alias, u.Id);
        }
        
        // Build list of all sales users
        List<Id> allSalesUserIds = new List<Id>();
        for (Lead_Assignment_Config__mdt cfg : assignmentOrder) {
            allSalesUserIds.add(identifierToUserId.get(cfg.User_Indentifier__c));
        }
        
        // Assign leads
        for (Lead ld : leadsToProcess) {
            Integer times = ld.No_Of_Times_Unqualified__c == null ? 0 : Integer.valueOf(ld.No_Of_Times_Unqualified__c);
            
            List<Id> availableUsers = new List<Id>();
            for (Id uId : allSalesUserIds) {
                if (uId != ld.OwnerId) {
                    availableUsers.add(uId);
                }
            }
            
            if (!availableUsers.isEmpty()) {
                Integer idx = Math.mod(times, availableUsers.size());
                ld.OwnerId = availableUsers[idx];
            }
        }
    }
    
    
    
    //Not in Use
    public static void afterinsertLogic(List<Lead> ldList){
        user u = [SELECT Id,Name,Profile.Name FROM user WHERE Id=:userinfo.getUserId()];
        
        Map<string,Lead> newemailMap = new Map<string,Lead>();
        Map<string,Lead> newPhoneMap = new Map<string,Lead>();
        set<string> cpIds = new set<string>();
        if(ldList.size()>1){
            for(Lead fnld : ldList){
                
                if(fnld.Email !=null && !newemailMap.containsKey(fnld.Email)){
                    newemailMap.put(fnld.Email,fnld);
                }
                if(fnld.Phone__c !=null && !newPhoneMap.containsKey(fnld.Phone__c)){
                    newPhoneMap.put(fnld.Phone,fnld);
                }
                if(fnld.Secondary_Email__c !=null && !newemailMap.containsKey(fnld.Secondary_Email__c)){
                    newemailMap.put(fnld.Secondary_Email__c,fnld);
                }
                if(fnld.Secondary_phone__c !=null && !newPhoneMap.containsKey(fnld.Secondary_phone__c)){
                    newPhoneMap.put(fnld.Secondary_phone__c,fnld);
                }
                
            }
            
        }
        
        for(Lead nld : ldList){
            
            system.debug('-------'+ nld.Delete_Lead__c);
            system.debug('-----'+ nld.Main_Lead__c);
            
            if(nld.Delete_Lead__c && nld.Main_Lead__c !=null){
                system.debug('====='+nld);
                system.debug('-----'+ nld.Main_Lead__c+'--=='+ nld.id);
                
                addRelatedSource(nld);
                
            }else if(nld.Phone__c !=null && NewPhoneMap.containsKey(nld.Phone__c) && nld.Id !=NewPhoneMap.get(nld.Phone__c).Id){
                
                addRelatedSource2(nld,NewPhoneMap.get(nld.Phone__c));
            }else if(nld.Email !=null && newemailMap.containsKey(nld.Email) && nld.Id !=newemailMap.get(nld.Email).Id){
                
                addRelatedSource2(nld,newemailMap.get(nld.Email));
            }else if(nld.Secondary_phone__c !=null && NewPhoneMap.containsKey(nld.Secondary_phone__c) && nld.Id !=NewPhoneMap.get(nld.Secondary_phone__c).Id){
                
                addRelatedSource2(nld,NewPhoneMap.get(nld.Secondary_phone__c));
            }else if(nld.Secondary_Email__c !=null && newemailMap.containsKey(nld.Secondary_Email__c)  && nld.Id !=newemailMap.get(nld.Secondary_Email__c).Id){
                
                addRelatedSource2(nld,newemailMap.get(nld.Secondary_Email__c));
            }else{
                
                
                Related_source__c rs = new Related_source__c();
                
                rs.SLead__c = nld.Id;
                System.debug('');
                rs.Source__c = nld.Source_Type__c;
                rs.Sub_Source__c = nld.Lead_source__c;
                rs.Phone__c = nld.Phone__c;
                rs.Country_Code__c = nld.Country_Code__c;
                rs.Secondary_Phone__c = nld.Secondary_Phone__c;
                rs.Secondary_Contry_Code__c = nld.Secondary_Country_Code__c;
                rs.Email__c = nld.Email;
                rs.Secondary_Email__c = nld.Secondary_Email__c;
                rs.Description__c = nld.Last_Comment__c;
                system.debug('======'+  rs.Description__c);
                rs.Allocated_Project__c = nld.Allocated_Project__c;
                rs.Campaign__c = nld.Campaign__c;
                rs.Campaign_Std__c = nld.Campaign_std__c;
                rs.type_of_lead__c = nld.Type_of_lead__c;
                rsList.add(rs);
                if(!matchedMap.containsKey(nld.Id)){
                    system.debug(nld.Id);
                    Lead ld = new Lead();
                    ld.Id = nld.Id;
                    ld.Last_Source_Of_Enquiry__c =nld.Source_Type__c;
                    ld.Last_Sub_Source__c =  nld.Lead_source__c;
                    ld.First_Source_Of_Enquiry__c = nld.Source_Type__c;
                    ld.First_Sub_Source__c =  nld.Lead_source__c;
                    ld.First_Contatced_On__c = system.now();
                    if(nld.Campaign__c != null){
                        ld.First_Campaign__c = nld.Campaign__c ;
                        ld.Last_Campagin__c = nld.Campaign__c;
                    }
                    
                    //ld.Last_Re_engaged_On__c = system.now();
                    // system.debug(nld.Re_engaged_Count__c);
                    // ld.Re_engaged_Count__c = nld.Re_engaged_Count__c + 1;
                    /* matchedMap.put(nld.Id,ld);*/
                }
                
            }
        }
        
        if(rsList.size() >0){
            insert rsList;
            rsList.clear();
        }
        
        if(matchedMap.size() >0){
            updateList = matchedMap.values();
            update updateList;
            matchedMap.clear();
            updateList.clear();
        }
        if(deleteList.size() >0){
            if(!test.isRunningTest()){
                delete deleteList;
            }
            deleteList.clear();
        }
    }

}