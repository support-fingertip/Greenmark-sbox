public without sharing class RoundRobinHandler {
    /***************************
     * Lead Assignedment based on projects
    **************************/
    public static void assignLead(List<Lead> leadList,boolean updateLeads,string usType){
        Datetime d = system.now();
        String dayOfWeek = d.format('EEEE');
        Set<string>  projectinterested  = new Set<string>();
        Map<string,List<Lead>>  projectLeadMap = new Map<string,List<Lead>>(); 
        Map<id,user>  rrMemberMapToUpdate = new  Map<id,user> ();
        for(Lead l:leadList){  
            string project = l.Allocated_Project__c;
            if(project != null && project != '' && l.Lead_Assigned__c != true && l.Delete_Lead__c != true){ 
                projectinterested.add(project);
                List<Lead>  projectQue = projectLeadMap.get(project); 
                if(projectQue  == null){
                    projectLeadMap.put(project, new   List<Lead>{l} );
                }else{
                    projectQue.add(l);  
                    projectLeadMap.put(project,  projectQue);
                } 
            }
        }
        system.debug('projectinterested'+ projectinterested.size());
        Map<string,List<Round_Robin_Member__c>>  projectAvaliableQueMap = new Map<string,List<Round_Robin_Member__c>>();
        Map<string,List<Round_Robin_Member__c>>  projectQueMap = new Map<string,List<Round_Robin_Member__c>>();
        Map<string,string>  projectWithProjectHead = new Map<string,string>();
        List<Round_Robin__c> RRAvaliablequeList=[Select id,Project_Assigned__c, Project_Head__c,
                                                 
                                                 (select Name,User__c from  Round_Robin_Members__r 
                                                  where Active__c = true AND user__r.Availability__c=true 
                                                  AND user__r.isActive=true AND user__r.is_working__c=TRUE AND
                                                  User__r.Week_off_days__c excludes(:dayOfWeek) AND User_Type__c=:usType  order by 
                                                  Last_Assigned_time_user__c,createddate asc nulls first )
                                                 
                                                 from Round_Robin__c where Project_Assigned__c in :projectinterested and 
                                                 Active__c = true ];
        
        List<Round_Robin__c> RRqueList=[Select id,Project_Assigned__c,Project_Head__c,
                                        
                                        (select Name,User__c from  Round_Robin_Members__r  where Active__c =true AND 
                                         user__r.isActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c 
                                         excludes ( :dayOfWeek) AND User_Type__c=:usType order by Last_Assigned_time_user__c,createddate	
                                         asc nulls first  ) 
                                        
                                        from Round_Robin__c where Project_Assigned__c in :projectinterested and 
                                        Active__c = true ];
        
        List<Round_Robin__c> RRqueProjectHeadList=[Select id,Project_Assigned__c,Project_Head__c
                                                   from Round_Robin__c where Project_Assigned__c in :projectinterested and 
                                                   Active__c = true ];
        
        if(RRAvaliablequeList.size()>0){
            system.debug('Available Users There');
            for(Round_Robin__c rr : RRAvaliablequeList){
                if(rr.Round_Robin_Members__r.size()>0){
                    projectAvaliableQueMap.put(rr.Project_Assigned__c,rr.Round_Robin_Members__r);
                }
               
            }
        }
        if(RRqueList.size()>0){
            system.debug('All are not Avaialble Users');
            for(Round_Robin__c rr : RRqueList){
                if(rr.Round_Robin_Members__r.size()>0){
                    projectQueMap.put(rr.Project_Assigned__c,rr.Round_Robin_Members__r);
                }
            }
        }
        
        if(RRqueProjectHeadList.size()>0){
            system.debug('In project head list');
            for(Round_Robin__c rr : RRqueProjectHeadList){
                if(rr.Project_Head__c != null)
                {
                    projectWithProjectHead.put(rr.Project_Assigned__c,rr.Project_Head__c);
                }
            }
        }

        for(string prj : projectinterested){
            if(projectAvaliableQueMap.containskey(prj) && projectAvaliableQueMap.get(prj).size()>0){
                system.debug('Entered the Available');
                List<Round_Robin_Member__c>  projectQue = projectAvaliableQueMap.get(prj);  
                integer counter = 0; 
                for(Lead l : projectLeadMap.get(prj)){
                    if(projectQue!=null && projectQue.size() > 0 && projectQue[counter] != null && projectQue[counter].user__c != null){
                        system.debug('projectQue[counter].user__c: ' + projectQue[counter].user__c);
                        l.ownerId = projectQue[counter].user__c;
                        l.Lead_Assigned__c = true;
                        if(usType =='Pre Sales'){
                            l.Pre_sales_user__c =projectQue[counter].user__c;
                        }else{
                            l.Sales_User__c =projectQue[counter].user__c;
                            
                            l.SV_User__c=projectQue[counter].user__c; 
                        }
                        l.Reassigned_By__c = UserInfo.getUserId();
                        l.Re_assigned_date__c = system.now();
                        user u = new user();
                        u.Id = projectQue[counter].user__c;
                        u.LastAssignmentTime1__c = system.now().getTime(); 
                        
                        rrMemberMapToUpdate.put(projectQue[counter].user__c,u ) ; 
                        counter ++; 
                        if(projectQue.size() == counter  ){
                            counter  =0; 
                        } 
                    }
                }
            }
            else if(projectQueMap.containsKey(prj) && projectQueMap.get(prj).size()>0){
                system.debug('Entered the Not Available');
                List<Round_Robin_Member__c>  projectQue = projectQueMap.get(prj);  
                integer counter = 0; 
                for(Lead l : projectLeadMap.get(prj)){
                    if(projectQue!=null && projectQue.size() > 0 && projectQue[counter] != null && projectQue[counter].user__c != null){
                        system.debug('projectQue[counter].user__c: ' + projectQue[counter].user__c);
                        l.ownerId = projectQue[counter].user__c;
                        l.Lead_Assigned__c = true;
                        if(usType =='Pre Sales'){
                            l.Pre_sales_user__c =projectQue[counter].user__c;
                        }else{
                            l.Sales_User__c =projectQue[counter].user__c;
                        }
                        l.Re_assigned_date__c = system.now();
                        user u = new user();
                        u.Id = projectQue[counter].user__c;
                        u.LastAssignmentTime1__c = system.now().getTime(); 
                        
                        rrMemberMapToUpdate.put(projectQue[counter].user__c,u ) ; 
                        counter ++; 
                        if(projectQue.size() == counter  ){
                            counter  =0; 
                        } 
                    }
                }
            }
            //If No Available and not acitive users we are assigning leads to Project Head
            else if(projectWithProjectHead.containskey(prj))
            {
                system.debug('Entered the Project Head');
                string projectHead = projectWithProjectHead.get(prj);
                for(Lead l : projectLeadMap.get(prj)){
                    l.ownerId = projectHead;
                    l.Lead_Assigned__c = true;
                    if(usType =='Pre Sales'){
                        l.Pre_sales_user__c = projectHead;
                    }
                    else{
                        l.Sales_User__c = projectHead;
                        l.SV_User__c= projectHead; 
                    }
                    l.Reassigned_By__c = UserInfo.getUserId();
                    l.Re_assigned_date__c = system.now();
                    user u = new user();
                    u.Id = projectHead;
                    u.LastAssignmentTime1__c = system.now().getTime(); 
                    rrMemberMapToUpdate.put(projectHead,u ) ; 
                }
            }
        }

        if(rrMemberMapToUpdate.values().size()>0){
            UPDATE rrMemberMapToUpdate.values();
            rrMemberMapToUpdate.clear();
        }
        if(updateLeads){
            Update leadList;
        }
    } 
    
    //Not In Use
    public static void siteVisitRoundRobin(List<Site_Visit__c> siteVisits){
        Datetime d = system.now();
        String dayOfWeek = d.format('EEEE');
        Set<string>  projectInterested  = new Set<string>();
        Map<string,List<Site_Visit__c>>  projectSiteVisitMap = new Map<string,List<Site_Visit__c>>(); 
        Map<id,user>  rrMemberMapToUpdate = new  Map<id,user> ();
        for(Site_Visit__c sv : siteVisits){  
            string project = sv.Project__c;
            if(project != null && project != '' && sv.Go_For_Round_Robin__c == true){ 
                projectInterested.add(project);
                List<Site_Visit__c>  projectQue = projectSiteVisitMap.get(project); 
                if(projectQue  == null){
                    projectSiteVisitMap.put(project, new List<Site_Visit__c>{sv} );
                }else{
                    projectQue.add(sv);  
                    projectSiteVisitMap.put(project,  projectQue);
                } 
            }
        }
        system.debug('projectinterested'+ projectinterested.size());
        Map<string,List<Round_Robin_Member__c>>  projectAvaliableQueMap = new Map<string,List<Round_Robin_Member__c>>();
        Map<string,List<Round_Robin_Member__c>>  projectQueMap = new Map<string,List<Round_Robin_Member__c>>();
        
        List<Round_Robin__c> RRAvaliablequeList=[Select id,Project_Assigned__c, 
                                                 (select Name,User__c from  Round_Robin_Members__r 
                                                  where Active__c =true AND user__r.Availability__c=true AND
                                                  user__r.isActive=true AND user__r.is_working__c=TRUE AND User__r.Week_off_days__c 
                                                  excludes ( :dayOfWeek) AND User_Type__c='Sales' order by
                                                  Last_Assigned_time_user__c,createddate	 asc nulls first )
                                                 from Round_Robin__c where Project_Assigned__c	in :projectinterested and Active__c = true ];
        List<Round_Robin__c> RRqueList=[Select id,Project_Assigned__c, (select Name,User__c from  Round_Robin_Members__r 
                                                                        where Active__c =true AND user__r.isActive=true AND 
                                                                        user__r.is_working__c=TRUE AND User__r.Week_off_days__c 
                                                                        excludes ( :dayOfWeek) AND User_Type__c='Sales' order by 
                                                                        Last_Assigned_time_user__c,createddate	 asc nulls first  )
                                        from Round_Robin__c where Project_Assigned__c in :projectinterested and Active__c = true ];
        if(RRAvaliablequeList.size()>0){
            for(Round_Robin__c rr : RRAvaliablequeList){
                if(rr.Round_Robin_Members__r.size()>0){
                    projectAvaliableQueMap.put(rr.Project_Assigned__c,rr.Round_Robin_Members__r);
                }
            }
        }
        if(RRqueList.size()>0){
            for(Round_Robin__c rr : RRqueList){
                if(rr.Round_Robin_Members__r.size()>0){
                    projectQueMap.put(rr.Project_Assigned__c,rr.Round_Robin_Members__r);
                }
            }
        }
        
        for(string prj : projectInterested){
            if(projectAvaliableQueMap.containskey(prj) && projectAvaliableQueMap.get(prj).size()>0){
                List<Round_Robin_Member__c>  projectQue = projectAvaliableQueMap.get(prj);  
                integer counter = 0; 
                for(Site_Visit__c sv : projectSiteVisitMap.get(prj)){
                    if(projectQue!=null && projectQue.size() > 0 && projectQue[counter] != null && projectQue[counter].user__c != null){
                        system.debug('projectQue[counter].user__c: ' + projectQue[counter].user__c);
                        sv.ownerId = projectQue[counter].user__c;
                        user u = new user();
                        u.Id = projectQue[counter].user__c;
                        u.LastAssignmentTime1__c = system.now().getTime(); 
                        
                        rrMemberMapToUpdate.put(projectQue[counter].user__c,u ) ; 
                        counter ++; 
                        if(projectQue.size() == counter  ){
                            counter  =0; 
                        } 
                    }
                }
            }
            else if(projectQueMap.containsKey(prj) && projectQueMap.get(prj).size()>0){
                List<Round_Robin_Member__c>  projectQue = projectQueMap.get(prj);  
                integer counter = 0; 
                for(Site_Visit__c sv : projectSiteVisitMap.get(prj)){
                    if(projectQue!=null && projectQue.size() > 0 && projectQue[counter] != null && projectQue[counter].user__c != null){
                        system.debug('projectQue[counter].user__c: ' + projectQue[counter].user__c);
                        sv.ownerId = projectQue[counter].user__c;
                        user u = new user();
                        u.Id = projectQue[counter].user__c;
                        u.LastAssignmentTime1__c = system.now().getTime(); 
                        
                        rrMemberMapToUpdate.put(projectQue[counter].user__c,u ) ; 
                        counter ++; 
                        if(projectQue.size() == counter  ){
                            counter  =0; 
                        } 
                    }
                }
            }
            
        }
        if(rrMemberMapToUpdate.values().size()>0){
            UPDATE rrMemberMapToUpdate.values();
            rrMemberMapToUpdate.clear();
        }
    } 
 
}