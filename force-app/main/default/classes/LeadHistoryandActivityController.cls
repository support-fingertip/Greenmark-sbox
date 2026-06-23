global class LeadHistoryandActivityController {
    
    @AuraEnabled
    public static list<WrapSObject> GetData(string ldId, string filter){
        list<WrapSObject> glist = new list<WrapSObject>();
         String type='Lead';
		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Schema.SObjectType leadSchema = schemaMap.get(type);
		Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        
        if(filter == 'All' || filter == 'Field Updates'){
            list<LeadHistory> llist = [SELECT CreatedById, CreatedBy.Name, CreatedDate, Field, Id, LeadId, NewValue, OldValue FROM LeadHistory WHERE LeadID=:ldId];
            for(LeadHistory lh:llist){
                if(lh.Field != null){
                    WrapSObject WSO = new WrapSObject();
                    WSO.CreatedByID=lh.CreatedByID;
                    WSO.CreatedByName=lh.CreatedBy.Name;
                    WSO.CreatedDate=lh.CreatedDate;
                    WSO.type = 'History';
                    if(fieldMap.containskey(lh.Field)){
                        if(lh.Field != 'Last_Comment__c') WSO.Field= fieldMap.get(lh.Field).getDescribe().getLabel();
                    }else{
                        if(lh.Field != 'Last_Comment__c') WSO.Field= lh.Field;
                    }
                    WSO.LeadID=lh.LeadID;
                    String newval = String.valueOf(lh.NewValue);
                    String oldval = String.valueOf(lh.OldValue);
                    if(newval != null) 
                        if(!newval.startsWith('005')) WSO.NewValue= newval;
                    if(oldval != null) 
                        if(!oldval.startsWith('005')) WSO.OldValue=  oldval;
                    glist.add(WSO);
                } 
            }
        }
        
        if(filter == 'All' || filter == 'Activities'){
            list<Lead> leadlist = [SELECT ID,(SELECT Id, ActivityDate, ActivityDateTime, ActivityType, Subject, Description, CreatedDate, CreatedById,CreatedBy.Name , ActivitySubtype FROM ActivityHistories order by  ActivityDate DESC, LastModifiedDate DESC limit 500) FROM Lead  where id=:ldId];
            
            for(Lead l:leadlist){
                for(integer i=0;i<l.ActivityHistories.size();i++){
                    if(l.ActivityHistories[i].Subject != null){
                        WrapSObject WSO = new WrapSObject(); 
                        WSO.CreatedByID=l.ActivityHistories[i].CreatedById;
                        WSO.CreatedByName=l.ActivityHistories[i].CreatedBy.Name;
                        WSO.CreatedDate = l.ActivityHistories[i].CreatedDate;
                        WSO.type = 'Activity';
                        WSO.Subject=l.ActivityHistories[i].Subject;
                        WSO.Description=l.ActivityHistories[i].Description;
                        glist.add(WSO);
                        
                    }
                    
                } 
            } 
        }
        if(filter == 'All' || filter == 'Calls'){
            List<Call_Detail__c> cdList = [SELECT Id, Name, CreatedDate, 
                                           Call_From__c, Call_ID__c, Call_To__c, Call_Type__c, Duration__c, 
                                           Lead__c, Recording_File__c,  Status__c, CreatedById,Owner.Name 
                                           FROM Call_Detail__c where Lead__c = :ldId];
            
            for(Call_Detail__c cd : cdList){
                WrapSObject WSO = new WrapSObject(); 
                WSO.CreatedByName=cd.Owner.Name;
                WSO.CreatedDate=cd.CreatedDate;
                WSO.type = 'Call';
                WSO.calltype = cd.Call_Type__c;
                WSO.callfrom = cd.Call_From__c;
                WSO.callto = cd.Call_To__c;
                WSO.callstatus = cd.Status__c;
                WSO.url = cd.Recording_File__c;    
                glist.add(WSO);
            }
        }
        glist.sort();
        return glist;
    }
    
    global class WrapSObject implements Comparable{
        @AuraEnabled public string CreatedByID{set;get;}
        @AuraEnabled public string CreatedByName{set;get;}
        @AuraEnabled public DateTime CreatedDate{set;get;}
        @AuraEnabled public string Field{set;get;}
        @AuraEnabled public string RecordID{set;get;}
        @AuraEnabled public string LeadID{set;get;}
        @AuraEnabled public string NewValue{set;get;}
        @AuraEnabled public string OldValue{set;get;}
        @AuraEnabled public string Subject{set;get;}
        @AuraEnabled public string Description{set;get;}
        @AuraEnabled public string type{set;get;}
        @AuraEnabled public string calltype{set;get;}
        @AuraEnabled public string callstatus{set;get;}
        @AuraEnabled public string callfrom{set;get;}
        @AuraEnabled public string callto{set;get;}
        @AuraEnabled public string url{set;get;}
        @AuraEnabled public string comments{set;get;}
        
        public  Integer compareTo(Object anotherObject){
            WrapSObject wso2=(WrapSObject) anotherObject;
            if(CreatedDate>wso2.CreatedDate){
                return -1;
            }else if(CreatedDate<wso2.CreatedDate){
                return 1;
            }
            return 0;
        }
        
        
    }
    
}