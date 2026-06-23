public class BookingCancellationApprovalController {
    public class DataBox {
        @auraEnabled public decimal cancellationAmount;
        @auraEnabled public boolean isAfterPostAggrement;
    }
   
    @AuraEnabled
    public static DataBox getRecordData(Id recordId) {
        DataBox db = new DataBox();
        // 1. Get Booking Data
        Booking__c bk =  [SELECT Id,Stage__c,Agreement_Status__c,Total_Amount__c FROM Booking__c WHERE Id = :recordId LIMIT 1];
        boolean isAfterPostAggrement = false;
        if(bk.Stage__c == 'Booked' || (bk.Stage__c =='Agreement' && (bk.Agreement_Status__c != 'Executed' && bk.Agreement_Status__c != 'Executed & Registered')))
        {
            db.cancellationAmount = 25000;
        }
        else
        {
            decimal amount = (bk.Total_Amount__c * 10)/100;
            db.cancellationAmount = amount;
            isAfterPostAggrement = true;
        }
        db.isAfterPostAggrement = isAfterPostAggrement;
        return db;
    }
    
    @AuraEnabled
    public static boolean sendCancellationApproval(Id recId, string cancellationReason, String cancellationRemarks, Decimal cancellationCharges,boolean isAfterPostAggrement){
        List<Booking__c> bklist = [Select Id, Name, Cancellation_Charge__c,Cancellation_Reason__c,	Stage__c,
                                   Cancellation_Description__c From Booking__c Where id =: recId];
        // Get Cancellation Amount from Custom Label
        Decimal cancellationAmount = 0;
        
        if(String.isNotBlank(Label.Cancellation_Amount)){
            cancellationAmount = Decimal.valueOf(
                Label.Cancellation_Amount.replace(',', '')
            );
        }
        
        for(Booking__c bk : bklist)
        {
            bk.Cancellation_Reason__c = cancellationReason;
            bk.Cancellation_Description__c = cancellationRemarks;
            bk.Cancellation_Charge__c = cancellationCharges;
            bk.Is_Cancelled__c = true;
            if((cancellationCharges >= cancellationAmount) && !isAfterPostAggrement) {
                bk.Cancellation_Status__c = 'Approved';
                bk.Stage__c = 'Cancellation';
            }
        }
        Update bklist;
        

        // Send for approval if cancellationCharges is less than defined Cancellation Amount
        if((cancellationCharges < cancellationAmount) || isAfterPostAggrement) {
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Cancellation request');
            req1.setObjectId(recId);
            req1.setSubmitterId(userInfo.getUserId());
            req1.setProcessDefinitionNameOrId('Cancellation_Approval_For_Booking_heads');
            req1.setSkipEntryCriteria(true);
            Approval.ProcessResult result = Approval.process(req1);
        }
        return true;
    }
    
}