/**
 * Subscriber trigger for the CP_Lead__e platform event.
 * Platform event triggers run as the Automated Process system user (full
 * permissions), so the Channel Partner lead - and its downstream automation
 * (round robin, owner assignment, related source) - is created here rather than
 * directly by the restricted Site guest user that submitted the request.
 */
trigger CP_Lead_Event_Trigger on CP_Lead__e (after insert) {
    List<Lead> leads = new List<Lead>();
    for (CP_Lead__e e : Trigger.new) {
        Lead l = new Lead();
        l.LastName = e.Last_Name__c;
        l.Lead_source__c = 'Channel Partner';
        if (String.isNotBlank(e.CP_Record_Id__c)) {
            l.Channel_Partner__c = (Id) e.CP_Record_Id__c;
        }
        l.Source_Type__c = 'Channel Partner';
        l.Sub_Source__c = e.CP_Name__c;
        l.Country_Code__c = e.Country_Code__c;
        String m = e.Mobile__c;
        l.Phone = (m != null && m.length() > 10) ? m.substring(m.length() - 10) : m;
        l.Phone__c = l.Phone;
        l.Email = e.Email__c;
        l.Allocated_project__c = e.Project__c;
        l.Last_Note__c = e.Remarks__c;
        l.Description = e.Description__c;
        l.Company = 'Greenmark Developers';
        l.Country__c = e.Country__c;
        l.State__c = e.State__c;
        l.City__c = e.City__c;
        l.Comments__c = e.Comments__c;
        leads.add(l);
    }
    if (!leads.isEmpty()) {
        insert leads;
    }
}
