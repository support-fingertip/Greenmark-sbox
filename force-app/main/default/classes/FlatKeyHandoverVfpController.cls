public class FlatKeyHandoverVfpController {
    public Booking__c booking { get; set; }
    public String handoverByName { get; set; }
    public String handoverByDesignation { get; set; }
    public String handoverByMobile { get; set; }
    public Co_Applicant__c firstCoApplicant { get; set; }
    public bookingInfoWrapper bookingWrapper { get; set; }
    
    public class bookingInfoWrapper {
        public String mainKeyNo { get; set; }
        public decimal mainNoOfKeys { get; set; }
        
        public String mainDoorSensorKeyNo { get; set; }
        public decimal mainDoorSensorNoOfKeys { get; set; }
        
        public String masterBedroomKeyNo { get; set; }
        public decimal masterBedroomNoOfKeys { get; set; }
        
        public String childrenBedroomKeyNo { get; set; }
        public decimal childrenBedroomNoOfKeys { get; set; }
        
        public String commonBedroomKeyNo { get; set; }
        public decimal commonBedroomNoOfKeys { get; set; }
        
        public String guestBedroomKeyNo { get; set; }
        public decimal guestBedroomNoOfKey{ get; set; }

        public String basementKeyNo { get; set; }
        public decimal basementNoOfKey{ get; set; }  
     
        public String secondFloorKeyNo { get; set; }
        public decimal secondFloorNoOfKey{ get; set; } 
        
        public String sitOutKeyNo { get; set; }
        public decimal sitOutNoOfKey{ get; set; } 
        
        public String projectName { get; set; }
        public String projectAddress { get; set; }

        public String customerName { get; set; }
    }
    
    
    public FlatKeyHandoverVfpController(ApexPages.StandardController stdController) {
        Id bookingId = stdController.getId();
        
        if (bookingId != null) {
            booking = [
                SELECT Id,Guest_Bedroom_No_of_Keys__c,Guest_Bedroom_Key_No__c,Basement_Door_No_of_Keys__c,Basement_Door_Key_No__c,
                Second_Floor_No_of_Keys__c,Second_Floor_Key_No__c,Sit_Out_No_of_Keys__c,Sit_Out_Key_No__c,
                First_Applicant_Name__c,Main_Door_Sensor_No_of_Keys__c,Main_Door__c,Project1__r.Name ,Block_Id__c,
                Main_Door_Key_No__c,Main_Door_No_of_Keys__c,FF_Master_bedroom_No_Of_Keys__c,FF_Master_bedroom_Key_No__c,
                FF_children_bedroom_No_Of_Keys__c,FF_children_bedroom_Key_No__c,Common_Bedroom_No_of_Keys__c,Common_Bedroom_Key_No__c,
                Unit_Number__c FROM Booking__c WHERE Id = :bookingId LIMIT 1
            ];
            //Block 
            Block__c block = [select Id,Name,Email__c,Project_Address__c,Construction_Company_Name__c,Land_Company_Name__c,
                              Company_Name__c,Company_Address__c from Block__c where Id =:booking.Block_Id__c];
            
            List<Co_Applicant__c> coapplicants = [SELECT Name, Salutation__c FROM Co_Applicant__c WHERE Booking__c = :bookingId];
            firstCoApplicant = !coapplicants.isEmpty() ? coapplicants[0] : null;
            
            bookingInfoWrapper br = new bookingInfoWrapper();
            br.mainKeyNo = booking.Main_Door_Key_No__c;
            br.mainNoOfKeys = booking.Main_Door_No_of_Keys__c;
            
            br.mainDoorSensorKeyNo = booking.Main_Door__c;
            br.mainDoorSensorNoOfKeys = booking.Main_Door_Sensor_No_of_Keys__c;
            
            br.masterBedroomKeyNo = booking.FF_Master_bedroom_Key_No__c;
            br.masterBedroomNoOfKeys = booking.FF_Master_bedroom_No_Of_Keys__c;
            
            br.childrenBedroomKeyNo = booking.FF_children_bedroom_Key_No__c;
            br.childrenBedroomNoOfKeys = booking.FF_children_bedroom_No_Of_Keys__c;
            
            br.commonBedroomKeyNo = booking.Common_Bedroom_Key_No__c;
            br.commonBedroomNoOfKeys = booking.Common_Bedroom_No_of_Keys__c;
            
            br.guestBedroomKeyNo = booking.Guest_Bedroom_Key_No__c;
            br.guestBedroomNoOfKey = booking.Guest_Bedroom_No_of_Keys__c;
            
            br.basementKeyNo = booking.Basement_Door_Key_No__c;
            br.basementNoOfKey = booking.Basement_Door_No_of_Keys__c;
            
            br.secondFloorKeyNo = booking.Second_Floor_Key_No__c;
            br.secondFloorNoOfKey = booking.Second_Floor_No_of_Keys__c;
            
            br.sitOutNoOfKey = booking.Sit_Out_No_of_Keys__c;
            br.sitOutKeyNo = booking.Sit_Out_Key_No__c;

            br.projectName = (booking.Project1__r != null) ? booking.Project1__r.Name : '';
            br.projectAddress = (block != null && block.Project_Address__c != null) ? block.Project_Address__c : '';
            
            bookingWrapper = br;
            
        } else {
            booking = new Booking__c();
        }
        system.debug('bookingId'+bookingId);
        User currentUser = [
            SELECT Name, Title, MobilePhone
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        
        handoverByName        = currentUser.Name        != null ? currentUser.Name        : '';
        handoverByDesignation = 'CRM Team';
        handoverByMobile      = currentUser.MobilePhone != null ? currentUser.MobilePhone : '';
    }
}