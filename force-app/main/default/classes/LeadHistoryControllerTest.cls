@isTest
private class LeadHistoryControllerTest {

    // Note: Leads are inserted with minimal fields and the Lead trigger is
    // bypassed (Utility.runLeadTrigger=false). If the org enforces additional
    // required fields/validation rules on Lead, add them to the test leads.
    @isTest
    static void testReturnsOtherLeadsWithSamePhone() {
        Utility.runLeadTrigger = false;

        String phone = '9908073349';
        List<Lead> leads = new List<Lead>{
            new Lead(LastName = 'Lead 1', Company = 'Test', Phone__c = phone),
            new Lead(LastName = 'Lead 2', Company = 'Test', Phone__c = phone),
            new Lead(LastName = 'Lead 3', Company = 'Test', Phone__c = phone),
            new Lead(LastName = 'Different', Company = 'Test', Phone__c = '1112223333')
        };
        insert leads;

        Id currentId = leads[0].Id;

        Test.startTest();
        LeadHistoryController.LeadHistoryResult res = LeadHistoryController.getLeadHistory(currentId);
        Test.stopTest();

        System.assertEquals(phone, res.phone, 'Phone should be the current lead phone');
        System.assertEquals(2, res.leads.size(), 'Only same-phone leads excluding the current one');
        for (LeadHistoryController.LeadWrapper w : res.leads) {
            System.assertNotEquals(currentId, w.id, 'Current lead must be excluded');
            System.assertEquals(phone, w.phone, 'Returned leads must share the phone');
            System.assert(w.recordUrl.contains(w.id), 'Record URL should reference the lead Id');
        }
    }

    @isTest
    static void testBlankPhoneAndNullRecordId() {
        Utility.runLeadTrigger = false;

        Lead l = new Lead(LastName = 'No Phone', Company = 'Test');
        insert l;

        Test.startTest();
        LeadHistoryController.LeadHistoryResult blankRes = LeadHistoryController.getLeadHistory(l.Id);
        LeadHistoryController.LeadHistoryResult nullRes = LeadHistoryController.getLeadHistory(null);
        Test.stopTest();

        System.assertEquals(0, blankRes.leads.size(), 'Blank phone returns no history');
        System.assertEquals(0, nullRes.leads.size(), 'Null recordId returns empty result');
    }
}