public class getQuoteData {
    public Quote__c qout { get; set; }
    public Id recid { get; set; }

    public Decimal totalPercent { get; set; }
    public Decimal subTotalA { get; set; }
    public Decimal subtotalVillaA { get; set; }
    public Decimal subtotalRowHouseA { get; set; }
  
    public Decimal subTotalB {get; set;}
    public Decimal subTotalVillaB {get; set;}
    public Decimal subTotalRowHouseB {get; set;}
    
    public Decimal totalAmount { get; set; }
    public Decimal totalAmountAB { get; set; }
    public Decimal totalAmountVillaAB { get; set; }
    public Decimal totalAmountRowHouseAB { get; set; } 
    public Decimal grandtotalAmount { get; set; }
    public Decimal biscomStp { get; set; }
    public string projectName { get; set; }
    
    public String templateBody { get; set; }

    // Separate lists for Payment Schedules
    public List<Payment_Schedule__c> landSchedules { get; set; }
    public List<Payment_Schedule__c> constructionSchedules { get; set; }

    public getQuoteData(ApexPages.StandardController controller) {
        this.recId = ApexPages.currentPage().getParameters().get('id');


        //  Fetch Quote and child payment schedules
        qout = [
            SELECT Id, RERA__c, Unit__r.Unit_Facing_Direction__c, Unit__r.Floor__c,Project__c,
                   Carpet_Area__c, Balcony_Area_Sq_ft__c, Super_Built_UpArea__c, Rate_sq_Ft_Discount__c,Block_Lookup__c,
                   Base_Value__c, PLC__c, Floor_Rise_Charges_Rate__c, Total_Car_Parking_Charges__c,
                   amenities_charges__c, Legal_Documentation_Charges__c, GST__c, Grand_Total_Before_GST__c,
                    Grand_Total_Amount__c, Bescom__c, Generator_Charges__c,Unit__r.Name,
                   GST_Amount__c, Floor_Rise_Charge__c, Bescom_STP_and_Generator__c, Plot_Land_Area__c,
                   Land_Rate_Per_Sqft__c, Land_Cost__c, Extra_Land_Amount__c, PLC_Amount__c,
                   Bescom_Charges__c, STP_and_Generator_Charges__c,
                   (SELECT Id, Name, Payment_percent__c, S_No__c, Type__c
                    FROM Payment_Schedules__r
                    ORDER BY S_No__c ASC)
            FROM Quote__c
            WHERE Id = :recId
            LIMIT 1
        ];
        
        projectName = qout.Project__c != null ? qout.Project__c : '';
      
       if (qout.Project__c != null && qout.Block_Lookup__c != null) {
            List<General_Settings__c> settings = [
                SELECT Id, Template_Body__c 
                FROM General_Settings__c 
                WHERE Project_Name1__c INCLUDES (:qout.Project__c) 
                AND Block__c = :qout.Block_Lookup__c AND Type__c='Terms and Conditions'
                LIMIT 1
            ];
            
            if (!settings.isEmpty()) {
                this.templateBody = settings[0].Template_Body__c;
            }
        }
        
        subTotalA = nvl(qout.Base_Value__c) + nvl(qout.Floor_Rise_Charge__c)
                    + nvl(qout.Total_Car_Parking_Charges__c) + nvl(qout.PLC_Amount__c);
        subtotalVillaA = nvl(qout.Base_Value__c) + nvl(qout.Extra_Land_Amount__c) + nvl(qout.PLC_Amount__c);
        subtotalRowHouseA = nvl(qout.Base_Value__c);
        
        biscomStp = nvl(qout.Bescom__c) + nvl(qout.Generator_Charges__c); //Value
        
        subTotalB = nvl(qout.Bescom_STP_and_Generator__c) + nvl(qout.amenities_charges__c) + nvl(qout.Legal_Documentation_Charges__c);
        subTotalVillaB = nvl(qout.STP_and_Generator_Charges__c) + nvl(qout.Bescom_Charges__c);
        subTotalRowHouseB =nvl(qout.STP_and_Generator_Charges__c) + nvl(qout.Bescom_Charges__c)+ nvl(qout.PLC_Amount__c) + nvl(qout.Legal_Documentation_Charges__c);
        
        totalAmountAB = subTotalA + subTotalB;
        totalAmountVillaAB = subtotalVillaA + subTotalVillaB;
        totalAmountRowHouseAB = subtotalRowHouseA + subTotalRowHouseB;
        grandtotalAmount = totalAmountAB + nvl(qout.GST_Amount__c);

        //  Split Payment Schedules by Type__c
        landSchedules = new List<Payment_Schedule__c>();
        constructionSchedules = new List<Payment_Schedule__c>();

        for (Payment_Schedule__c ps : qout.Payment_Schedules__r) {
            if (ps.Type__c == 'Land') {
                landSchedules.add(ps);
            } else if (ps.Type__c == 'Construction') {
                constructionSchedules.add(ps);
            }
        }
    }

    // Null-safe helper
    public Decimal nvl(Decimal value) {
        return value == null ? 0 : value;
    }
}