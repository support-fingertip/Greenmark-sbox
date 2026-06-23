/****************************************************************
* Class Name   : SMSHandler
* Company      : Fingertipplus
* Created Date : 02-12-2025
* @description : This class is used to send text message to customers
* @author      : Mayuri Patel

* Change Log:
* -----------------------------------------------------------------------------
* Ver | Author 			| 	  Date 		| Description
* -----------------------------------------------------------------------------
* 1.0 | Mayuri Patel 	| 06-11-2025 	| Initial version
* -----------------------------------------------------------------------------
**************************************************************/
public class SMSHandler implements Queueable, Database.AllowsCallouts{

    public String COMPANY_NAME = 'Trifecta Projects Pvt. Ltd.';
    public String ACTION = '';

    public static Boolean disableSMS = false;
    private List<Lead> leads;
    private List<Site_Visit__c> visits;
    private List<Booking__c> bookings;
    private List<Receipt__c> receipts;
    private List<Demand_Raised__c> demands;
    private Booking__c booking;
    private Decimal demandAmount;
    private Date demandDueDate;

    // Constructor to pass leads to the queueable class
    public SMSHandler(List<Lead> leads, String act) {
        this.leads = leads;
        this.ACTION = act;
    }
    // Constructor to pass leads to the queueable class
    public SMSHandler(List<Site_Visit__c> visits, String act) {
        this.visits = visits;
        this.ACTION = act;
    }

      // Constructor to pass leads to the queueable class
    public SMSHandler(List<Booking__c> bookings, String act) {
        this.bookings = bookings;
        this.ACTION = act;
    }

    // Constructor to pass receipts to the queueable class
    public SMSHandler(List<Receipt__c> receipts, String act) {
        this.receipts = receipts;
        this.ACTION = act;
    }

    // Constructor to pass demands to the queueable class
    public SMSHandler(List<Demand_Raised__c> demands, String act) {
        this.demands = demands;
        this.ACTION = act;
    }
    // Constructor for Revised Demand - single booking with amount and due date
    public SMSHandler(Booking__c booking, Decimal amount, Date dueDate, String act) {
        this.booking = booking;
        this.demandAmount = amount;
        this.demandDueDate = dueDate;
        this.ACTION = act;
    }

    // Welcome Mail - single booking
    public SMSHandler(Booking__c booking, String act) {
        this.booking = booking;
        this.ACTION = act;
    }

    // The execute method where the actual callout will happen
    public void execute(QueueableContext context) {
       if (Test.isRunningTest() || disableSMS) {
            System.debug('SMS execution skipped (test mode).');
            return;
        }

        if(this.ACTION == '1') sendWelcomeMsg(this.leads);
        if(this.ACTION == '2') sendNotConnectedMsg(this.leads);
        if(this.ACTION == '3') sendSVProposedMsg(this.visits);
        if(this.ACTION == '4') sendSVConfirmedMsg(this.visits);
        if(this.ACTION == '5') sendSVDoneMsg(this.visits);
        if(this.ACTION == '6') sendBookingDoneMsg(this.bookings);
        if(this.ACTION == '7') sendPaymentReceiptMsg(this.receipts);
        if(this.ACTION == '8') sendDemandRaisedMsg(this.demands);
        if(this.ACTION == '9') sendDemandReminderMsg(this.bookings);
        if(this.ACTION == '10') sendRevisedDemandMsg(this.booking, this.demandAmount, this.demandDueDate);
        if(this.ACTION == '11') sendWelcomeMail(this.booking);

    }

    // Method to send WELCOME SMS message to multiple leads
    public void sendWelcomeMsg(List<Lead> leads) {

        // Fetch SMS configuration from Custom Metadata
        SMS_Setting__mdt config = getSMSConfig('Welcome');

        if(config == null){
            System.debug('Template not found: No Active SMS template is available!');
            return;
        }

        List<Lead> leadsToUpdate = new List<Lead>();
        // Loop through the leads and send a message to each one
        for (Lead lead : leads) {
            String customerPhoneNumber = lead.Phone__c;
            String customerName = lead.FirstName != null ? lead.FirstName + ' ' + lead.LastName : lead.LastName;
            String projectName = lead.Allocated_Project__c;

            if (String.isBlank(customerPhoneNumber)) {
                continue; // Skip to the next lead if no phone number
            }

            String vars = 'mobileNos='+customerPhoneNumber+'&templateid='+config.Template_Id__c+'&var1='+customerName+'&var2='+projectName;

            // Send the message
            Boolean res = sendTextMessage(config, vars);

            Lead ld = new Lead();
            ld.Id = lead.Id;
            ld.Sent_Welcome_Msg__c = res;
            leadsToUpdate.add(ld);
        }

        try{
            update leadsToUpdate;
        }
        catch(Exception ex){
            System.debug('Error while updating leads:' + ex.getMessage());
        }
    }

    // Method to send NOTCONNECTED Text message to multiple leads
    public void sendNotConnectedMsg(List<Lead> leads) {

        // Fetch SMS configuration from Custom Metadata
        SMS_Setting__mdt config = getSMSConfig('Not_Connected');

        if(config == null){
            System.debug('Template not found: No Active SMS template is available!');
            return;
        }

        // Loop through the leads and send a message to each one
        for (Lead lead : leads) {
            String customerPhoneNumber = lead.Phone__c;
            String customerName = lead.Name;
            String projectName = lead.Allocated_Project__c;

            if (String.isBlank(customerPhoneNumber)) {
                continue; // Skip to the next lead if no phone number
            }

            String vars = 'mobileNos='+customerPhoneNumber+'&templateid='+config.Template_Id__c+'&var1='+customerName+'&var2='+projectName;

            // Send the message
            Boolean res = sendTextMessage(config, vars);

        }

    }

    // Method to send SVPROPOSED Text message to multiple leads
    public void sendSVProposedMsg(List<Site_Visit__c> visits) {

        // Fetch SMS configuration from Custom Metadata
        SMS_Setting__mdt config = getSMSConfig('SV_Proposed');

        if(config == null){
            System.debug('Template not found: No Active SMS template is available!');
            return;
        }

        // Loop through the leads and send a message to each one
        for (Site_Visit__c sv : visits) {
            String customerPhoneNumber = sv.SLead__r.Phone__c;
            String customerName = sv.SLead__r.Name;
            String projectName = sv.Project__c;
            DateTime svdatetime = sv.SV_Proposed_Date_Time__c.addHours(5).addMinutes(30);

            if (String.isBlank(customerPhoneNumber)) {
                continue; // Skip to the next lead if no phone number
            }

            String vars = 'mobileNos='+customerPhoneNumber+'&templateid='+config.Template_Id__c+'&var1='+customerName+'&var2='+projectName+'&var3='+svdatetime;

            // Send the message
            Boolean res = sendTextMessage(config, vars);

        }

    }

    // Method to send SVCONFIRMED Text message to multiple leads
    public void sendSVConfirmedMsg(List<Site_Visit__c> visits) {

        // Fetch SMS configuration from Custom Metadata
        SMS_Setting__mdt config = getSMSConfig('SV_Confirmed');

        if(config == null){
            System.debug('Template not found: No Active SMS template is available!');
            return;
        }

        Map<String, Project__c> projectMap = new Map<String, Project__c>();

        for(Project__c pr: [SELECT Id, Name, Location__c FROM Project__c]) {
            projectMap.put(pr.Name, pr);
        }
        // Loop through the leads and send a message to each one
        for (Site_Visit__c sv : visits) {
            String customerPhoneNumber = sv.SLead__r.Phone__c;
            String customerName = sv.SLead__r.Name;
            String projectName = sv.Project__c;
            DateTime svdatetime = sv.Date__c.addHours(5).addMinutes(30);
            String loc = projectMap.get(projectName).Location__c != null ? projectMap.get(projectName).Location__c : 'N/A';

            if (String.isBlank(customerPhoneNumber)) {
                continue; // Skip to the next lead if no phone number
            }

            String vars = 'mobileNos='+customerPhoneNumber+'&templateid='+config.Template_Id__c+'&var1='+customerName+'&var2='+projectName+'&var3='+svdatetime+'&var4='+loc;

            // Send the message
            Boolean res = sendTextMessage(config, vars);

        }

    }

    // Method to send SVDONE Text message to multiple leads
    public void sendSVDoneMsg(List<Site_Visit__c> visits) {

        // Fetch SMS configuration from Custom Metadata
        SMS_Setting__mdt config = getSMSConfig('SV_Done');

        if(config == null){
            System.debug('Template not found: No Active SMS template is available!');
            return;
        }

        // Loop through the leads and send a message to each one
        for (Site_Visit__c sv : visits) {
            String customerPhoneNumber = sv.SLead__r.Phone__c;
            String customerName = sv.SLead__r.Name;
            String projectName = sv.Project__c;
            String executiveName = sv.Owner.Name;


            if (String.isBlank(customerPhoneNumber)) {
                continue; // Skip to the next lead if no phone number
            }

            String vars = 'mobileNos='+customerPhoneNumber+'&templateid='+config.Template_Id__c+'&var1='+customerName+'&var2='+projectName+'&var3='+executiveName;

            // Send the message
            Boolean res = sendTextMessage(config, vars);

        }

    }

    // Method to send BOOKINGDONE WhatsApp message to multiple leads
    public void sendBookingDoneMsg(List<Booking__c> bookings) {

        // Fetch SMS configuration from Custom Metadata
        SMS_Setting__mdt config = getSMSConfig('SV_Done');

        if(config == null){
            System.debug('Template not found: No Active Whatsapp template is available!');
            return;
        }


        // Loop through the leads and send a message to each one
        for (Booking__c book : bookings) {
            String customerPhoneNumber = book.Mobile__c;
            String sal = book.S__c;
            String customerName = book.First_Applicant_Name__c;
            String projectName = book.Project1__r.Name;
            String unit = book.Plot__r.Name;
            String dim = book.Plot__r.Super_Built_up_Area__c + ' Sqft.';
            String bhk = book.Plot__r.BHK_Type__c;

            if (String.isBlank(customerPhoneNumber)) {
                continue; // Skip to the next lead if no phone number
            }

            String vars = 'mobileNos='+customerPhoneNumber+'&templateid='+config.Template_Id__c+'&var1='+sal+'&var2='+customerName+'&var3='+projectName+'&var4='+projectName+'&var5='+unit+'&var6='+dim+'&var7='+bhk;

            // Send the message
            Boolean res = sendTextMessage(config, vars);

        }

    }

    // Method to send PAYMENT RECEIPT SMS message to customers
    public void sendPaymentReceiptMsg(List<Receipt__c> receipts) {

        // Fetch SMS configuration from Custom Metadata
        SMS_Setting__mdt config = getSMSConfig('Payment Receipt');

        if(config == null){
            System.debug('Template not found: No Active SMS template is available!');
            return;
        }

        // Loop through the receipts and send a message to each one
        for (Receipt__c receipt : receipts) {
            String customerPhoneNumber = receipt.Booking__r.Mobile__c;
            String customerName = receipt.Booking__r.First_Applicant_Name__c;
            String amount = String.valueOf(receipt.Total_Received_Amount__c);
            String flatNo = receipt.Booking__r.Plot__r.Name;
            String projectName = receipt.Booking__r.Project1__r.Name;

            if (String.isBlank(customerPhoneNumber)) {
                continue; // Skip to the next receipt if no phone number
            }

            String vars = 'mobileNos='+customerPhoneNumber+'&templateid='+config.Template_Id__c+'&var1='+customerName+'&var2='+amount+'&var3='+flatNo+'&var4='+projectName;

            // Send the message
            Boolean res = sendTextMessage(config, vars);

        }

    }

    // Method to send DEMAND RAISED SMS message
    public void sendDemandRaisedMsg(List<Demand_Raised__c> demands) {

        // Fetch SMS configuration from Custom Metadata
        SMS_Setting__mdt config = getSMSConfig('Demand Note');

        if(config == null){
            System.debug('Template not found: No Active SMS template is available!');
            return;
        }

        // Loop through the demands and send a message to each one
        for (Demand_Raised__c demand : demands) {
            String customerPhoneNumber = demand.Booking__r.Mobile__c;
            String customerName = demand.Booking__r.First_Applicant_Name__c;
            String amount = String.valueOf(demand.Grand_Total__c);
            String unit = ' ' + demand.Booking__r.Unit_No__c;
            String projectandBlockName = demand.Project_Block_Name__c;
            String dueDate = demand.Payment_Due_Date__c != null
                ? String.valueOf(demand.Payment_Due_Date__c.format())
                : 'N/A';

            if (String.isBlank(customerPhoneNumber)) {
                continue; // Skip if no phone number
            }

            String vars = 'mobileNos='+customerPhoneNumber+'&templateid='+config.Template_Id__c+'&var1='+customerName+'&var2='+amount+'&var3='+unit+'&var4='+projectandBlockName+'&var5='+dueDate;

            // Send the message
            Boolean res = sendTextMessage(config, vars);

        }

    }

    // Method to send DEMAND REMINDER SMS message
    public void sendDemandReminderMsg(List<Booking__c> bookings) {

        // Fetch SMS configuration from Custom Metadata
        SMS_Setting__mdt config = getSMSConfig('REMINDER -1');

        if(config == null){
            System.debug('Template not found: No Active SMS template is available!');
            return;
        }

        // Loop through the bookings and send a message to each one
        for (Booking__c book : bookings) {
            String customerPhoneNumber = book.Mobile__c;
            String customerName = book.First_Applicant_Name__c;

            if (String.isBlank(customerPhoneNumber)) {
                continue; // Skip if no phone number
            }

            String vars = 'mobileNos='+customerPhoneNumber+'&templateid='+config.Template_Id__c+'&var1='+customerName;

            // Send the message
            Boolean res = sendTextMessage(config, vars);

        }

    }

    // Method to send REVISED DEMAND SMS message - Single Booking
    public void sendRevisedDemandMsg(Booking__c booking, Decimal amount, Date dueDate) {

        // Fetch SMS configuration from Custom Metadata
        SMS_Setting__mdt config = getSMSConfig('Revised Demand Note');

        if(config == null){
            System.debug('Template not found: No Active SMS template is available!');
            return;
        }

        String customerPhoneNumber = booking.Mobile__c;
        String customerName = booking.First_Applicant_Name__c;
        String unit = booking.Unit_No__c;
        String projectandBlockName = booking.Project_Block_Name__c;
        String dueDateStr = dueDate != null
            ? String.valueOf(dueDate.format())
            : 'N/A';
        String amountStr = amount != null ? String.valueOf(amount) : '0';

        if (String.isBlank(customerPhoneNumber)) {
            System.debug('No phone number found for booking: ' + booking.Id);
            return;
        }

        String vars = 'mobileNos='+customerPhoneNumber+'&templateid='+config.Template_Id__c+'&var1='+customerName+'&var2='+amountStr+'&var3='+unit+'&var4='+projectandBlockName+'&var5='+dueDateStr;

        // Send the message
        Boolean res = sendTextMessage(config, vars);

    }

    // Method to send WELCOME MAIL SMS message - Single Booking
    public void sendWelcomeMail(Booking__c booking) {

        // Fetch SMS configuration from Custom Metadata
        SMS_Setting__mdt config = getSMSConfig('Welcome Template');

        if(config == null){
            System.debug('Template not found: No Active SMS template is available!');
            return;
        }

        String customerPhoneNumber = booking.Mobile__c;
        String customerName = booking.First_Applicant_Name__c;
        String crmExecutiveName = booking.Owner_Full_Name__c;

        if (String.isBlank(customerPhoneNumber)) {
            System.debug('No phone number found for booking: ' + booking.Id);
            return;
        }

        String vars = 'mobileNos='+customerPhoneNumber+'&templateid='+config.Template_Id__c+'&var1='+customerName+'&var2='+crmExecutiveName;

        // Send the message
        Boolean res = sendTextMessage(config, vars);

    }

    // Helper method to fetch Text settings from Custom Metadata
    private SMS_Setting__mdt getSMSConfig(String templateName) {
        // Query the custom metadata record (assuming only one configuration record exists)
        List<SMS_Setting__mdt> config = [SELECT Template_Id__c,Template_Name__c, Sender_ID__c,  Authentication_Key__c, URL__c ,Route_Id__c
                                         FROM SMS_Setting__mdt where Template_Name__c = :templateName and Active__c = true LIMIT 1];
        return config.size() > 0 ? config[0] : null;
    }

    private Boolean sendTextMessage(SMS_Setting__mdt config, String vars) {
        Apex_Log__c log = new Apex_Log__c();

        // -------------------------------------
        // 1. Build Base Query Params
        // -------------------------------------
        Map<String, String> queryParams = new Map<String, String>{
            'AUTH_KEY'  => config.Authentication_Key__c,
                'senderId'  => config.Sender_ID__c,
                'routeId'   => config.Route_Id__c
                };

                    // -------------------------------------
                    // 2. Parse the dynamic vars (var1=xx&var2=yy etc)
                    // Supports unlimited params + values with '='
                    // -------------------------------------
                    if (String.isNotBlank(vars)) {
                        for (String pair : vars.split('&')) {
                            Integer idx = pair.indexOf('=');
                            if (idx > 0) {
                                String key = pair.substring(0, idx).trim();
                                String val = pair.substring(idx + 1).trim();
                                queryParams.put(key, val);
                            }
                        }
                    }

        // -------------------------------------
        // 3. Build final URL with URL encoding
        // -------------------------------------
        List<String> finalParts = new List<String>();

        for (String key : queryParams.keySet()) {
            String encodedValue = EncodingUtil.urlEncode(queryParams.get(key), 'UTF-8');
            finalParts.add(key + '=' + encodedValue);
        }

        String apiUrl = config.URL__c + '?' + String.join(finalParts, '&');

        // -------------------------------------
        // 4. Prepare HTTP Request
        // -------------------------------------
        HttpRequest req = new HttpRequest();
        req.setEndpoint(apiUrl);
        req.setMethod('GET');

        // Initialize the HTTP client
        Http http = new Http();
        HttpResponse res = http.send(req);

        log.Request__c = String.valueof(apiUrl);
        log.Input_parameters__c = String.join(finalParts, '&');
        log.Response__c = res.getBody();
        log.Status__c = res.getStatus();

        system.debug(res);
        // Handle the response
        if (res.getStatusCode() == 200) {
            System.debug('Message sent successfully! Response: ' + res.getBody());
            return true;
        } else {
            log.Error_Message__c = res.getBody();
            System.debug('Failed to send message. Status: ' + res.getStatus() + ' Response: ' + res.getBody());
        }

        Database.insert(log,false);
        return false;
    }

}