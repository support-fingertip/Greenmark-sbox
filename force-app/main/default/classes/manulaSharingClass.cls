public class manulaSharingClass {
    public static void manualShareSiteVisit(Map<Id,Id> SVMap){
        List<Site_Visit__Share> SVShareList = new List<Site_Visit__Share>();
        for(Id con : SVMap.keySet()){
            Site_Visit__Share ldShr  = new Site_Visit__Share();
            ldShr.parentId = con;
            ldShr.UserOrGroupId = SVMap.get(con);
            ldShr.AccessLevel = 'Read';
            ldShr.RowCause = Schema.Site_Visit__Share.RowCause.Manual;
            SVShareList.add(ldShr);
        }
        system.debug('SVShareList'+SVShareList);
        if(SVShareList.size()>0){
            List<Database.SaveResult> srList = Database.insert(SVShareList,false);
            for(Database.SaveResult sr : srList){
                if(sr.isSuccess()){
                    system.debug('Success');
                }
                else {
                    Database.Error err = sr.getErrors()[0];
                    system.debug('Error Message'+err.getMessage());
                    if(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  &&  
                       err.getMessage().contains('AccessLevel')){
                       }
                    else{
                    }
                }
            }
        }
    }
    public static Boolean manualShareLeadVisit(Map<Id,Id> LeadMap){
        Boolean res;
        List<LeadShare> LeadShareList = new List<LeadShare>();
        for(Id con : LeadMap.keySet()){
            LeadShare ldShr  = new LeadShare();
            ldShr.LeadId = con;
            ldShr.UserOrGroupId = LeadMap.get(con);
            ldShr.LeadAccessLevel = 'Read';
            ldShr.RowCause = Schema.LeadShare.RowCause.Manual;
            LeadShareList.add(ldShr);
        }
        system.debug('LeadShareList'+LeadShareList);
        if(LeadShareList.size()>0){
            List<Database.SaveResult> srList = Database.insert(LeadShareList,false);
            for(Database.SaveResult sr : srList){
                if(sr.isSuccess()){
                    system.debug('Success');
                    res = true;
                }
                else {
                    Database.Error err = sr.getErrors()[0];
                    system.debug('Error Message'+err.getMessage());
                    if(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  &&  
                       err.getMessage().contains('AccessLevel')){
                       }
                    else{
                    }
                    res = false;
                }
            }
        }
        return res;
    }
    
    
    public static void shareAnyRecord(List<Lead> leadList,String levelAccess) {
        
        Map<Id,Id> SVMap = new Map<Id,Id>();
        for(Lead ld : leadList){
            SVMap.put(ld.Lead_OwnerSecondary__c,ld.Id);
           //SVMap.put(ld.Id, ld.Lead_OwnerSecondary__c);
        }
        if(SVMap.size() >0){
            List<SObject> shareRecords = new List<SObject>();
            for(Id recordId :SVMap.keySet()){
                SObjectType sObjectType = SVMap.get(recordId).getSObjectType();
                system.debug(sObjectType);
                String shareObjectName;
                String parenId;
                String AccessLev;
                if (sObjectType.getDescribe().isCustom()) {
                    String objectApiName = String.valueOf(sObjectType);
                    shareObjectName = objectApiName.removeEndIgnoreCase('__c') + '__Share';
                } else {
                    shareObjectName = sObjectType + 'Share';
                    parenId = sObjectType +'Id';
                    AccessLev = sObjectType + 'AccessLevel';
                }
                Schema.SObjectType shareType = Schema.getGlobalDescribe().get(shareObjectName);
                system.debug(shareType);
                if (shareType != null) {
                    SObject shareRecord = shareType.newSObject();
                    if(sObjectType.getDescribe().isCustom()){
                        shareRecord.put('ParentId', SVMap.get(recordId));
                        shareRecord.put('UserOrGroupId', recordId);
                        shareRecord.put('AccessLevel', levelAccess);
                        shareRecord.put('RowCause', 'Manual');
                        shareRecords.add(shareRecord);
                    }
                    else{
                        if(shareObjectName == 'AccountShare'){
                            shareRecord.put('OpportunityAccessLevel', levelAccess); 
                        }
                        shareRecord.put(parenId, SVMap.get(recordId));
                        shareRecord.put('UserOrGroupId', recordId);
                        shareRecord.put(AccessLev, levelAccess);
                        shareRecord.put('RowCause', 'Manual');
                        shareRecords.add(shareRecord);
                    }
                } 
                else {
                    System.debug('Share object not found for ' + sObjectType);
                }
            }
            if(shareRecords.size()>0){
                List<Database.SaveResult> srList = Database.insert(shareRecords,false);
                for(Database.SaveResult sr : srList){
                    if(sr.isSuccess()){
                        system.debug('Lead Shared success');
                    }
                    else {
                        Database.Error err = sr.getErrors()[0];
                        system.debug('Error Message'+err.getMessage());
                        if(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  &&  
                           err.getMessage().contains('AccessLevel')){
                           }
                        else{
                        }
                    }
                }
            }
        }
    }
    
    public static void shareAnyRecordPreSales(List<Lead> leadList,String levelAccess) {
        
        Map<Id,Id> SVMap = new Map<Id,Id>();
        for(Lead ld : leadList){
            SVMap.put(ld.Pre_sales_user__c,ld.Id);
        }
        if(SVMap.size() >0){
            List<SObject> shareRecords = new List<SObject>();
            for(Id recordId :SVMap.keySet()){
                SObjectType sObjectType = SVMap.get(recordId).getSObjectType();
                system.debug(sObjectType);
                String shareObjectName;
                String parenId;
                String AccessLev;
                if (sObjectType.getDescribe().isCustom()) {
                    String objectApiName = String.valueOf(sObjectType);
                    shareObjectName = objectApiName.removeEndIgnoreCase('__c') + '__Share';
                } else {
                    shareObjectName = sObjectType + 'Share';
                    parenId = sObjectType +'Id';
                    AccessLev = sObjectType + 'AccessLevel';
                }
                Schema.SObjectType shareType = Schema.getGlobalDescribe().get(shareObjectName);
                system.debug(shareType);
                if (shareType != null) {
                    SObject shareRecord = shareType.newSObject();
                    if(sObjectType.getDescribe().isCustom()){
                        shareRecord.put('ParentId', SVMap.get(recordId));
                        shareRecord.put('UserOrGroupId', recordId);
                        shareRecord.put('AccessLevel', levelAccess);
                        shareRecord.put('RowCause', 'Manual');
                        shareRecords.add(shareRecord);
                    }
                    else{
                        if(shareObjectName == 'AccountShare'){
                            shareRecord.put('OpportunityAccessLevel', levelAccess); 
                        }
                        shareRecord.put(parenId, SVMap.get(recordId));
                        shareRecord.put('UserOrGroupId', recordId);
                        shareRecord.put(AccessLev, levelAccess);
                        shareRecord.put('RowCause', 'Manual');
                        shareRecords.add(shareRecord);
                    }
                } 
                else {
                    System.debug('Share object not found for ' + sObjectType);
                }
            }
            if(shareRecords.size()>0){
                List<Database.SaveResult> srList = Database.insert(shareRecords,false);
                for(Database.SaveResult sr : srList){
                    if(sr.isSuccess()){
                        system.debug('Lead Shared success');
                    }
                    else {
                        Database.Error err = sr.getErrors()[0];
                        system.debug('Error Message'+err.getMessage());
                        if(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  &&  
                           err.getMessage().contains('AccessLevel')){
                           }
                        else{
                        }
                    }
                }
            }
        }
    }
    
    //not using
    public static void checkShared(List<Lead> updateList){
        Map<Id, Id> leadToShare = new Map<Id, Id>();
        Set<Id> leadIdsToRevoke = new Set<Id>();
      
        for (Lead dl : updateList) {
            if (dl.Lead_OwnerSecondary__c != null) {
                leadToShare.put(dl.Lead_OwnerSecondary__c,dl.Id);
            } else {
                leadIdsToRevoke.add(dl.Id); 
            }
        }
        if(leadIdsToRevoke.size() >0){
            List<LeadShare> existingShares = [SELECT Id, LeadId, UserOrGroupId FROM LeadShare WHERE LeadId IN :leadToShare.keySet() and RowCause = 'Manual'];
            
            Map<Id, Set<Id>> leadToExistingShares = new Map<Id, Set<Id>>();
            for (LeadShare share : existingShares) {
                if (!leadToExistingShares.containsKey(share.LeadId)) {
                    leadToExistingShares.put(share.UserOrGroupId, new Set<Id>());
                }
                //leadToExistingShares.get(share.LeadId).add(share.UserOrGroupId);
            }
            
            for (Id leadId : leadIdsToRevoke) {
                if (leadToExistingShares.containsKey(leadId)) {
                    Set<Id> usersWithAccess = leadToExistingShares.get(leadId);
                    system.debug('Called revoke access');
                    revokeAccess(usersWithAccess);
                }
            }
            
        }
        if(leadToShare.size() > 0){
            system.debug('Called the share nay lead');
            //shareAnyRecord(leadToShare, 'Edit');
        }
        
    }
    
   /* public static void bookingsToShare(List<Booking__c> bookingsList){
        system.debug('shareAnyRecord breached ------- ');
        Map<Id,Id> SVMap = new Map<Id,Id>();
        for(Booking__c ld : bookingsList){
            if(ld.Sales_User__c != null){
                SVMap.put(ld.Sales_User__c,ld.Id);
            }
        }
        if(SVMap.size() >0){
            List<SObject> shareRecords = new List<SObject>();
            for(Id recordId :SVMap.keySet()){
                SObjectType sObjectType = SVMap.get(recordId).getSObjectType();
                system.debug(sObjectType);
                String shareObjectName;
                String parenId;
                String AccessLev;
                if (sObjectType.getDescribe().isCustom()) {
                    String objectApiName = String.valueOf(sObjectType);
                    shareObjectName = objectApiName.removeEndIgnoreCase('__c') + '__Share';
                } else {
                    shareObjectName = sObjectType + 'Share';
                    parenId = sObjectType +'Id';
                    AccessLev = sObjectType + 'AccessLevel';
                }
                Schema.SObjectType shareType = Schema.getGlobalDescribe().get(shareObjectName);
                system.debug(shareType);
                if (shareType != null) {
                    SObject shareRecord = shareType.newSObject();
                    if(sObjectType.getDescribe().isCustom()){
                        shareRecord.put('ParentId', SVMap.get(recordId));
                        shareRecord.put('UserOrGroupId', recordId);
                        shareRecord.put('AccessLevel', 'Read');
                        shareRecord.put('RowCause', 'Manual');
                        shareRecords.add(shareRecord);
                    }
                    else{
                        if(shareObjectName == 'AccountShare'){
                            shareRecord.put('OpportunityAccessLevel', 'Read'); 
                        }
                        shareRecord.put(parenId, SVMap.get(recordId));
                        shareRecord.put('UserOrGroupId', recordId);
                        shareRecord.put(AccessLev, 'Read');
                        shareRecord.put('RowCause', 'Manual');
                        shareRecords.add(shareRecord);
                    }
                } 
                else {
                    System.debug('Share object not found for ' + sObjectType);
                }
            }
            if(shareRecords.size()>0){
                system.debug('shareAnyRecord list greater than zero ------- ');
                List<Database.SaveResult> srList = Database.insert(shareRecords,false);
                system.debug('shareAnyRecord list greater than zero insert success------- ');
                for(Database.SaveResult sr : srList){
                    if(sr.isSuccess()){
                        system.debug('Lead Shared success');
                    }
                    else {
                        Database.Error err = sr.getErrors()[0];
                        system.debug('Error Message'+err.getMessage());
                        if(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  &&  
                           err.getMessage().contains('AccessLevel')){
                           }
                        else{
                        }
                    }
                }
            }
        }
    }*/
    
    
    @future
    public static void revokeAccess(Set<Id> ldId){
        List<LeadShare> sharesToDelete = [SELECT Id FROM LeadShare WHERE LeadId in: ldId and RowCause = 'Manual'];
        system.debug('Called revoke access lead share '+sharesToDelete);
        if (!sharesToDelete.isEmpty()) {
            delete sharesToDelete;
        }
    }
}