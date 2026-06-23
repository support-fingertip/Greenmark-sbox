public without sharing class BookingController {
    @AuraEnabled
    public static List<String> getPaymentTypePicklistValues() {
        List<String> paymentTypeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Booking__c.Mode_Of_Payment__c.getDescribe();
        
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            paymentTypeValues.add(picklistEntry.getLabel());
        }
        
        return paymentTypeValues;
    }
    
    @AuraEnabled
    public static List<String> getFundingtTypePicklistValues() {
        List<String> paymentTypeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Booking__c.Funding_Type__c.getDescribe();
        
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            paymentTypeValues.add(picklistEntry.getLabel());
        }
        
        return paymentTypeValues;
    }
    
    public class returnBox {
        @AuraEnabled public Quote__c quote;
        @AuraEnabled public List<String> bankNames = new List<String>();
    }
    
    @AuraEnabled
    public static returnBox quoteRecord(String recId) {
        returnBox rt = new returnBox();
        rt.quote = [select id,name,BHK_Type__c,Super_Built_UpArea__c,Rate_sq_Ft_Discount__c,
                    Unit_Number__c,Unit__r.Unit_Facing_Direction__c, Unit__r.Status__c,Property_Type__c,
                    Project__c,Wing__c,Block__c,Agreement_Value_Before_GST__c,SLead__r.Email,Rate_per_sqft__c,
                    Extra_Land_Amount__c,Grand_Total_Amount__c,
                    SLead__r.Name, SLead__r.Phone__c,SLead__r.Age__c,Plot_Land_Area__c,Construction_Cost__c,Land_Cost__c
                    from Quote__c where Id=:recId ];
        List<String> bankNames = new List<String>();
        Schema.DescribeFieldResult fieldResult = Booking__c.Bank_Name__c.getDescribe();
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            bankNames.add(picklistEntry.getLabel());
        }
        rt.bankNames = bankNames;
        return rt;
    }
    @AuraEnabled
    public static Id saveFile(Id parentId, String fileName, String base64Data, String contentType, String fileType) {
        System.debug('Incoming File: ' + fileName + ', Type: ' + fileType);
        
        // Decode Base64 content
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        Blob fileBody = EncodingUtil.base64Decode(base64Data);
        
        // Extract base name without extension
        String cleanName = fileName;
        if (fileName.contains('.')) {
            cleanName = fileName.substring(0, fileName.lastIndexOf('.'));
        }
        
        //If fileType provided, prepend or use it as a prefix
        String title = !String.isBlank(fileType) ? fileType.trim() : cleanName;
        
        // Step 1: Create ContentVersion properly
        ContentVersion cv = new ContentVersion();
        cv.Title = title; // No file extension here!
        cv.PathOnClient = fileName; // Include full name here
        cv.VersionData = fileBody;
        cv.IsMajorVersion = true;
        insert cv;
        
        System.debug('Inserted ContentVersion Id: ' + cv.Id);
        
        //  Step 2: Get the ContentDocumentId
        Id contentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id 
            LIMIT 1
        ].ContentDocumentId;
        
        //  Step 3: Create ContentDocumentLink (Link File to Record)
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = parentId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        
        System.debug('Linked ContentDocument: ' + contentDocumentId + ' to Record: ' + parentId);
        
        return contentDocumentId;
    }
    @auraEnabled
    public static string convertQuote(string recId,Booking__c book,List<Co_Applicant__c> applicantList){
        //Getting Record Type with Name
        List<RecordType> recordTypeList = [
            SELECT Id, Name 
            FROM RecordType 
            WHERE SObjectType = 'Booking__c'
        ];
        Map<String,Id> recordTypeNameToId = new Map<String,Id>();
        
        for (RecordType recType : recordTypeList) {
            recordTypeNameToId.put(recType.Name, recType.Id);
        }
        
        
        Quote__c qt = [SELECT Id,Name,SLead__c,SLead__r.Email,Approval_status__c,Quote_status__c,
                       Maintenance_Charge__c,Corpus_Fund__c,Built_up_area__c,Payment_Type__c,Carpet_Area__c,
                       Infrastructure_Charges_per_sqft__c,Project__c,Property_Type__c,Unit__c,
                       SLead__r.Secondary_Email__c,SLead__r.Name,Plot_Type__c,Plot_Land_Area__c,Block_Lookup__c,
                       Quote_date__c,Floor_Rise_Charges_Rate__c,Clubhouse_Charges__c,Unit__r.Status__c,
                       Unit__r.Name,Unit__r.Block_Lookup__r.CRM_Executive__c,
                       PLC_Amount__c,Bescom__c,Generator_Charges__c,amenities_charges__c,Floor_Rise_Charge__c,Car_Parking__c,
                       Legal_Documentation_Charges__c,Extra_car_parking_charges__c,Need_Additional_Car_Parking__c,Extra_Land_Amount__c
                       ,Land_Rate_Per_Sqft__c,GST__c,Grand_Total_Before_GST__c FROM Quote__c WHERE Id=:recId];
        Project__c pro = [select id,name,CRM_executive__c,Project_Type__c,Finance_User__c,Project_Sales_Head__c,CRM_Manager__c,Sales_Head__c,
                          CRM_Head__c from Project__c where Project__c =: qt.Project__c];
        Block__c block = [select Id,CRM_Manager__c,CRM_Head__c,CRM_Executive__c from Block__c where Id =: qt.Block_Lookup__c];
        
        if(qt.Unit__r.Status__c == 'Sold' || qt.Unit__r.Status__c == 'Booked'){
            return 'Unit not available';
        }
        else
        {
            Booking__c bk = new Booking__c();
            bk=book;
            bk.Quote__c = qt.Id;
            bk.Block__c = block.Id;
            bk.Stage__c = 'Booked';
            bk.SLead__c = qt.SLead__c;
            bk.Project__c = qt.Project__c;
            if( pro.Finance_User__c != null) bk.Finance_Lead__c = pro.Finance_User__c;
            bk.Project_Type__c = qt.Property_Type__c;
            bk.Project1__c = pro.Id;
            bk.Plot__c = qt.Unit__c;
            bk.Email1__c=qt.SLead__r.Secondary_Email__c;
            bk.Applicant_Name__c = qt.SLead__r.Name;
            bk.RecordTypeId = recordTypeNameToId.get(qt.Property_Type__c);
            bk.Project_Sales_Head__c = pro.Project_Sales_Head__c;
            bk.Sales_User__c = UserInfo.getUserId();
            bk.Sales_Head__c =  pro.Sales_Head__c;
            bk.Carpet_Area__c = qt.Carpet_Area__c;
            
            //Mapping Quote fields Booking
            bk.PLC_Charges__c = qt.PLC_Amount__c;
            bk.Bescom_per_Sq_ft__c = qt.Bescom__c;
            bk.Generator_Per_Sq_Ft__c = qt.Generator_Charges__c;
            bk.Amenity_Charges__c = qt.amenities_charges__c;
            bk.Floor_Rise_Amount__c = qt.Floor_Rise_Charge__c;
            bk.Car_Parking_Amount__c = qt.Car_Parking__c;
            bk.Legal_Charge__c = qt.Legal_Documentation_Charges__c;
            bk.Additional_Car_Parking_Amount__c = qt.Extra_car_parking_charges__c;
            bk.Extra_Land_Amount__c = qt.Extra_Land_Amount__c;
            bk.Land_Per_Sq_ft_Charge__c = qt.Land_Rate_Per_Sqft__c;
            bk.GST_Percent__c =qt.GST__c;
            bk.Grand_Total_Before_GST__c = qt.Grand_Total_Before_GST__c;
            //CRM Team
            if(block != null)
            {
                bk.CRM_Manager__c = block.CRM_Manager__c != null ? block.CRM_Manager__c : null ;
                bk.CRM_Executive__c = block.CRM_Executive__c != null ? block.CRM_Executive__c : null ;
                bk.CRM_Head__c = block.CRM_Head__c != null ? block.CRM_Head__c : null ;
            }
            
            insert bk;
            
            List<Co_Applicant__c> applicantListToInsert = new List<Co_Applicant__c>();
            for(Co_Applicant__c coA : applicantList){
                if(coA.Name != null && coA.Name != ''){
                    coA.Booking__c = bk.Id;
                    applicantListToInsert.add(coA);
                }
            }
            insert applicantListToInsert;
            
            
            Lead ld = new Lead();
            ld.Id=qt.SLead__c;
            ld.Lead_Status__c='Booked';
            ld.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
            update ld;
            
            Quote__c quot = new Quote__c();
            quot.Id = qt.Id;
            quot.Quote_status__c = 'Converted';
            update quot;
            
            plot__c pt=new plot__c();
            pt.id = qt.Unit__c;
            pt.Status__c='Booked';
            update pt;
            
            //Create first Recipet for Booking Amount automatically
            if( bk.Booking_Amount__c != null && bk.Booking_Amount__c != 0){
                List<Receipt_Line_Item__c> replineItems = new List<Receipt_Line_Item__c>();
                Receipt_Line_Item__c repItem = new Receipt_Line_Item__c();
                repItem.Payment_Type__c = 'Booking Amount';
                repItem.Bank_Name__c = bk.Bank_Name__c;
                repItem.Mode_of_Payment__c = bk.Mode_Of_Payment__c;
                repItem.Received_Amount__c = bk.Booking_Amount__c;
                repItem.Branch__c = bk.Branch_Name__c;
                if(bk.Mode_Of_Payment__c == 'Cheque'){
                    repItem.Drawn_On__c = bk.Posting_in_Date__c;
                }else{
                    repItem.Drawn_On__c = bk.Date_of_Payment__c;  
                }
                repItem.Cheque_no_Transaction_Number__c = bk.Transaction_ID__c;
                replineItems.add(repItem);
                String receiptType  = qt.Property_Type__c == 'Villas' ? 'Land' : '';
                ReceiptController.insertReceiptLineItems(replineItems, 'Booking Amount', string.valueof(bk.Booking_Date__c),bk.Id,bk.Booking_Amount__c,0,null,receiptType);
            }
            
            return bk.Id;
            
        }
        
    }
    
    public static void changeUnitStatus(List<Booking__c> bookList) {   
        Set<Id> units = new Set<Id>();
        for (Booking__c bcc : bookList) {
            units.add(bcc.Plot__c);
        }
        List<Plot__c> plotList = [SELECT Id, Name, Status__c FROM Plot__c WHERE Id IN :units];
        for (Plot__c plt : plotList) {
            plt.Status__c = 'Available';
        }
        if (!plotList.isEmpty()) {
            update plotList;
        }
    }
    
}