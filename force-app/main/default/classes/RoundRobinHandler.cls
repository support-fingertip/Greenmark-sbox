public without sharing class RoundRobinHandler {
    /***************************
     * Lead Assignedment based on projects
    **************************/
    public static void assignLead(List<Lead> leadList,boolean updateLeads,string usType){
        Datetime d = system.now();
        String dayOfWeek = d.format('EEEE');

        // Collect the leads that still need assignment, plus the projects and sources they reference.
        List<Lead> toAssign = new List<Lead>();
        Set<String> projectinterested = new Set<String>();
        Set<String> sourceinterested  = new Set<String>();
        for(Lead l : leadList){
            if(l.Lead_Assigned__c != true && l.Delete_Lead__c != true){
                toAssign.add(l);
                if(String.isNotBlank(l.Allocated_Project__c)) projectinterested.add(l.Allocated_Project__c);
                if(String.isNotBlank(l.Source_Type__c))       sourceinterested.add(l.Source_Type__c);
            }
        }
        if(toAssign.isEmpty()){
            if(updateLeads) update leadList;
            return;
        }

        // Active members (availability split is done in-memory by getEligibleQueue) keyed by routing key.
        Map<String,List<Round_Robin_Member__c>> projectMembers = new Map<String,List<Round_Robin_Member__c>>();
        Map<String,List<Round_Robin_Member__c>> sourceMembers  = new Map<String,List<Round_Robin_Member__c>>();
        List<Round_Robin_Member__c> commonMembers = new List<Round_Robin_Member__c>();

        // Priority 1 - Project round robins (also matches legacy records where the type is blank but a project is set).
        if(!projectinterested.isEmpty()){
            for(Round_Robin__c rr : [Select id,Project_Assigned__c,
                                        (select Name,User__c,User__r.Availability__c from Round_Robin_Members__r
                                         where Active__c = true AND user__r.isActive=true AND user__r.is_working__c=TRUE
                                           AND User__r.Week_off_days__c excludes(:dayOfWeek) AND User_Type__c=:usType
                                         order by Last_Assigned_Time__c,createddate asc nulls first)
                                     from Round_Robin__c
                                     where Active__c = true AND Project_Assigned__c in :projectinterested
                                       AND (Round_Robin_Type__c = 'Project' OR Round_Robin_Type__c = null)]){
                if(rr.Round_Robin_Members__r.size() > 0) projectMembers.put(rr.Project_Assigned__c, rr.Round_Robin_Members__r);
            }
        }

        // Priority 2 - Source round robins.
        if(!sourceinterested.isEmpty()){
            for(Round_Robin__c rr : [Select id,Lead_Source_Type__c,
                                        (select Name,User__c,User__r.Availability__c from Round_Robin_Members__r
                                         where Active__c = true AND user__r.isActive=true AND user__r.is_working__c=TRUE
                                           AND User__r.Week_off_days__c excludes(:dayOfWeek) AND User_Type__c=:usType
                                         order by Last_Assigned_Time__c,createddate asc nulls first)
                                     from Round_Robin__c
                                     where Active__c = true AND Round_Robin_Type__c = 'Source'
                                       AND Lead_Source_Type__c in :sourceinterested]){
                if(rr.Round_Robin_Members__r.size() > 0) sourceMembers.put(rr.Lead_Source_Type__c, rr.Round_Robin_Members__r);
            }
        }

        // Priority 3 - Common round robin (fallback for everyone).
        for(Round_Robin__c rr : [Select id,
                                    (select Name,User__c,User__r.Availability__c from Round_Robin_Members__r
                                     where Active__c = true AND user__r.isActive=true AND user__r.is_working__c=TRUE
                                       AND User__r.Week_off_days__c excludes(:dayOfWeek) AND User_Type__c=:usType
                                     order by Last_Assigned_Time__c,createddate asc nulls first)
                                 from Round_Robin__c
                                 where Active__c = true AND Round_Robin_Type__c = 'Common' limit 1]){
            commonMembers = rr.Round_Robin_Members__r;
        }

        Map<String,Integer> counters = new Map<String,Integer>();
        Map<id,user> rrMemberMapToUpdate = new Map<id,user>();
        Map<Id,Round_Robin_Member__c> memberUpdates = new Map<Id,Round_Robin_Member__c>(); // BRD 4.1.9 - member-level last-assigned time (ratio)

        for(Lead l : toAssign){
            List<Round_Robin_Member__c> queue = null;
            String key = null;

            // Project (1st) -> Source (2nd) -> Common (3rd)
            if(String.isNotBlank(l.Allocated_Project__c) && projectMembers.containsKey(l.Allocated_Project__c)){
                queue = getEligibleQueue(projectMembers.get(l.Allocated_Project__c));
                key   = 'P-' + l.Allocated_Project__c;
            }
            if(queue == null && String.isNotBlank(l.Source_Type__c) && sourceMembers.containsKey(l.Source_Type__c)){
                queue = getEligibleQueue(sourceMembers.get(l.Source_Type__c));
                key   = 'S-' + l.Source_Type__c;
            }
            if(queue == null && !commonMembers.isEmpty()){
                queue = getEligibleQueue(commonMembers);
                key   = 'C';
            }
            if(queue == null || queue.isEmpty()) continue;

            Integer counter = counters.containsKey(key) ? counters.get(key) : 0;
            if(counter >= queue.size()) counter = 0;
            Round_Robin_Member__c m = queue[counter];
            if(m != null && m.User__c != null){
                l.ownerId = m.User__c;
                l.Lead_Assigned__c = true;
                l.Lead_Assigned_Time__c = System.now();
                if(usType == 'Pre Sales'){
                    l.Pre_sales_user__c = m.User__c;
                }else{
                    l.Sales_User__c = m.User__c;
                    l.SV_User__c    = m.User__c;
                }
                l.Reassigned_By__c    = UserInfo.getUserId();
                l.Re_assigned_date__c = system.now();
                Long nowTime = system.now().getTime();
                // Stamp the MEMBER row so a user added multiple times (ratio) rotates independently.
                memberUpdates.put(m.Id, new Round_Robin_Member__c(Id = m.Id, Last_Assigned_Time__c = nowTime));
                // Keep the user-level stamp too (backward compatible).
                user u = new user();
                u.Id = m.User__c;
                u.LastAssignmentTime1__c = nowTime;
                rrMemberMapToUpdate.put(m.User__c, u);
            }
            counter++;
            counters.put(key, counter);
        }

        if(!memberUpdates.isEmpty()){
            UPDATE memberUpdates.values();
        }
        if(rrMemberMapToUpdate.values().size() > 0){
            UPDATE rrMemberMapToUpdate.values();
            rrMemberMapToUpdate.clear();
        }
        if(updateLeads){
            Update leadList;
        }
    }

    // Returns only the available members, or - if everyone is unavailable - the full active list
    // (BRD 4.1.9: when all members are unavailable, leads still go to all active members).
    private static List<Round_Robin_Member__c> getEligibleQueue(List<Round_Robin_Member__c> activeMembers){
        List<Round_Robin_Member__c> available = new List<Round_Robin_Member__c>();
        for(Round_Robin_Member__c m : activeMembers){
            if(m.User__r != null && m.User__r.Availability__c == true) available.add(m);
        }
        return available.isEmpty() ? activeMembers : available;
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