/****************************************************************
* Class Name   : LostLeadReassignment
* Company      : Fingertipplus
* Created Date : 20-11-2025
* @description : This class is used to reassign the lost leads for 1st 3 times
* @author      : Mayuri Patel

* Change Log: 28-1-2026  added the condition exclude Cp leads as there is no round robin for CP
* -----------------------------------------------------------------------------
* Ver | Author 			| 	  Date 		| Description
* -----------------------------------------------------------------------------
* 1.0 | Mayuri Patel 	| 20-11-2025 	| Initial version
* 1.0 | Durga Prasad 	| 28-1-2026 	| modified version
* -----------------------------------------------------------------------------
**************************************************************/
global class LostLeadReassignment  implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

     public Database.QueryLocator start(Database.BatchableContext bc) {
         
         Decimal validity = Decimal.valueOf(System.Label.Lead_Lost_Reassignment_Validity);
        
        return Database.getQueryLocator([
            SELECT Id, Name, Phone__c, Allocated_Project__c,
            Lead_Status__c,Lead_Assigned__c,Mark_Unqualified__c ,No_Of_Times_Unqualified__c ,Previous_Stage__c,Lead_Lost_Reasons__c,
            Hrs_after_Lead_Lost__c,OwnerId FROM Lead
            where Mark_Unqualified__c = true and Lead_Assigned__c = false and Lead_Status__c = 'Lead Lost' and No_Of_Times_Unqualified__c < 3
            /*and (Previous_Stage__c = 'New' or Previous_Stage__c = 'Open')*/ and Lead_Lost_Reasons__c = 'RNR'
            and Hrs_after_Lead_Lost__c >=:validity AND Lead_Owner_Profile__c !='CP Sourcing Member' and Lead_Owner_Profile__c !='CP Coordinator'
            AND Lead_Owner_Profile__c!='CP Head'
        ]);
        
    }
    
     public void execute(Database.BatchableContext bc, List<Lead> scope) {
         
          Map<String, Project__c> projectMap = new Map<String, Project__c>();
         for(Project__c pr: [select Id,Name,Project__c,Project_Sales_Head__c from Project__c]){
             projectMap.put(pr.Project__c,pr);
         }
         
         
         for(Lead ld: scope){
           
             if(ld.No_Of_Times_Unqualified__c == 1){
                    ld.Lead_Status__c = 'New';
                    ld.Lead_Assigned__c = false;
                }
             
             if(ld.No_Of_Times_Unqualified__c == 2){
                     ld.OwnerId = projectMap.get(ld.Allocated_Project__c).Project_Sales_Head__c;
                     ld.Lead_Status__c = 'New';
                     ld.Lead_Assigned__c = true;
             }
         }
         
         try{
             database.update(scope,false);
         }
         catch(Exception ex){
             System.debug('Leads:' + scope);
             System.debug('Error while reassigning lost leads:' + ex.getMessage());
         }
         
       /*  List<Call_Detail__c> calls = [
             SELECT Id, Lead__c, OwnerId, Lead__r.OwnerId
             FROM Call_Detail__c
             WHERE Lead__c IN :scope
         ];
         
         Map<Id, Integer> leadIdToCallCount = new Map<Id, Integer>();
         
         for (Call_Detail__c c : calls) {
             // only count when call owner == lead owner
             if (c.OwnerId == c.Lead__r.OwnerId) {
                 Integer existing = leadIdToCallCount.get(c.Lead__c);
                 if (existing == null) {
                     leadIdToCallCount.put(c.Lead__c, 1);
                 } else {
                     leadIdToCallCount.put(c.Lead__c, existing + 1);
                 }
             }
         }
         Map<String, Project__c> projectMap = new Map<String, Project__c>();
         for(Project__c pr: [select Id,Name,Project__c,Project_Sales_Head__c from Project__c]){
             projectMap.put(pr.Project__c,pr);
         }
         
         
         for(Lead ld: scope){
             Integer callcount = leadIdToCallCount.containsKey(ld.id) ? leadIdToCallCount.get(ld.id) : 0;
             system.debug(ld.No_Of_Times_Unqualified__c + '---' + callcount);
             if((ld.No_Of_Times_Unqualified__c == 1 && callcount < 7) 
                || (ld.No_Of_Times_Unqualified__c == 2 && callcount < 5)){
                    ld.Lead_Status__c = 'New';
                    ld.Lead_Assigned__c = false;
                }
             
             if(ld.No_Of_Times_Unqualified__c == 3){
                     ld.OwnerId = projectMap.get(ld.Allocated_Project__c).Project_Sales_Head__c;
                     ld.Lead_Status__c = 'New';
                     ld.Lead_Assigned__c = true;
             }
             
         }*/
         
         
         
         
     }
    
      public void finish(Database.BatchableContext bc) {
        System.debug('Lost Lead Reassignment batch finished.');
    }
    
    global void execute(SchedulableContext SC) {
        database.executeBatch(new LostLeadReassignment(), 100);
        
        /*
        LostLeadReassignment job1 = new LostLeadReassignment();
        String cronExpression1 = '0 0 * * * ?'; // Runs at 0 minutes past the hour
        System.schedule('LostLeadReassignment_1', cronExpression1, job1);
        LostLeadReassignment job2 = new LostLeadReassignment();
        String cronExpression2 = '0 30 * * * ?'; // Runs at 30 minutes past the hour
        System.schedule('LostLeadReassignment_2', cronExpression2, job2);
*/
    }
}