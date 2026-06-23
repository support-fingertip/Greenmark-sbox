@isTest
public class LeadStatusControllerTest {
    
    @isTest
    public static void method() {
      
        Lead lad= new Lead();
        lad.LastName='test';
        lad.Allocated_Project__c = 'Trifecta Vanto';
        lad.Phone = '9182748514';
        //lad.Source_Type__c='Digital Marketing';
        lad.Lead_source__c = 'Social Media';
        lad.Lead_Status__c ='New';
        lad.OwnerId = UserInfo.getUserId();
        lad.Lead_Assigned__c = false;
        lad.IsPushed__c = true;
        lad.Source_Type__c = 'Google';
        lad.Company='test';
        insert lad;
        
        Site_Visit__c st = new Site_Visit__c();
        st.Status__c = 'Scheduled';
        st.SLead__c = lad.Id;
        DateTime dt = System.Now().addDays(1);
        
        Test.startTest();
        
        //  Cover getRecordTypeName
        LeadStatusController.getLeadRecordTypeName(lad.Id);
        
        //  Cover picklist methods
        //LeadStatusController.getUnqualifiedReasons();
        //LeadStatusController.getClosedLostReason();
       // LeadStatusController.getOpenReason();
       // LeadStatusController.getAllocatedReason();
        
        //  Cover "Open"
        //LeadStatusController.updateLeadWithStatus(lad.Id, 'Open', dt, 'Hot', 'TestOpen', 'ReasonOpen', 'ReasonAlloc');
        LeadStatusController.updateLeadWithStatus(lad.Id,'Open', System.now().addDays(2),'Hot', 'Customer requested a call back','New Lead Inquiry', 'Assigned by Lead Queue',true, false,true,false,System.now().addDays(5));
        
        //  Cover "Pre Sales Follow Up"
      LeadStatusController.updateLeadWithStatus(lad.Id,'Pre Sales Follow Up', System.now().addDays(2),'Hot', 'Customer requested a call back','New Lead Inquiry', 'Assigned by Lead Queue',true, false,true,false,System.now().addDays(5));
        
        //  Cover "Qualified"
      LeadStatusController.updateLeadWithStatus(lad.Id,'Qualified', System.now().addDays(2),'Hot', 'Customer requested a call back','New Lead Inquiry', 'SV Proposed',true, false,true,false,System.now().addDays(5));
        
        //  Cover "Quotation"
        LeadStatusController.updateLeadWithStatus(lad.Id,'Quotation', System.now().addDays(2),'Hot', 'Customer requested a call back','New Lead Inquiry', 'Assigned by Lead Queue',true, false,true,false,System.now().addDays(5));
        
        //  Cover "Lead Lost"
       LeadStatusController.updateLeadWithStatus(lad.Id,'Lead Lost', System.now().addDays(2),'Hot', 'Customer requested a call back','New Lead Inquiry', 'Assigned by Lead Queue',true, false,true,false,System.now().addDays(5));
        
        //  Cover "Closed Lost" (normal rating)
       LeadStatusController.updateLeadWithStatus(lad.Id,'Closed Lost', System.now().addDays(2),'Hot', 'Customer requested a call back','New Lead Inquiry', 'Assigned by Lead Queue',true, false,true,false,System.now().addDays(5));
        
        //  Cover "Unqualified" with rating = Other (special branch)
      //  LeadStatusController.updateLeadWithStatus(lad.Id, 'Unqualified', dt, 'Other', 'Other Comments', 'ReasonOpen', 'ReasonAlloc');
        
        //  Cover "Closed Lost"
       // LeadStatusController.updateLeadWithStatus(lad.Id, 'Closed Lost', dt, 'Budget Issue', 'Detailed reason', 'ReasonOpen', 'ReasonAlloc');
        
        //  Cover "Allocated"
       // LeadStatusController.updateLeadWithStatus(lad.Id, 'Allocated', dt, 'Hot', 'TestAlloc', 'ReasonOpen', 'ReasonAlloc');
        
        Test.stopTest();
    }
}