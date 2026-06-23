trigger SLeadTrigger on Lead (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    if(label.Enable_Trigger=='TRUE'){
        system.debug(utility.runLeadTrigger);
        if(Utility.runLeadTrigger  != false){
            if (Trigger.isBefore) {
                
                if (Trigger.isInsert) {   
                    
                    list<Lead> ldlist = new list<Lead>();
                    for (Lead led : Trigger.new) {
                        if (led.Channel_Partner__c != null) ldlist.add(led);
                        
                        if(led.Company == null)led.Company = 'Trifecta';
                        //Enquiry Date - 16/12/2025 Added by - Durga Prasad
                        if(led.Enquiry_Date__c == null)
                        {
                            led.Enquiry_Date__c = system.now();
                        }
                        if(led.Created_Date__c == null)
                        {
                            led.Created_Date__c = system.now();
                        }
                        if( led.Source_Type__c != null && led.Source_Type__c != '')
                        {
                              led.Credit_Source__c = led.Source_Type__c;
                        }
                        if(led.Lead_source__c != null && led.Lead_source__c != '')
                        {
                            led.Credit_Sub_Source__c = led.Lead_source__c;
                        }
                        
                        if(led.Channel_Partner__c != null)
                        {
                            led.Last_Channel_Partner__c = led.Channel_Partner__c;
                            led.Credit_Channel_Partner__c = led.Channel_Partner__c;
                        }
                    }
                    
                    // Ensure ldlist is not empty before calling cpmethod
                    if (ldlist != null && ldlist.size() > 0) {
                        system.debug('Callcpmethod');
                        //RelatedSourceHandler.cpmethod(ldlist); 
                    }

                    user u = [SELECT Id,Name,Profile.Name FROM user WHERE Id=:userinfo.getUserId()];
                    Map<String,Id> cpMap = new  Map<String,Id>();
                    Map<String,Id> cpMap2 = new  Map<String,Id>();
                    RelatedSourceHandler.checkMobileNumber2(trigger.new);
                    RelatedSourceHandler.duplicateCheck2(trigger.new);
                    list<Lead> PreSalesLeads = new list<Lead>();
                    list<Lead> WalkinLeads = new list<Lead>();
                    
                    // if leads are creating by admin then it will go to roundrobin, if lead is creating by other user it will assign same user.
                    if(u.Profile.Name =='System Administrator' || u.Profile.Name == 'Lead Capture Profile' || 
                       u.Profile.Name == 'API MCube Profile' ||  u.Profile.Name  =='GRE' ||  u.Profile.Name  =='Management User' || 
                       u.Profile.Name =='CP Head' || u.Profile.Name =='CP Coordinator' )
                    {
                        for(Lead ld : trigger.new){
                            if(ld.Walking_Lead_Form__c){
                                system.debug('Inside the Walking- In Leads');
                                ld.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
                                ld.Lead_Status__c='SV Done';
                                if(ld.Round_Robin_Off__c){
                                    
                                }
                                else{
                                    
                                    WalkinLeads.add(ld); 
                                }
                            }
                            else if(ld.Channel_Partner__c != null && ld.Sourcing_Member__c != null)
                            {
                                ld.Pre_sales_user__c = ld.Sourcing_Member__c;
                                ld.OwnerId = ld.Sourcing_Member__c;
                                ld.Re_assigned_date__c = system.now();
                                ld.Sourcing_Member__c = ld.Sourcing_Member__c;
                                ld.Lead_Assigned__c = true;
                                ld.Lead_Transfered__c = true;
                                ld.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
                            }
                            else{
                                PreSalesLeads.add(ld);
                            }
                        }
                        
                        if(PreSalesLeads.size()>0){
                            RoundRobinHandler.assignLead(PreSalesLeads,false,'Pre Sales'); 
                        }
                        if(WalkinLeads.size()>0){
                            RoundRobinHandler.assignLead(WalkinLeads,false,'Sales'); 
                        }
                        
                    }
                    else{
                        for(Lead ld : trigger.new){
                            ld.Lead_Assigned__c = true;
                            ld.Reassigned_By__c = UserInfo.getUserId();
                            ld.Re_assigned_date__c = system.now();
                            if(u.Profile.Name == 'Sales'){
                                ld.Sales_User__c =UserInfo.getUserId();
                                ld.Lead_Assigned__c = true;
                                ld.Lead_Transfered__c = true;
                                ld.SV_User__c=UserInfo.getUserId();
                                
                                ld.Pre_sales_user__c =UserInfo.getUserId();// added due to Sales is working as pre Sales user
                                ld.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
                                //  ld.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
                            }
                            else if(u.Profile.Name == 'Pre sales'){
                                ld.Pre_sales_user__c =UserInfo.getUserId();
                                ld.Lead_Assigned__c = true;
                                ld.Lead_Transfered__c = true;
                                ld.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
                            }
                            else if(u.Profile.Name == 'CP Sourcing Member')
                            {
                                ld.Pre_sales_user__c = UserInfo.getUserId();
                                ld.Sourcing_Member__c = UserInfo.getUserId();
                                ld.Lead_Assigned__c = true;
                                ld.Lead_Transfered__c = true;
                                ld.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
                            }
                            if(ld.Lead_source__c =='Walk-In'){
                                ld.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
                                ld.Lead_Status__c='New sales enquiry';
                                
                            }
                        }
                        
                        
                    }
                    
                    
                    
                } 
                
                if (Trigger.isUpdate) {
                    system.debug('on update');
                    List<Lead> preSalesLdList = new List<Lead>();
                    List<Lead> salesLdList = new List<Lead>();
                    Set<String> phonePrjSet = new Set<String>();
                    
                    //-----------For Checking Duplicate while edit the Primary Phone or Secondary Phone
                    For(Lead ld : Trigger.New){
                        if ((ld.Phone__c!= Trigger.oldmap.get(ld.Id).Phone__c && ld.Phone__c != null) || (ld.Allocated_Project__c!= Trigger.oldmap.get(ld.Id).Allocated_Project__c && ld.Allocated_Project__c != null)) {
                            phonePrjSet.add(ld.Phone__c+ld.Allocated_Project__c);
                        }
                        else if ((ld.Secondary_Phone__c!= Trigger.oldmap.get(ld.Id).Secondary_Phone__c && ld.Secondary_Phone__c != null) || (ld.Allocated_Project__c!= Trigger.oldmap.get(ld.Id).Allocated_Project__c && ld.Allocated_Project__c != null)) {
                            phonePrjSet.add(ld.Secondary_Phone__c+ld.Allocated_Project__c);
                        } 
                    }
                    
                    List<Lead> unqalifiedlead = new List<Lead>();
                    List<Lead> bookedLead = new List<Lead>();
                    for(Lead ld : Trigger.new){
                        if (
                            (
                                // Case 1: Lead Status changed to New
                                (
                                    ld.Lead_status__c != Trigger.oldMap.get(ld.Id).Lead_status__c && ld.Lead_status__c == 'New'
                                )
                                ||
                                // Case 2: Re-Assignment Status changed while Lead Status is New
                                (
                                    ld.Re_Assignment_Status__c != Trigger.oldMap.get(ld.Id).Re_Assignment_Status__c &&
                                    ld.Lead_status__c == 'New' &&
                                    (
                                        ld.Re_Assignment_Status__c == 'Re-engaged After 90 Days (Executive Re-assignment)' ||
                                        ld.Re_Assignment_Status__c == 'Re-assigned After 90 Days (Status Not Closed)'
                                    )
                                )
                            )
                            &&
                            !ld.Lead_Assigned__c &&
                            !ld.Lead_Transfered__c
                        )
                        {
                            preSalesLdList.add(ld);
                        }else if(!ld.Lead_Assigned__c && ld.Push_To_Sales__c && ld.Lead_status__c != 'Lead Lost'){
                            salesLdList.add(ld);
                        }
                        //Not in Use
                        else if(ld.Mark_Unqualified__c && LeadStatusController.markleadUnqualified && !ld.Lead_Assigned__c && ld.Lead_status__c=='New'&& ld.No_Of_Times_Unqualified__c <= 2){
                            // system.debug(ld.Mark_Unqualified__c+'=='+ LeadStatusController.markleadUnqualified +'=='+ ld.Lead_Assigned__c +'==='+ ld.Lead_status__c+'===='+ ld.No_Of_Times_Unqualified__c );
                            unqalifiedlead.add(ld);
                        }
                        else if (ld.Lead_status__c != Trigger.oldmap.get(ld.Id).Lead_status__c && ld.Lead_status__c=='Booked'){
                            bookedLead.add(ld);
                        }
                        
                        if(ld.Lead_status__c != Trigger.oldmap.get(ld.Id).Lead_status__c && (ld.Lead_status__c=='Lead Lost' || ld.Lead_Status__c == 'Closed Lost')){
                            ld.Previous_Stage__c = Trigger.oldmap.get(ld.Id).Lead_status__c;
                        }

                    }
                    
                    if(preSalesLdList.size()>0){
                        RoundRobinHandler.assignLead(preSalesLdList,false,'Pre Sales');
                        
                    }
                    if(salesLdList.size()>0){
                        RoundRobinHandler.assignLead(salesLdList,false,'Sales');
                    }
                    if(unqalifiedlead.Size()>0){
                        // system.debug('Called for unqalification lead');
                        RoundRobinHandler.assignLead(preSalesLdList,true,'Pre Sales');
                    }
                    if(bookedLead.size()>0){
                       /* if(label.Enable_whatsapp_notifications == 'TRUE'){
                            WhatsappController ctrl = new WhatsappController(bookedLead,'6');
                            System.enqueueJob(ctrl);
                        }*/
                    }
                    if(phonePrjSet.size()>0 ){
                        
                        List<Lead> oldLeadList = [SELECT Id,Lead_ID__c, Phone__c, Secondary_Phone__c, Email, Secondary_Email__c,Allocated_Project__c,PhoneProject__c,Secondary_Phone_Project__c  FROM Lead 
                                                  WHERE ( PhoneProject__c IN :phonePrjSet OR Secondary_Phone_Project__c IN :phonePrjSet) 
                                                  ORDER BY CreatedDate ASC];
                        // Map to store old leads based on phone and email
                        Map<String, Lead> phonePrjMap = new Map<String, Lead>();
                        for (Lead old : oldLeadList) {
                            
                            if (old.Phone__c != null) {
                                phonePrjMap.put(old.PhoneProject__c, old);
                            }
                            if (old.Secondary_Phone__c != null) {
                                phonePrjMap.put(old.Secondary_Phone_Project__c, old);
                            }
                            
                        }
                        for (Lead nld : trigger.new) { 
                            string phone = nld.Phone__c+nld.Allocated_Project__c;
                            string secPhone = nld.Secondary_Phone__c+nld.Allocated_Project__c;
                            
                            if (phonePrjMap.containsKey(phone) && phonePrjMap.get(phone).Id != nld.Id) {
                                nld.addError('Lead with the same phone number and project already exists: ' + phonePrjMap.get(phone).Lead_ID__c);
                            }else if (phonePrjMap.containsKey(secPhone) && phonePrjMap.get(secPhone).Id != nld.Id) {
                                nld.addError('Lead with the same phone number and project already exists: ' + phonePrjMap.get(secPhone).Lead_ID__c);
                            } 
                        }
                        
                    }
                    
                    //--------------Validation for Checking site visit before updating the lead status to site Visit Schedule---------------
                   /* List<Lead> leadListforSiteVisit = new List<Lead>();
                    
                    For(Lead ld : Trigger.new){
                        if(ld.Lead_Status__c!=Trigger.oldmap.get(ld.Id).Lead_Status__c && ld.Lead_Status__c == 'SV Scheduled'){
                            leadListforSiteVisit.add(ld);
                        }
                    }
          
                    if(!leadListforSiteVisit.isEmpty()){
                       // String returnMessage = ValidationHandler.CheckScheduleSiteVist(leadListforSiteVisit);  
                        system.debug('returnMessage'+returnMessage); 
                        if(returnMessage!=null){
                            leadListforSiteVisit[0].addError(returnMessage);
                        }
                        
                    }
                    
                    
                    //for Unqualified Lead- If any lead is unqualified in the 3rd round it should be assigned to Pre sales Head/ Manager.
                    for (Lead ld : Trigger.new) {
                        Lead oldLd = Trigger.oldMap.get(ld.Id);
                        
                        if (ld.Last_Unqualified_by__c != oldLd.Last_Unqualified_by__c && ld.No_Of_Times_Unqualified__c >2) {
                            Id userId = oldLd.Last_Unqualified_by__c;
                            User u = [select id ,ManagerId from User where Id =:userId];
                            if (u.ManagerId != null) {
                                ld.OwnerId = u.ManagerId;
                                ld.Lead_Status__c = 'New';
                                ld.Lead_Assigned__c = true;
                                
                            }
                        }
                    }
                    */
                    
                    
                }
                //To Stop the Lead deletion if any child records are there
                if (Trigger.isDelete) {
                    Set<Id> leadIds = new Set<Id>();
                    for (Lead l : Trigger.old) {
                        leadIds.add(l.Id);
                    }
                    
                    Map<Id, Boolean> leadWithChildMap = new Map<Id, Boolean>();
                    for (Related_Source__c rs : [SELECT Id, SLead__c FROM Related_Source__c WHERE SLead__c IN :leadIds ]) {
                        leadWithChildMap.put(rs.SLead__c, true);
                    }
                    for (Site_Visit__c sv : [ SELECT Id, SLead__c FROM Site_Visit__c WHERE SLead__c IN :leadIds]) {
                        leadWithChildMap.put(sv.SLead__c, true);
                    }
                    for (Call_Detail__c cd : [ SELECT Id, Lead__c FROM Call_Detail__c WHERE Lead__c IN :leadIds]) {
                        leadWithChildMap.put(cd.Lead__c, true);
                    }
                    for (Quote__c qt : [SELECT Id, SLead__c FROM Quote__c WHERE SLead__c IN :leadIds]) {
                        leadWithChildMap.put(qt.SLead__c, true);
                    }
                    for (Follow_Up__c fu : [SELECT Id, SLead__c FROM Follow_Up__c WHERE SLead__c IN :leadIds ]) {
                        leadWithChildMap.put(fu.SLead__c, true);
                    }
                    for (Booking__c bk : [ SELECT Id, SLead__c FROM Booking__c WHERE SLead__c IN :leadIds ]) {
                        leadWithChildMap.put(bk.SLead__c, true);
                    }
                    for (Lead l : Trigger.old) {
                        if (leadWithChildMap.containsKey(l.Id)) {
                            l.addError('You cannot delete this Lead because child records exist.');
                        }
                    }
                }
            }
            
            if (Trigger.isAfter) {
                if (Trigger.isInsert) {
                    //  WhatsAppTriggerHandler.processNewLeads(Trigger.new);//Call the WhatsAppTriggerHandler
                    List<account> accList = new List<account>();
                    RelatedSourceHandler.afterinsertLogic2(trigger.new);
                    
                    List<Lead> newLeads = new List<Lead>();
                    for(Lead ld: trigger.new){
                        if(!ld.Delete_Lead__c){
                            newLeads.add(ld);
                        }
                    }
                    if(label.Enable_whatsapp_notifications == 'TRUE'){
                        WhatsappController ctrl = new WhatsappController(newLeads,'1');
                        System.enqueueJob(ctrl);
                        
                        SMSHandler ctrl2 = new SMSHandler(newLeads,'1');
                        System.enqueueJob(ctrl2);
                    }
                   
                } 
                if (Trigger.isUpdate) {
                    
                    Set<Id> lostWinLeads = new Set<Id>();
                    Set<Id> ownerChange = new Set<Id>();
                    List<Lead> ldList = new List<Lead>();
                    List<Lead> toshare = new List<Lead>();
                    for(Lead con : Trigger.new){
                        system.debug(Trigger.oldmap.get(con.Id).lead_status__c );
                        system.debug(con.Lead_status__c );
                        if(con.Lead_status__c!=Trigger.oldmap.get(con.Id).lead_status__c && (con.Lead_status__c=='Lead Lost' || con.Lead_status__c=='Closed Lost')){
                            lostWinLeads.add(con.Id);
                        }
                        if(con.OwnerId!=Trigger.oldmap.get(con.Id).OwnerId && con.Lead_status__c!='Lead Lost' && con.Lead_status__c!='Closed Lost'){
                            ownerChange.add(con.Id);
                        }
                        // adding to List to update account owner
                        if(con.OwnerId!=Trigger.oldmap.get(con.Id).OwnerId && con.Lead_Status__c=='SV Scheduled'){
                            ldList.add(con);
                        }
                    }

                    if(lostWinLeads.size()>0){
                        List<site_visit__c> svList = new List<site_visit__c>();
                        svList = [SELECT Id,Name,status__c,Canceled_Reason__c FROM site_visit__c WHERE SLead__c IN : lostWinLeads and (status__c='Scheduled' OR status__c='SV Proposed')];
                        if(svList.size()>0){
                            for(site_visit__c sv : svList){
                                sv.status__c='Cancelled';
                                sv.Canceled_Reason__c = 'System Cancelled';
                            }
                            Update svList;
                        }
                        List<Follow_up__c> svList1 = new List<Follow_up__c>();
                        svList1 = [SELECT Id,Name,status__c FROM Follow_up__c WHERE SLead__c IN : lostWinLeads and status__c='Scheduled'];
                        if(svList1.size()>0){
                            for(Follow_up__c sv1 : svList1){
                                sv1.status__c='Missed';
                            }
                            Update svList1;
                        }
                    }
                    if(ownerChange.size()>0){
                        List<Follow_up__c> fwList = new List<Follow_Up__c>();
                        fwList = [SELECT Id,Name,OwnerId,SLead__r.ownerId FROM Follow_Up__c WHERE SLead__c IN: ownerChange and status__c='Scheduled'];
                        if(fwList.size()>0){
                            for(Follow_Up__c fw : fwList){
                                fw.ownerId = fw.SLead__r.OwnerId;
                            }
                            Update fwList;
                        }
                        List<site_visit__c> fwList1 = new List<site_visit__c>();
                        Map<Id,Id> ldMap = new Map<Id,Id>();
                        Map<Id,Id> SvMap = new Map<Id,Id>();
                        fwList1 = [SELECT Id,Name,OwnerId,SLead__r.ownerId,SLead__c,SLead__r.Id,SLead__r.Pre_sales_user__c FROM site_visit__c WHERE SLead__c IN: ownerChange];
                        if(fwList1.size()>0){
                            for(site_visit__c fw1 : fwList1){
                                ldMap.put(fw1.SLead__r.Id,fw1.SLead__r.Pre_sales_user__c);
                                SvMap.put(fw1.Id,fw1.SLead__r.Pre_sales_user__c);
                                fw1.ownerId = fw1.SLead__r.OwnerId;
                            }
                            Update fwList1;
                        }
                        if (!ldMap.isEmpty()) {
                            Boolean res = manulaSharingClass.manualShareLeadVisit(ldMap);
                            system.debug('=='+res);
                            if(res == true){
                                manulaSharingClass.manualShareSiteVisit(SvMap);
                            }
                        }
                    }
                    
                    if(ldList.size()>0){
                        manulaSharingClass.shareAnyRecordPreSales(ldList, 'Read');
                    }
                    
                }
            } 
        }
    }
}