@isTest
public class TrifectaCustomerBookingFormConTest {
@isTest
    public static void trifectaCustomer(){
        
          Project__c pjt = new Project__c(
            Name = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c = true
        );
        insert pjt;

        // Create block
        Block__c bc = new Block__c(
            Name = 'A',
            Intrest_Percentage__c = 12,
            Project__c = pjt.Id
        );
        insert bc;

        // Create Lead
        Lead ld = new Lead(
            LastName = 'Test',
            Company = 'test company',
            Phone__c = '9999999999',
            Source_Type__c = 'Google',
            Allocated_Project__c = pjt.Name
        );
        insert ld;

        // Create Plot
        Plot__c ut = new Plot__c(
            Name = 'P1',
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut;

        // Create Quote
        Quote__c qc = new Quote__c(
            Block_Lookup__c = bc.Id,
            Quote_status__c = 'Drafted',
            Block__c = 'A2',
            Project__c = pjt.Name,
            Payment_Type__c = 'Standard',
            Sale_Area__c = 2000,
            Built_up_area__c = 1500,
            Rate_per_sqft__c = 7000,
            Unit__c = ut.Id,
            SLead__c = ld.Id
        );
        insert qc;

        // Create Booking — IMPORTANT: must have CRM_Manager__c
        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c = qc.Id,
            Plot__c = ut.Id,
            CRM_Manager__c = UserInfo.getUserId(),
            Project__c = 'Trifecta Vanto',
            Project_Type__c = 'Apartments',
            Approval_status__c = 'Approved'
        );
        insert book;
        
       List<Payment_Schedule__c> schedules = new List<Payment_Schedule__c>();
    Payment_Schedule__c ps1 = new Payment_Schedule__c(
            Name = 'PS1',
            Quote__c = qc.Id,
        Booking__c = book.Id,
            Payment_percent__c = 40,
            S_No__c = 1
        );
        insert ps1;
        schedules.add(ps1);
        
         Receipt__c rc = new Receipt__c(
        Booking__c = book.Id
        );
        insert rc;
        
        Receipt_Line_Item__c rcl= new Receipt_Line_Item__c(
        Booking__c = book.Id,
            Payment_schedule__c = ps1.Id,
            Receipt__c = rc.Id
        //Type__c = 'Apartments'   
        //Receipt_Date__c = Date.today()
        );
        insert rcl;
        
        
        TrifectaCustomerBookingFormController.getBookingData(book.Id, 'Appartments');
         TrifectaCustomerBookingFormController.getBookingData(book.Id, 'Land');
         TrifectaCustomerBookingFormController.getBookingData(book.Id, 'Construction');
        TrifectaCustomerBookingFormController.updateBooking(book.Id, 'commnets', 'Approved','Apartments');
        TrifectaCustomerBookingFormController.updateBooking(book.Id, 'commnets', 'Approved','Land');
        TrifectaCustomerBookingFormController.updateBooking(book.Id, 'commnets', 'Approved','Construction');
    }
        
    
}