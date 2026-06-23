public class UpdateLeadStatus1Controller {
     @AuraEnabled(cacheable=true)
    public static Id getRecordTypeId(String RecordId) {
        Lead ld =[Select id, RecordTypeId from Lead where Id =: RecordId];
        return ld.RecordTypeId;
        //return [SELECT Id FROM RecordType WHERE SObjectType = :objectApiName AND Name = :recordTypeName LIMIT 1].Id;
    }
    
    @AuraEnabled
    public static List<String> getFilteredLeadStages() {
        List<String> stages = new List<String>();
        Schema.DescribeFieldResult fieldDescribe = Lead.Lead_Status__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.getValue() != 'Booked') { // Exclude 'Booked'
                stages.add(entry.getLabel());
            }
        }
        system.debug('stages '+stages);
        return stages;
    }
    
    @AuraEnabled
    public static List<Follow_up__c> getFollowUps(string RecordId){
        List<Follow_up__c> F = [select Id,Name,Scheduled_Date__c,Description__c,Status__c from Follow_up__c where SLead__c=:RecordId and Status__c='Scheduled'];
        return F;
    }
    
    
    @AuraEnabled
    public static List<string> getAllocatedProject(ID RecordId){
        List<String> globalPicklistValues = new List<String>();
        
        // Get a map of fields for the SObject
        Map<String, Schema.SObjectField> fieldMap   = SObjectType.Lead.fields.getMap(); 
        // Get the list of picklist values for this field.
        List<Schema.PicklistEntry> values  = fieldMap.get( 'Allocated_Project__c' ).getDescribe().getPickListValues();
        
        for( PicklistEntry entry : values ) {
            globalPicklistValues.add( entry.getLabel());
        }
        system.debug('globalPicklistValues '+globalPicklistValues);
        return globalPicklistValues; 
        
    }
    
    @AuraEnabled
    public static List<Follow_up__c> getMissedFollowUps(string RecordId){
        List<Follow_up__c> F = [select Id,Name,Scheduled_Date__c,Description__c,Status__c from Follow_up__c where SLead__c=:RecordId and Status__c='Missed'];
        return F;
    }
    @AuraEnabled
    public static string UpdateFollowUps(string recId, string ButtonValue,string UpdateLeadStatus){
        string res = null;
        Lead l = [select Id,Name,Next_follow_up_Date__c,Follow_Up_Description__c,Followup_Subject__c,Follow_Up_Comment__c from Lead where Id=:recId limit 1];
        if(l.id!=null){
            
            Try{
                
                 List<Follow_up__c> scheduledFollowUps = [SELECT Id, Status__c, Name, CreatedDate, Comments__c, Completed_Date__c 
                    FROM Follow_up__c  WHERE Status__c = 'Scheduled' AND SLead__c = :recId  ];
                
                System.debug('Scheduled Follow-ups: ' + scheduledFollowUps);
                if (!scheduledFollowUps.isEmpty()) {
                    for (Follow_up__c followUp : scheduledFollowUps) {
                            followUp.Status__c = 'Completed';
                            followUp.Completed_Date__c = System.now();
                        followUp.Comments__c=l.Follow_Up_Comment__c;
                        
                    }
                    update scheduledFollowUps;
                }else{
                    
                    
                Follow_up__c newFollowUp = new Follow_up__c();
                newFollowUp.SLead__c= recId;
                newFollowUp.Scheduled_Date__c=l.Next_follow_up_Date__c;
                newFollowUp.Subject__c= l.Followup_Subject__c;
                newFollowUp.Description__c=l.Follow_Up_Description__c;
                insert newFollowUp;
                }
                
            }
            catch (Exception e) {
                System.debug('An error occurred: ' + e.getMessage());
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    // Get the error message for the current error
                    String errorMessage = e.getDmlMessage(i);
                    // You can log or handle the error message as needed
                    System.debug('An error occurred: ' + errorMessage);
                    return errorMessage;
                }
            }
            
        }
        return res;
    }
     @AuraEnabled(cacheable=true)
    public static List<String> getLeadStatusValues(Id recordTypeId) {
        List<String> statusValues = new List<String>();

        // Describe Lead.Status field for a specific record type
        Schema.DescribeFieldResult fieldResult = Lead.Lead_Status__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.isActive()) {
                statusValues.add(entry.getLabel());
            }
        }

        return statusValues;
    }
}