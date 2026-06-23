@isTest
public class BookingPDFControllerTest {
    
    @isTest
    public static void testbooking() {
        
         Project__c pjt = new Project__c(
            Name = 'Trifecta Vanto',
             Project_Type__c = 'Apartments',
            Project__c = 'Trifecta Vanto',
            Active__c = true
        );
        insert pjt;
        
        
         Lead testLead = new Lead(
            LastName='Test Lead',
            Allocated_Project__c='Trifecta Vanto',
            Reassigned_By__c=UserInfo.getUserId(),
            Re_assigned_date__c = system.now(),
            Lead_status__c='New',
            Email='praveen@gmail.com',
            LeadSource ='Advertisement',
            Source_Type__c ='Google',
            Phone__c='9898767998',
            Company='test'
        );
        insert testLead;

        Quote__c testQuote = new Quote__c(
            Project__c = 'Trifecta Vanto',
            Payment_Type__c='Standard',
            Quote_status__c = 'Converted',
            SLead__c = testLead.Id
        );
        insert testQuote;
        
      
        
         List<Payment_Schedule__c> schedules = new List<Payment_Schedule__c>();
    Payment_Schedule__c ps1 = new Payment_Schedule__c(
            Name = 'PS1',
            Quote__c = testQuote.Id,
            Payment_percent__c = 40,
            S_No__c = 1
        );
        insert ps1;
        schedules.add(ps1);
      Payment_Schedule__c ps2 = new Payment_Schedule__c(
            Name = 'PS1',
            Quote__c = testQuote.Id,
            Payment_percent__c = 40,
            S_No__c = 2
        );
        insert ps2;
        schedules.add(ps2);
        
        
        Booking__c bk = New Booking__c();
        bk.SLead__c= testLead.id;
        bk.Quote__c= testQuote.id;
        insert bk;
        
          Co_Applicant__c co = new Co_Applicant__c(
        Name = 'test',
            Primary_Phone__c ='4567890675',
            Booking__c = bk.Id
        
        );
        insert co;
        
        Receipt__c rc = new Receipt__c(
        Booking__c = bk.Id
        );
        insert rc;
        
        Receipt_Line_Item__c rcl= new Receipt_Line_Item__c(
        Booking__c = bk.Id,
            Payment_schedule__c = ps2.Id,
            Receipt__c = rc.Id
        //Type__c = 'Land'   
        //Receipt_Date__c = Date.today()
        );
        insert rcl;
        
        
        Test.setMock(HttpCalloutMock.class, new RestMock());
        
         PageReference pref = Page.BookingForm; 
        BookingPDFController.sendEmailtoCustomer(bk.id, 'Apartments');
        
        Test.setCurrentPage(pref);
        
        pref.getParameters().put('Id', String.valueOf(bk.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(bk);
        BookingPDFController testp = new BookingPDFController(sc);
       
       
    }
     private class RestMock implements HttpCalloutMock {
 
        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = 'your Json Response';
 
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
     }

}