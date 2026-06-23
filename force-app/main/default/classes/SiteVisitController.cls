public without sharing class SiteVisitController {
    
    public static void checkSiteVisitForRoundRobin(List<Site_Visit__c> svList){
        
        Set<Id> leadIds = new Set<Id>();
        for(Site_Visit__c sv : svList){
            leadIds.add(sv.SLead__c);
        }
        system.debug('Lead Ids'+leadIds);
        List<Lead> leadList = [Select Id,Name,RecordType.Name,Allocated_Project__c,Source_Type__c From Lead Where Id in: leadIds ];
        Map<Id,Lead> leadMapIdToRecordType = new Map<Id,Lead>();
        for(Lead ld : leadList){
            leadMapIdToRecordType.put(ld.Id,ld);
        }
        system.debug('Lead Map'+leadMapIdToRecordType);
        
        
        for(Site_Visit__c sv : svList){
           // if(leadMapIdToRecordType.get(sv.SLead__c).RecordType.Name == 'Pre Sales'){
                system.debug('SV In Loop');
            
                sv.Go_For_Round_Robin__c = true;
            if(sv.OTP__c!='0000'){
                sv.OTP__c = GenerateOTP.generateUniqueOTP();
            }
                if(sv.Source_Type__c == null){
                    sv.Source_Type__c = leadMapIdToRecordType.get(sv.SLead__c).Source_Type__c;
                }
            //}
        }
    }

}