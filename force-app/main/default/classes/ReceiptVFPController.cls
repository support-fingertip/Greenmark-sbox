/****************************************************************
* Class Name   : ReceiptVFPController
* Company      : Fingertipplus
* Created Date : 06-02-2026
* @description : Controller for Receipt Visualforce page which:
*                - Retrieves receipt and related booking details
*                - Converts total amount into words
*                - Fetches first co-applicant information
*                - Loads receipt line items excluding TDS
*                - Calculates total received amount for display
* @author      : Durga Prasad
*
* Change Log:
* ----------------------------------------------------------------
* Ver | Author        | Date        | Description
* ----------------------------------------------------------------
* 1.0 | Durga Prasad | 06-02-2026  | Initial version
* 1.1 | Durga Prasad | 20-04-2026  | Grouped Receipt Line Items by
*     |              |             | Receipt__c + Payment_Type__c;
*     |              |             | Fixed formatIndianCurrency to
*     |              |             | static for inner class access
* ----------------------------------------------------------------
*****************************************************************/
public class ReceiptVFPController {
    
    public Id receiptId { get; set; }
    public String amountInWords { get; set; }
    public Co_Applicant__c firstCoApplicant { get; set; }
    
    public List<Receipt_Line_Item__c> receiptLineItems { get; set; }
    public Decimal totalReceivedAmount { get; set; }
    public ReceiptInfoWrapper receiptInfo { get; set; }
    public String totalAmountFormatted { get; set; }
    public List<LineItemWrapper> receiptLineItemWrappers { get; set; }
    
    // ─────────────────────────────────────────────────────────────
    // Inner Wrapper: Groups line items by Receipt__c + Payment_Type__c
    // formatIndianCurrency is static so it can be called from here
    // ─────────────────────────────────────────────────────────────
    public class LineItemWrapper {
        public String  paymentType       { get; set; }
        public String  modeOfPayment     { get; set; }
        public Date    receiptDate       { get; set; }
        public String  chequeOrTxnNumber { get; set; }
        public String  bankName          { get; set; }
        public Decimal totalAmount       { get; set; }
        public String  formattedAmount   { get; set; }
        public String  receiptId         { get; set; }
        
        public LineItemWrapper(String receiptId, String paymentType, Receipt_Line_Item__c item, Decimal total) {
            this.receiptId         = receiptId;
            this.paymentType       = paymentType;
            this.modeOfPayment     = item.Mode_of_Payment__c;
            this.receiptDate       = item.Receipt_Date__c;
            this.chequeOrTxnNumber = item.Cheque_no_Transaction_Number__c;
            this.bankName          = item.Bank_Name__c;
            this.totalAmount       = total;
            // Static call is valid from inner class
            this.formattedAmount   = ReceiptVFPController.formatIndianCurrency(total);
        }
    }
    
    // ─────────────────────────────────────────────────────────────
    // Inner Wrapper: Holds header/meta info for the receipt
    // ─────────────────────────────────────────────────────────────
    public class ReceiptInfoWrapper {
        public String receiptNo        { get; set; }
        public String customerId       { get; set; }
        public String customerName     { get; set; }
        public String unitNo           { get; set; }
        public String block            { get; set; }
        public String receiptDate      { get; set; }
        public String project          { get; set; }
        public String projectAddress   { get; set; }
        public String email            { get; set; }
        public String contactNo        { get; set; }
        public String webAddress       { get; set; }
        public String companyAddress   { get; set; }
        public String companyName      { get; set; }
        
        public ReceiptInfoWrapper() { }
    }
    
    // ─────────────────────────────────────────────────────────────
    // Static utility: Formats a Decimal into Indian currency style
    // e.g. 1234567 => 12,34,567
    // Made static so LineItemWrapper inner class can access it
    // ─────────────────────────────────────────────────────────────
    private static String formatIndianCurrency(Decimal amount) {
        if (amount == null) amount = 0;
        
        String intPart = String.valueOf(amount.longValue());
        
        if (intPart.length() <= 3) {
            return intPart;
        }
        
        String lastThree = intPart.substring(intPart.length() - 3);
        String remaining = intPart.substring(0, intPart.length() - 3);
        
        List<String> chunks = new List<String>();
        Integer j = remaining.length();
        while (j > 0) {
            Integer s = Math.max(j - 2, 0);
            chunks.add(remaining.substring(s, j));
            j = s;
        }
        
        List<String> reversed = new List<String>();
        for (Integer k = chunks.size() - 1; k >= 0; k--) {
            reversed.add(chunks[k]);
        }
        
        return String.join(reversed, ',') + ',' + lastThree;
    }
    
    // ─────────────────────────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────────────────────────
    /**
    * Method Name  : ReceiptVFPController (Constructor)
    * Description  : Initializes data required for Receipt Visualforce page.
    *
    * Functionality:
    * 1. Retrieves Receipt record and related booking/plot details.
    * 2. Converts total received amount into words format.
    * 3. Fetches first co-applicant linked to the booking.
    * 4. Fetches receipt line items and groups them by Payment_Type__c.
    * 5. Calculates total received amount from line items.
    *
    * Parameters:
    * @param stdController - StandardController instance from VF page
    *
    * Used From:
    * - Receipt Visualforce Page Controller
    */
    public ReceiptVFPController(ApexPages.StandardController stdController) {
        
        receiptId = stdController.getId();
        
        // ── 1. Retrieve Receipt record with all required relationships ──
        Receipt__c receiptRecord = [
            SELECT Name,
                   Total_Received_Amount__c,
                   Booking__c,
                   Booking__r.Plot__r.Name,
                   Booking__r.First_Applicant_Name__c,
                   Booking__r.SLead__r.Lead_ID__c,
                   Booking__r.Project1__r.Name,
                   Booking__r.Project_Type__c,
                   Owner_Email_Id__c,
                   Booking__r.Project1__r.Company_Address__c,
                   Type__c,
                   Booking__r.Unit_No__c,
                   Booking__r.Block_Name__c,
                   Booking__r.Block_Id__c,
                   CreatedDate,
                   Booking__r.CRM_Executive_Contact_No__c,
                   Booking__r.Company_Name__c
            FROM Receipt__c
            WHERE Id = :receiptId
        ];
        
        // ── 2. Retrieve Block details ──
        Block__c block = [
            SELECT Id, Name, Email__c, Project_Address__c,
                   Construction_Company_Name__c, Land_Company_Name__c,
                   Project_Name__c, Company_Name__c, Company_Address__c
            FROM Block__c
            WHERE Id = :receiptRecord.Booking__r.Block_Id__c
        ];
        
        // ── 3. Build ReceiptInfoWrapper ──
        NumberTOWordConvertion conversion = new NumberTOWordConvertion();
        receiptInfo = new ReceiptInfoWrapper();
        
        receiptInfo.receiptNo     = receiptRecord.Name;
        receiptInfo.customerId    = (receiptRecord.Booking__r != null && receiptRecord.Booking__r.SLead__r != null)
                                        ? receiptRecord.Booking__r.SLead__r.Lead_ID__c : '';
        receiptInfo.customerName  = (receiptRecord.Booking__r != null && receiptRecord.Booking__r.First_Applicant_Name__c != null)
                                        ? receiptRecord.Booking__r.First_Applicant_Name__c : '';
        receiptInfo.unitNo        = (receiptRecord.Booking__r != null) ? receiptRecord.Booking__r.Unit_No__c : '';
        receiptInfo.block         = (receiptRecord.Booking__r != null && receiptRecord.Booking__r.Block_Name__c != null)
                                        ? receiptRecord.Booking__r.Block_Name__c : '';
        receiptInfo.receiptDate   = receiptRecord.CreatedDate != null
                                        ? String.valueOf(receiptRecord.CreatedDate.day()).leftPad(2, '0')   + '/' +
                                          String.valueOf(receiptRecord.CreatedDate.month()).leftPad(2, '0') + '/' +
                                          String.valueOf(receiptRecord.CreatedDate.year())
                                        : '';
        receiptInfo.project        = (block != null && block.Project_Name__c != null) ? block.Project_Name__c : '';
        receiptInfo.email          = (receiptRecord.Owner_Email_Id__c != null) ? receiptRecord.Owner_Email_Id__c : '';
        receiptInfo.projectAddress = (block != null && block.Project_Address__c != null) ? block.Project_Address__c : '';
        receiptInfo.webAddress     = 'www.trifectaprojects.com';
        receiptInfo.contactNo      = (receiptRecord.Booking__r != null && receiptRecord.Booking__r.CRM_Executive_Contact_No__c != null)
                                        ? receiptRecord.Booking__r.CRM_Executive_Contact_No__c : '';
        receiptInfo.companyAddress = (block.Company_Address__c != null)
                                        ? block.Company_Address__c.replaceAll('(?i),?\\s*Bangalore', '<br/>Bangalore')
                                        : '';
        
        // Company name logic based on Project Type and Receipt Type
        receiptInfo.companyName = 'TRIFECTA PROJECTS PVT LTD';
        if (receiptRecord.Booking__r.Project_Type__c == 'Villas') {
            if (receiptRecord.Type__c == 'Land') {
                receiptInfo.companyName = (block.Land_Company_Name__c != null) ? block.Land_Company_Name__c : '';
            } else if (receiptRecord.Type__c == 'Construction') {
                receiptInfo.companyName = (block.Construction_Company_Name__c != null) ? block.Construction_Company_Name__c : '';
            }
        } else {
            receiptInfo.companyName = (block.Company_Name__c != null) ? block.Company_Name__c : '';
        }
        
        // ── 4. Initialize lists and totals ──
        receiptLineItems        = new List<Receipt_Line_Item__c>();
        receiptLineItemWrappers = new List<LineItemWrapper>();
        totalReceivedAmount     = 0;
        
        // ── 5. Fetch related data only if Booking exists ──
        if (receiptRecord.Booking__c != null) {
            
            // ── 5a. Co-applicants (first only) ──
            List<Co_Applicant__c> coApplicants = [
                SELECT Name,
                       Salutation__c,
                       Date_of_Birth__c,
                       Spouse_Date_Of_Birth_coapp__c,
                       Permanent_Address__c,
                       Communication_Address__c,
                       Pincode_office__c,
                       Other_Qualification__c,
                       Qualification__c,
                       Pincode_commmunication__c,
                       Pincode_permanent__c,
                       Other_Industry__c,
                       Office_Address__c,
                       Anniverssary_Date__c,
                       Son_Daughter_Wife_of__c,
                       Nationality__c,
                       Aadhar_Number__c,
                       Alternate_Contact_No__c,
                       Country_of_Residence__c,
                       Passport_Number__c,
                       PAN_Number__c,
                       Email__c,
                       Primary_Phone__c,
                       Office_Pincode__c,
                       Residential_Status__c,
                       Profession__c,
                       Industry__c,
                       Employeed_at__c,
                       Designation__c
                FROM Co_Applicant__c
                WHERE Booking__c = :receiptRecord.Booking__c
                ORDER BY CreatedDate ASC
                LIMIT 1
            ];
            
            if (!coApplicants.isEmpty()) {
                firstCoApplicant = coApplicants[0];
            }
            
            // ── 5b. Fetch Receipt Line Items for this Receipt ──
            receiptLineItems = [
                SELECT Payment_Type__c,
                       Cheque_no_Transaction_Number__c,
                       Received_Amount__c,
                       Bank_Name__c,
                       Mode_of_Payment__c,
                       Receipt__c,
                       Drawn_On__c,
                       Receipt_Date__c,
                       Payment_schedule__r.Name
                FROM Receipt_Line_Item__c
                WHERE Booking__c = :receiptRecord.Booking__c
                AND   Receipt__c = :receiptId
            ];
            
            // ── 5c. Collapse all line items into one summed row for this Receipt ──
            // Metadata (mode/instrument/bank/etc) comes from the first line of the
            // receipt. Sign is negative iff any line is 'TDS Refund' (Phase 2 makes
            // TDS Refund a solo-row receipt, so this is equivalent to "this is a
            // refund receipt").
            if (!receiptLineItems.isEmpty()) {
                Decimal sumAmt = 0;
                Boolean isNegative = false;
                for (Receipt_Line_Item__c item : receiptLineItems) {
                    sumAmt += item.Received_Amount__c != null ? item.Received_Amount__c : 0;
                    if (item.Payment_Type__c == 'TDS Refund') {
                        isNegative = true;
                    }
                }

                Receipt_Line_Item__c meta = receiptLineItems[0];
                String displayLabel = isNegative ? 'TDS Refund' : 'Receipt';

                LineItemWrapper rw = new LineItemWrapper(receiptId, displayLabel, meta, sumAmt);
                if (isNegative) {
                    rw.formattedAmount = '(' + formatIndianCurrency(sumAmt) + ')';
                    totalReceivedAmount = -sumAmt;
                } else {
                    totalReceivedAmount = sumAmt;
                }
                receiptLineItemWrappers.add(rw);
            }

            // ── 5d. Format totals ──
            totalAmountFormatted = totalReceivedAmount != null
                ? totalReceivedAmount.setScale(2).format()
                : '0.00';
            amountInWords = totalReceivedAmount != null
                ? conversion.getNumberTOWordConvertion(totalReceivedAmount.abs())
                : null;
        }
    }
}