public class CancellationLetterVFPController {
    public Id bookingId { get; set; }
    public List<Co_Applicant__c> coApplicants { get; set; }
     public Co_Applicant__c firstCoApplicant { get; set; }
        public Booking__c booking { get; set; }
    
    
    private Boolean bookingAddressesLoaded = false;
    private String permanentAddress;
    
    public CancellationLetterVFPController(ApexPages.StandardController stdController) {
        bookingId = stdController.getId();
         fetchBookingDetails();
        coapplicants=[
            SELECT Name, Salutation__c, Date_of_Birth__c, Spouse_Date_Of_Birth_coapp__c,Spouse_Name__c,
                   Permanent_Address__c, Communication_Address__c, Pincode_office__c,Other_Qualification__c,
                   Qualification__c, Pincode_commmunication__c, Pincode_permanent__c,Other_Industry__c,
                   Office_Address__c, Anniverssary_Date__c, Son_Daughter_Wife_of__c,Son2_Daughter_Wife_of__c,
                   Nationality__c, Co_Applicant__c.Aadhar_Number__c, Alternate_Contact_No__c,Country_of_Residence__c,
                   Passport_Number__c, PAN_Number__c, Email__c, Primary_Phone__c,Office_Pincode__c,
                   Residential_Status__c, Profession__c, Industry__c, Employeed_at__c, Designation__c
            FROM Co_Applicant__c WHERE Booking__c = :bookingId  ];
      
        if (!coApplicants.isEmpty()) {
            firstCoApplicant = coApplicants[0];
        }
       
    }
     public void  fetchBookingDetails(){
         booking = [Select Id,
                   First_Applicant_Name__c,
                   Agreement_Execution_Date__c,
                   S__c,
                   Son_Daughter_Wife_of1__c,
                   PAN_Number__c,
                   Agreement_Executed_Date__c,
                   Aadhar_No__c,
                   Address__c,
                   Date_of_Birth1__c,
                   Son_Daughter_Wife_of__c,
                   Booking_Amount__c,
                   GRAND_TOTAL__c,
                   Permanent_Address1__c,
                   Pincode1__c,
                   Permanent_Address2__c,
                   Plot__c
                   
                   
                   From Booking__c Where Id=:bookingId];
    }
   
    private void loadBookingAddresses() {
        if (bookingAddressesLoaded) return;
        
        Booking__c b = [
            SELECT Permanent_Address2__c,
            Correspondence_Address__c,
            Office_Address1__c
            FROM Booking__c
            WHERE Id = :booking.Id
            LIMIT 1
        ];
        
        permanentAddress      = b.Permanent_Address2__c;
        
        bookingAddressesLoaded = true;
    }
    public String getPermanentFullAddress() {
        loadBookingAddresses();            // you already have this
        return formatAddress(permanentAddress);
    }
    private String formatAddress(String addr) {
        if (addr == null) return '';
        
        return addr;
    }
    
    
}