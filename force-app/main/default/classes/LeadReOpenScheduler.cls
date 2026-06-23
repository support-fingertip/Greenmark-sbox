global class LeadReOpenScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {

        // Get Record Type Id for "Pre Sales"
        Id recTypeId = Schema.SObjectType.Lead
            .getRecordTypeInfosByName()
            .get('Pre Sales')
            .getRecordTypeId();

        List<Lead> leadsToUpdate = new List<Lead>();

        List<Lead> leadList = [
            SELECT Id,
                   Allocated_Project__c
            FROM Lead
            WHERE Lead_Age__c > 90 AND Re_Assignment_Age__c > 90
            AND Lead_Status__c NOT IN ('Booked','Lead Lost','Closed Lost')
        ];

        for (Lead nld : leadList) {

            Lead ld = new Lead(
                Id = nld.Id
            );
            ld.Re_Assignment_Status__c ='Re-assigned After 90 Days (Status Not Closed)';
            ld.Lead_status__c ='New';
            ld.Lead_Assigned__c=false;
            ld.Lead_Transfered__c = false;
            ld.RecordTypeId=recTypeId;
            
            leadsToUpdate.add(ld);
        }

        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }
}