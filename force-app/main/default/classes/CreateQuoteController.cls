public Without Sharing class  CreateQuoteController {
    public class QuoteResponse {
        @AuraEnabled public String quoteId { get; set; }
        @AuraEnabled public String recordTypeName { get; set; }
    }
    public class returnBox {
        @AuraEnabled public list<Block__c> blockList;
        @AuraEnabled public list<Plot__c> unitList;
        @AuraEnabled public List<String> paymentTypeValues = new List<String>();
        @AuraEnabled public decimal discountLimit;
        @AuraEnabled public boolean showReferalPercentage;
        @AuraEnabled public boolean isProjectNameExisted;
    }
    public class databox{
        @AuraEnabled 
        public List<Payment_schedule__c> payList;
        @AuraEnabled
        public List<Master_payment_schedule__c> MasterpayList;
        @AuraEnabled
        public Decimal grandTotal;
        @AuraEnabled
        public Decimal paymentSum;
        @AuraEnabled
        public Decimal RecivedAmountTotal;
        @AuraEnabled
        public Decimal totalPercent;
        @AuraEnabled
        public Decimal RecivedAmount;
        @AuraEnabled
        public string objectName;
        @AuraEnabled
        public string projectName;
        @AuraEnabled
        public string flatNumber;
        @AuraEnabled
        public string blockName;
        @AuraEnabled
        public Decimal RecivedPercent;
        @AuraEnabled
        public Decimal ScheduledAmount;
        @AuraEnabled
        public Decimal TotalOutStandingDueAmount;
        @AuraEnabled
        public Decimal TotalPaidAmount;
    }
    
    @AuraEnabled
    public static returnBox getData(string recId){
        returnBox rt = new returnBox();
        User us = [select Id,Discount_Limit__c from User where Id =: UserInfo.getUserId()];
        Lead ld =[select id ,Allocated_Project__c,Source_Type__c,Credit_Source__c from Lead where id =:recId limit 1];
        rt.showReferalPercentage = ld.Credit_Source__c == 'Referral and Loyalty' ? true : false;
        // Check Project existence
        String projectName = ld.Allocated_Project__c;
        rt.isProjectNameExisted = !String.isBlank(projectName);
        if (rt.isProjectNameExisted) {
            list<Project__c> projectList = [select Id,Project_Type__c from Project__c where Project__c =:projectName limit 1];
            string projectType = projectList[0].Project_Type__c;
            rt.blockList =  [select Id,Name,Project__r.Name,Project__c from Block__c where Project__r.Project__c =:projectName ];
            List<String> paymentTypeValues = new List<String>();
            Schema.DescribeFieldResult fieldResult = Quote__c.Payment_Type__c.getDescribe();
            for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
                paymentTypeValues.add(picklistEntry.getLabel());
            }
            rt.paymentTypeValues = paymentTypeValues;
            rt.discountLimit = us.Discount_Limit__c;
        }
        return rt;
    }
    @AuraEnabled
    public static List<Plot__c> getPlots(string recId){
        system.debug('recId: ' + recId);
        List<Plot__c> plotList = new List<Plot__c>();
        plotList = [select Id, Name,GST1__c, Plot_Type__c,Infrastructure_Charges_per_sqft__c,Project__r.Name,
                    Balcony_Area_Sq_ft__c,Project__c,Super_Built_up_Area__c,Plot_Land_Area__c,Carpet_Area__c,
                    BHK_Type__c,Rate_per_sqft__c,Clubhouse_Charges__c,Piped_Gas__c,Land_Rate_Per_Sqft__c,
                    Project__r.Franking_Shifting_Rate__c,Generator_Charges__c,Bescom__c,Unit_Type__c,
                    Block_Lookup__c,Water_Electricity_Charges__c,Legal_Charges__c,
                    Wing__c,Car_Parking__c,Project__r.Project__c,Scheme__c,SitOut_Area_Sq_ft__c,
                    Terrace_Area_Sq_ft__c,Project__r.Home_Automation__c,Tower__c,Floor__c,Mort_Non_Mortgage__c,
                    Utility_in_SFT__c,Balcony_in_SFT__c,PLC__c,
                    Carpet_Area_in_SFT__c,UDS_in_Sqyards__c,SBA_in_SFT__c,Corner_Non_Corner__c,Corpus_Fund__c,
                    Legal_Documentation_Charges__c,amenities_charges__c,Project__r.Maintenance_Charge_Rate__c,Project__r.Clubhouse_Charges__c,
                    Garden_Area_Sq_ft__c,W_E_Charges__c, Project__r.GST_on_Aggrement__c, Project__r.Project_Type__c,
                    Project__r.GST_on_Other__c,Unit_Facing_Direction__c,Maintenance_Charge__c,Floor_Rise_Charge__c,
                    Project__r.Guideline_Value_Charges__c from Plot__c where Block_Lookup__c =:recId and Status__c = 'Available'];
        system.debug('plotList: ' + plotList);
        return plotList;
    }
    @AuraEnabled
    public static List<Payment_schedule__c> getPaymentSchedules(String Pay, String Project,String blockId){
        List<Payment_schedule__c> schdules = new List<Payment_schedule__c>();
        List<Master_payment_schedule__c> Master = new List<Master_payment_schedule__c>();
        
        block__c block = [select Id,Type__c from block__c where Id =:blockId];
        // Step 1: Try to get block-wise schedule if blockId is present
        if (blockId != null) {
            Master = [ SELECT Id, Project__c, S_No__c, Name, Payment_Percent__c, Amount__c, Completed_Date__c, Due_Date__c, Status__c,
                      Is_Land__c,Is_Construction__c,Block__r.Intrest_Percentage__c,Block__c,Include_Interest__c FROM Master_payment_schedule__c
                      WHERE Project__r.Project__c = :Project
                      AND Block__c = :blockId and Block__c!= null ORDER BY S_No__c ASC];
        }
        for(Master_payment_schedule__c mps : Master){
            Payment_schedule__c ps = new Payment_schedule__c();
            if(Pay == 'Standard')
            {
                ps.Master_Payment_Schedule__c = mps.Id;
            }
            
            ps.Payment_percent__c = mps.Payment_Percent__c;
            ps.Type__c = mps.Is_Land__c ? 'Land' : mps.Is_Construction__c ? 'Construction' : '';
            ps.Name = mps.Name;
            ps.Interest_Percent__c = mps.Block__c !=null ? mps.Block__r.Intrest_Percentage__c : 0;
            ps.S_No__c = mps.S_No__c;
            ps.Include_Interest__c = mps.Include_Interest__c;
            // Make only FIRST schedule Completed When welcome mail sent 1st payment schdule need to completed
            if(block.Type__c == 'Apartments' || block.Type__c == 'Row House' || block.Type__c == 'Villas')
            {
                if(mps.S_No__c == 1){
                    ps.Status__c = 'Completed';
                }
            }
           
            schdules.add(ps); 
        }
        
        if(schdules.size()==0){
            schdules = null;
        }
        return schdules;
    }

    
    @AuraEnabled
    public static QuoteResponse saveOppPlot(Quote__c oppPlot,List<Payment_schedule__c> payList,boolean isAutoApproval) {
        List<RecordType> recordTypeList = [
            SELECT Id, Name 
            FROM RecordType 
            WHERE SObjectType = 'Quote__c'
        ];
        Map<String,Id> recordTypeNameToId = new Map<String,Id>();
        Map<Id,String> recordTypeIdToName = new Map<Id,String>();
        
        for (RecordType recType : recordTypeList) {
            recordTypeNameToId.put(recType.Name, recType.Id);
            recordTypeIdToName.put(recType.Id, recType.Name);
        }
        
        oppPlot.RecordTypeId = recordTypeNameToId.get(oppPlot.Property_Type__c);
        if(isAutoApproval == true)
        {
            oppPlot.Quote_status__c = 'Management User Approved';
        }
        
        if (oppPlot.Id == null) {
            insert oppPlot;
        } else {
            update oppPlot;
        }
        string quoteid = oppPlot.Id;
        String sObjName = Id.valueOf(quoteid).getSObjectType().getDescribe().getName();
        List<Payment_schedule__c> schduleList = new List<Payment_schedule__c>();
        list<booking__c>blist=new list<booking__C>();
        List<Quote__c> quo = [Select id,name,Payment_Type__c,Grand_Total_Amount__c,Total_Land_Amount__c,
                             Construction_Cost__c from Quote__c where id=:quoteid limit 1];
        System.debug(quoteid);
        Decimal grandTotal = quo[0].Grand_Total_Amount__c != null ? quo[0].Grand_Total_Amount__c : 0;
        if(quo != null && !quo.isEmpty()){
            Decimal landTotal  = quo[0].Total_Land_Amount__c != null ? quo[0].Total_Land_Amount__c : 0;
            Decimal constTotal = quo[0].Construction_Cost__c != null ? quo[0].Construction_Cost__c : 0;
            
            for(Payment_schedule__c pay : payList){
                
                Payment_schedule__c ps = new Payment_schedule__c();
                
                // ----- COMMON FIELD MAPPING -----
                ps.Name = pay.Name;
                ps.Payment_Percent__c = pay.Payment_Percent__c;
                ps.Payment_Due_Date__c = pay.Payment_Due_Date__c;
                ps.Master_Payment_Schedule__c = pay.Master_Payment_Schedule__c;
                ps.S_No__c = pay.S_No__c;
                ps.Type__c = pay.Type__c;
                ps.Interest_Percent__c = pay.Interest_Percent__c;
                ps.Include_Interest__c = pay.Include_Interest__c;
                ps.Status__c = pay.Status__c;
                ps.Quote__c = quoteid;
                
                Decimal percent = pay.Payment_Percent__c != null ? pay.Payment_Percent__c : 0;
                
                // ----- AMOUNT CALCULATION (SINGLE PLACE) -----
                if(percent > 0){
                    
                    if(pay.Type__c == 'Land'){
                        ps.Amount__c = (landTotal * percent) / 100;
                    }
                    else if(pay.Type__c == 'Construction'){
                        ps.Amount__c = (constTotal * percent) / 100;
                    }
                    else{
                        ps.Amount__c = (grandTotal != null) ? (grandTotal * percent / 100) : 0;
                    }
                    
                } else {
                    ps.Amount__c = 0;
                }
                
                schduleList.add(ps);
            }
            
            System.debug('schduleList :' + schduleList);
            
            upsert schduleList;
        }
        
        QuoteResponse resp = new QuoteResponse();
        resp.quoteId = oppPlot.Id;
        resp.recordTypeName = recordTypeIdToName.get(oppPlot.RecordTypeId);
        
        return resp;
    }
    
    @AuraEnabled
    public static Void deleteQuote(String recId){
        Quote__c qt=[select id  from Quote__c where id =:recId ];
        List<Payment_schedule__c> pymlist = [select id from Payment_schedule__c where Id =:qt.Id];
        Delete pymlist;
        Delete qt;
    }
    @AuraEnabled
    public static void callQuoteApproval(String recId) {
        try {
            Quote__c q = [
                SELECT Id, OwnerId
                FROM Quote__c
                WHERE Id = :recId
                LIMIT 1
            ];
            
            System.debug('Submitting Quote for approval: ' + q.Id);
            if(!test.isRunningTest()){
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(q.Id);
            // Optional: only use this if you explicitly want the record owner as submitter
            // req.setSubmitterId(q.OwnerId);
            req.setProcessDefinitionNameOrId('Quote_Approval_Process_2');
            req.setSkipEntryCriteria(false);
            
            Approval.ProcessResult result = Approval.process(req);
            
            if (!result.isSuccess()) {
                for (Database.Error err : result.getErrors()) {
                    System.debug('Approval submission failed: ' + err.getMessage());
                }
                throw new AuraHandledException('Approval submission failed. Please check setup.');
            }
            } 
            System.debug('Approval submitted successfully for Quote: ' + q.Id);
           
        } catch (Exception e) {
            System.debug('Error in callQuoteApproval: ' + e.getMessage());
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static void deleteSchedule(string recId){
        DELETE [SELECT Id FROM Payment_schedule__c WHERE Id=:recId];
    }

    /**Not in Use**/
    @AuraEnabled
    public static void insertSchedules(List<Payment_schedule__c> payList,string quoteid){
        String sObjName = Id.valueOf(quoteid).getSObjectType().getDescribe().getName();
        List<Payment_schedule__c> schduleList = new List<Payment_schedule__c>();
        list<booking__c>blist=new list<booking__C>();
        List<Quote__c> quo = [Select id,name,Payment_Type__c from Quote__c where id=:quoteid limit 1];
        System.debug(quoteid);
        if(quo[0].Payment_Type__c=='Standard')
        {
            for(Payment_schedule__c pay : payList){
                Payment_schedule__c ps = new Payment_schedule__c();
                ps.Name = pay.Name;
                ps.Payment_Percent__c = pay.Payment_Percent__c;
                ps.Payment_Due_Date__c = pay.Payment_Due_Date__c;
                ps.Master_Payment_Schedule__c = pay.Master_Payment_Schedule__c;
                ps.S_No__c = pay.S_No__c;
                ps.Quote__c = quoteid;
                schduleList.add(ps);
            }
        }
        else if(quo[0].Payment_Type__c=='Custom'){
            for(Payment_schedule__c pay : payList)
            {
                system.debug(pay);
                Payment_schedule__c ps = new Payment_schedule__c();
                ps = pay;
                ps.quote__c = quoteid;
                schduleList.add(ps);
            }
        }
        system.debug( 'schduleList :'+ schduleList);
        upsert schduleList;
    }
    @AuraEnabled
    public static databox QuoteCreate(String Leadid,String Quoteid){
        databox db = new databox();
        String sObjName = Id.valueOf(Quoteid).getSObjectType().getDescribe().getName();
        db.objectName = sObjName;
        List<Payment_schedule__c> schdules;
        string paymentType;
        schdules = [SELECT Id,Name,Payment_percent__c,Recived_Per__c,S_No__c,status__c,Booking__c,Quote__c,Quote__r.Grand_Total__c,Quote__r.project__c,Quote__r.unit__r.Name FROM Payment_schedule__c WHERE Quote__c =:Quoteid  ORDER BY S_No__c ASC];
        Quote__c qt = [SELECT Id,Grand_Total__c,Plot_Type__c,project__c,Payment_Type__c,unit__r.Name FROM Quote__c WHERE Id=:Quoteid LIMIT 1];
        db.grandTotal = qt.Grand_Total__c;
        db.projectName = qt.project__c;
        paymentType = qt.Payment_Type__c;
        db.flatNumber =qt.unit__r.Name;
        //db.blockName=qt.Block_Lookup__r.Name;
        // system.debug(db.blockName +'-------------------');
        return db;
    }

    
}