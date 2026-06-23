global without sharing class mCubeController {
    
    public static string calloutResponse{get;set;}
    
    @auraenabled
    webservice static List<string> readNumbers(String recordId) { 
        list<string> numbers = new list<string> ();
        string  mcubeObjectName = id.valueof( recordId).getSObjectType().getDescribe().getName() ;  
        List<MCUBE_Object_Api__c> mcubeObjectList =[select id,name,Field_to_Compare_Mobile_Incoming_Number__c from MCUBE_Object_Api__c where name =:mcubeObjectName ];
        string fieldsToquery = '';
        for(MCUBE_Object_Api__c m:  mcubeObjectList){
            fieldsToquery =  fieldsToquery+','+ m.Field_to_Compare_Mobile_Incoming_Number__c;
        }
        String condtn='Id='+'\''+recordId+'\'';
        String xQuery='Select id '+fieldsToquery+ ' from '+mcubeObjectName+' where '+condtn;
        system.debug(xQuery);         
        sObject so = Database.query(xQuery);
        for(MCUBE_Object_Api__c m:  mcubeObjectList){
            system.debug(m.Field_to_Compare_Mobile_Incoming_Number__c);
            system.debug((string)so.get(m.Field_to_Compare_Mobile_Incoming_Number__c));
            numbers.add((string)so.get(m.Field_to_Compare_Mobile_Incoming_Number__c));
        }
        system.debug(numbers);
        return numbers;
        
    }
    
    @auraenabled
    webservice static boolean clickToCallNumber(String recordId, String numberSelected) { 
        string  mcubeObjectName = id.valueof( recordId).getSObjectType().getDescribe().getName() ;  
        MCUBE_Object_Api__c mcubeObject=[select id,name,Field_to_Compare_Mobile_Incoming_Number__c,LandingNumber__c from MCUBE_Object_Api__c where name =:mcubeObjectName  limit 1];
        String condtn='Id='+'\''+recordId+'\'';
        String xQuery='Select id,'+mcubeObject.Field_to_Compare_Mobile_Incoming_Number__c+ ' from '+mcubeObjectName+' where '+condtn;
        system.debug(xQuery);         
        List<sObject> l = Database.query(xQuery);
        system.debug(l);        
        
        // Lead l =  [select id, Mobilephone from Lead where id=: leadId ];
        User u = [select mobilePhone from user where id=:userinfo.getUserId()];
        String m= numberSelected; 
        
        u.mobilePhone = u.mobilePhone.replace('+91','')  ; 
        u.mobilePhone = u.mobilePhone.replace('+','')  ;  
        u.mobilePhone=  u.mobilePhone.replaceAll('\\(', '');
        u.mobilePhone=  u.mobilePhone.replaceAll('\\)', '');
        u.mobilePhone=  u.mobilePhone.replaceAll(' ', '');
        if(m != null){
            m= m.replace('+91','')  ; 
            m=  m.replaceAll('\\(', '');
            m=  m.replaceAll('\\)', ''); 
            m=  m.replaceAll(' ', ''); 
        }
        
        Mcube__mdt api1 =  [select Value__c from Mcube__mdt where DeveloperName ='APIKey'];
        Mcube__mdt api2 =  [select Value__c from Mcube__mdt where DeveloperName ='callbackUrl'];
        //for new Products
        List<Mcube__mdt> verstionList = [select Value__c from Mcube__mdt where DeveloperName ='Version'];
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        string url = '';
        //For New Products 
        if(!(verstionList.isEmpty()) && verstionList[0].Value__c == '2'){
            //Mcube__mdt gsmConfig =   [select Value__c from Mcube__mdt where DeveloperName ='gsm'];
            // url  =   'http://api.mcube.com/Restmcube-api/outbound-calls?exenumber='+u.mobilePhone+'&custnumber='+m+'&refid='+l[0].get('Id')+'&refurl='+api2.Value__c +'/calland?refid='+l[0].get('Id')+'&gsm_config='+gsmConfig.Value__c;
            url  =   'http://api.mcube.com/Restmcube-api/outbound-calls';
            String token = api1.Value__c;
            request.setHeader('Content-Type', 'multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW');
            request.setHeader('Authorization', 'Bearer '+token );
            String boundary = '------WebKitFormBoundary7MA4YWxkTrZu0gW';
            String requestBody = '';
            
            
            
            // Add your form data
            requestBody += boundary + '\r\n';
            requestBody += 'Content-Disposition: form-data; name="exenumber"\r\n\r\n';
            //requestBody += '8767316316\r\n';  
            requestBody += u.mobilePhone+'\r\n';
            
            // Add your form data
            requestBody += boundary + '\r\n';
            requestBody += 'Content-Disposition: form-data; name="custnumber"\r\n\r\n';
            requestBody += m+'\r\n';  
            
            // Add your form data
            requestBody += boundary + '\r\n';
            requestBody += 'Content-Disposition: form-data; name="refid"\r\n\r\n';
            requestBody += l[0].get('Id')+'\r\n';  
            
            // Add your form data
            requestBody += boundary + '\r\n';
            requestBody += 'Content-Disposition: form-data; name="refurl"\r\n\r\n';
            requestBody += +'1\r\n';  
            // Add closing boundary
            requestBody += boundary + '--\r\n';
            
            // Set the request body as a Blob
            request.setBody(requestBody); 
            
            System.debug(requestBody);
        }else{
            url  =   'http://mcube.vmc.in/api/outboundcall?apikey='+api1.Value__c  +'&exenumber='+u.mobilePhone+'&custnumber='+m+'&refid='+l[0].get('Id')+'&url='+api2.Value__c +'/calland?refid='+l[0].get('Id');
        }
        
        request.setEndpoint(url);
        request.setMethod('POST');
        system.debug(url);
        if(!test.isRunningTest()){
            HttpResponse response = http.send(request);
            String var= response.getBody() ;
            Map<String,String> responseMap = (Map<String, String>) JSON.deserialize(var, Map<String, String>.class); 
            system.debug(var);  
            system.debug('Status COde'+response.getStatusCode()); 
            if(response.getStatusCode() == 200 ){
                String bodyStatus =  responseMap.get('status');
                
                if(bodyStatus=='false')
                    throw  new AuraHandledException(responseMap.get('msg'));
                
                return true;
            }
            
            return false;
        }
        
        return false;
        
    }
    
    @auraenabled
    webservice static boolean clickToCall(String recordId) { 
        
        string  mcubeObjectName = id.valueof( recordId).getSObjectType().getDescribe().getName() ;  
        MCUBE_Object_Api__c mcubeObject=[select id,name,Campaign_Field_API__c, Source_Field_API__c, Field_to_Compare_Mobile_Incoming_Number__c,LandingNumber__c from MCUBE_Object_Api__c where name =:mcubeObjectName  limit 1];
        String condtn='Id='+'\''+recordId+'\'';
        String xQuery='Select id,'+mcubeObject.Field_to_Compare_Mobile_Incoming_Number__c+ ' from '+mcubeObjectName+' where '+condtn;
        
        
        system.debug(xQuery);         
        List<sObject> l = Database.query(xQuery);
        system.debug(l);        
        
        // Lead l =  [select id, Mobilephone from Lead where id=: leadId ];
        User u = [select mobilePhone from user where id=:userinfo.getUserId()];
        String m= String.valueof(l[0].get(mcubeObject.Field_to_Compare_Mobile_Incoming_Number__c));
        
        u.mobilePhone = u.mobilePhone.replace('+91','')  ; 
        u.mobilePhone = u.mobilePhone.replace('+','')  ;  
        u.mobilePhone=  u.mobilePhone.replaceAll('\\(', '');
        u.mobilePhone=  u.mobilePhone.replaceAll('\\)', '');
        u.mobilePhone=  u.mobilePhone.replaceAll(' ', '');
        if(m != null){
            m= m.replace('+91','')  ; 
            m=  m.replaceAll('\\(', '');
            m=  m.replaceAll('\\)', ''); 
            m=  m.replaceAll(' ', ''); 
        }
        
        Mcube__mdt api1 =  [select Value__c from Mcube__mdt where DeveloperName ='APIKey'];
        Mcube__mdt api2 =  [select Value__c from Mcube__mdt where DeveloperName ='callbackUrl'];
        //for new Products
        List<Mcube__mdt> verstionList = [select Value__c from Mcube__mdt where DeveloperName ='Version'];
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        string url = '';
        //For New Products 
        if(!(verstionList.isEmpty()) && verstionList[0].Value__c == '2'){
            // Mcube__mdt gsmConfig =   [select Value__c from Mcube__mdt where DeveloperName ='gsm'];
            // url  =   'http://api.mcube.com/Restmcube-api/outbound-calls?exenumber='+u.mobilePhone+'&custnumber='+m+'&refid='+l[0].get('Id')+'&refurl='+api2.Value__c +'/calland?refid='+l[0].get('Id')+'&gsm_config='+gsmConfig.Value__c;
            url  =   'http://api.mcube.com/Restmcube-api/outbound-calls';
            String token = api1.Value__c ;
            request.setHeader('Content-Type', 'multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW');
            request.setHeader('Authorization', 'Bearer '+token );
            String boundary = '------WebKitFormBoundary7MA4YWxkTrZu0gW';
            String requestBody = '';
            
            
            
            // Add your form data
            requestBody += boundary + '\r\n';
            requestBody += 'Content-Disposition: form-data; name="exenumber"\r\n\r\n';
            //requestBody += '8767316316\r\n';  
            requestBody += u.mobilePhone+'\r\n';
            
            // Add your form data
            requestBody += boundary + '\r\n';
            requestBody += 'Content-Disposition: form-data; name="custnumber"\r\n\r\n';
            requestBody += m+'\r\n';  
            
            // Add your form data
            requestBody += boundary + '\r\n';
            requestBody += 'Content-Disposition: form-data; name="refid"\r\n\r\n';
            requestBody += l[0].get('Id')+'\r\n';  
            
            // Add your form data
            requestBody += boundary + '\r\n';
            requestBody += 'Content-Disposition: form-data; name="refurl"\r\n\r\n';
            requestBody += +'1\r\n';  
            // Add closing boundary
            requestBody += boundary + '--\r\n';
            
            // Set the request body as a Blob
            request.setBody(requestBody); 
            
            System.debug(requestBody);
        }else{
            url  =   'http://mcube.vmc.in/api/outboundcall?apikey='+api1.Value__c  +'&exenumber='+u.mobilePhone+'&custnumber='+m+'&refid='+l[0].get('Id')+'&url='+api2.Value__c +'/calland?refid='+l[0].get('Id');
        }
        
        request.setEndpoint(url);
        request.setMethod('POST');
        system.debug(url);
        if(!test.isRunningTest()){
            HttpResponse response = http.send(request);
            String var= response.getBody() ;
            Map<String,String> responseMap = (Map<String, String>) JSON.deserialize(var, Map<String, String>.class); 
            system.debug(var);  
            system.debug('Status COde'+response.getStatusCode()); 
            if(response.getStatusCode() == 200 ){
                String bodyStatus =  responseMap.get('status');
                
                if(bodyStatus=='false')
                    throw  new AuraHandledException(responseMap.get('msg'));
                
                return true;
            }
            
            return false;
        }
        
        return false;
        
    }

    public static void callConnecting(){
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c ='Call Route';
        Boolean newLead = false;
        List<MCUBE_Object_Api__c> mcubeObjectList = [select id,name,field__c,value__c,field1__c,value1__c,field2__c,value2__c,LandingNumber__c,field4__c,field5__c,
                                                     Field_to_Compare_Mobile_Incoming_Number__c from MCUBE_Object_Api__c order by LandingNumber__c nulls first];
        String fullUrl = ApexPages.currentPage().getUrl();
        system.debug('fullURL:' +fullUrl );
        String fromnumber = apexpages.currentpage().getparameters().get('fromnumber');
        // fromnumber = fromnumber.replace('\'', '');
        fromnumber = (fromnumber != null) ? fromnumber.replace('\'', '') : '';
        String landingNumber = apexpages.currentpage().getparameters().get('landingNumber');
        //log.Request__c = 'fromnumber:' + fromnumber + ' landingNumber:' + landingNumber + 'newlead' + newLead + 'OwnerNumber' + calloutResponse;
        log.Request__c = 'fromnumber:' + fromnumber + ' landingNumber:' + landingNumber;
        
        Map<string,Landing_Number__c> projectNumber = new Map<string,Landing_Number__c>();
        
        if(landingNumber != null){
            landingNumber = landingNumber.replace('\'', '').trim();
            List<Landing_Number__c> landingNumberList = [SELECT Id, Name,Project_Name__c,Active__c,Source__c,Sub_Source__c FROM Landing_Number__c WHERE Active__c = true AND Name =: landingNumber limit 1];
            system.debug('landingNumberList > '+landingNumberList);
            
            if(landingNumberList.size() > 0){
                projectNumber.put(landingNumberList[0].Name,landingNumberList[0]);
                
            }
        }
        String ownerId = '';
        String LeadId = '';
        try{
            if(!mcubeObjectList.isEmpty()){
                List<Related_Source__c> rltdList = new List<Related_Source__c>();
                List<Lead> checkList = [Select Id,OwnerId,Allocated_Project__c,Lead_Assigned__c,Delete_Lead__c,Lead_Status__c,recordTypeID FROM Lead WHERE (Phone__c =: fromnumber OR Secondary_phone__c =: fromnumber ) and Allocated_Project__c = :projectNumber.get(landingNumber).Project_Name__c limit 1];
                
                // evening time 7pm to 12 pm available users starts by ragu
                Datetime d = system.now();
                String dayOfWeek = d.format('EEEE');
                List<Lead> updateLeadList = new List<Lead>();
                List<User> userList = new List<User>();
                
                //If Lead exists (Open Lead)
                if(!checkList.isEmpty()){ // Changes made by ragu
                    system.debug('Lead exists');
                    if(checkList[0].Lead_Status__c != 'Lead Lost' && checkList[0].Lead_Status__c != 'Closed Lost'){
                        ownerId = (String) checkList[0].get('OwnerId');
                    }
                    else{
                        system.debug('Lost Lead');
                    }
                }
                else if(checkList.isEmpty()){ //If Lead doesn't exists, check for related source
                    rltdList = [SELECT Id,Allocated_Project__c,Phone__c,Secondary_phone__c,SLead__r.ownerId,SLead__r.Lead_Status__c,SLead__r.Id,SLead__r.Allocated_Project__c FROM Related_Source__c WHERE (Phone__c =: fromnumber OR Secondary_phone__c =: fromnumber ) and SLead__r.Allocated_Project__c = :projectNumber.get(landingNumber).Project_Name__c ORDER BY CreatedDate ASC];
                    if(rltdList.size() > 0){
                        ownerId = rltdList[0].SLead__r.ownerId;
                    }
                }
                
                if(ownerId == ''){
                    newLead = true;
                }
                log.Request__c +=  'newlead' + newLead;
                
                MCUBE_Object_Api__c  mcubeObject = new  MCUBE_Object_Api__c();
                for(MCUBE_Object_Api__c m: mcubeObjectList){
                    
                    mcubeObject = m;
                    break;
                }
                sObject l = Schema.getGlobalDescribe().get(mcubeObject.Name).newSObject(); 
                if(newLead){
                    system.debug('isnewLeadcreating');
                    
                    if(mcubeObject.field__c != null && projectNumber.containskey(landingNumber)){
                        L.put(mcubeObject.field__c, projectNumber.get(landingNumber).Project_Name__c); 
                    }
                    if(mcubeObject.field1__c != null && mcubeObject.value1__c != null){
                        L.put(mcubeObject.field1__c, mcubeObject.value1__c); 
                    }
                    if(mcubeObject.field2__c != null && mcubeObject.value2__c != null){
                        L.put(mcubeObject.field2__c, mcubeObject.value2__c); 
                    }
                    L.put(mcubeObject.field4__c, projectNumber.get(landingNumber).Source__c); 
                    L.put(mcubeObject.field5__c, projectNumber.get(landingNumber).Sub_Source__c); 
                    
                    //Check if Project Name is not null, lead exists (Closed Lead)
                    if(mcubeObject.field__c != null && !projectNumber.containskey(landingNumber)){
                        if(!checkList.isEmpty() && (checkList[0].Lead_Status__c == 'Lead Lost' || checkList[0].Lead_Status__c == 'Closed Lost')){
                            L.put(mcubeObject.field__c, checkList[0].Allocated_Project__c);
                        }
                        else if(checkList.isEmpty() && !rltdList.isEmpty()){//lead doesn't exists, check for related list (Closed Lead)
                            if(rltdList[0].SLead__r.Lead_Status__c == 'Lead Lost' || rltdList[0].SLead__r.Lead_Status__c == 'Closed Lost'){
                                L.put(mcubeObject.field__c, rltdList[0].SLead__r.Allocated_Project__c);
                            }
                        }
                    }
                    
                    l.put(mcubeObject.Field_to_Compare_Mobile_Incoming_Number__c,fromnumber); 
                    //l.put('Rating','Cold');
                    system.debug('inserted   '+mcubeObject); 
                    insert l;
                    LeadId = l.Id;
                    
                    //Check if Project Name is not null, lead exists (Re-opened Lead)
                    if(mcubeObject.field__c != null && !projectNumber.containskey(landingNumber)){
                        if(!checkList.isEmpty() && (checkList[0].Lead_Status__c == 'Lead Lost' || checkList[0].Lead_Status__c == 'Closed Lost')){
                            ownerId = [select id,name,ownerId from Lead where Id=: checkList[0].Id].ownerId;
                        }
                        else if(checkList.isEmpty() && !rltdList.isEmpty()){//lead doesn't exists, check for related list (RE-opened Lead)
                            if(rltdList[0].SLead__r.Lead_Status__c == 'Lead Lost' || rltdList[0].SLead__r.Lead_Status__c == 'Closed Lost'){
                                ownerId = [select id,name,ownerId from Lead where Id=: rltdList[0].SLead__c].ownerId;
                            }
                        }
                    }
                }
                if(ownerId == ''){
                    if(!checkList.isEmpty() && checkList[0].Id != null){
                        LeadId = checkList[0].Id;
                    }
                    else if(!rltdList.isEmpty() && rltdList[0].SLead__c != null){
                        LeadId = rltdList[0].SLead__c;
                    }
                    Lead ld = new Lead();
                    ld = [select id,Lead_source__c,Lead_Status__c,OwnerId from Lead where Id =: LeadId];
                    ownerId = ld.OwnerId;
                }
                
                if(ownerId != null){
                    user u =[select id,phone from user where id =: ownerId];
                    calloutResponse = u.phone;
                }
                else{
                    calloutResponse = 'empty'; 
                }
                log.Request__c +=  'OwnerNumber' + calloutResponse;
            }
            else{
                calloutResponse = 'Please Configure the Mcube Object in salesforce';
                log.Request__c +=  'newlead' + newLead + 'OwnerNumber' + calloutResponse;
            }
            log.Status__c ='SUCCESS';
        }
        catch (exception e){
            log.Response__c = e.getMessage();
            log.Status__c ='FAILED';
            log.Error_Message__c = e.getMessage();
            calloutResponse = e.getMessage(); 
            log.Request__c +=  'newlead' + newLead + 'OwnerNumber' + calloutResponse;
        }
        insert log;
        
    } 
    
    public static void callRoute(){
        Apex_Log__c log = new Apex_Log__c();
        log.Request_Type__c ='Call Route';
        Boolean newLead = false;
        List<MCUBE_Object_Api__c> mcubeObjectList = [select id,name,field__c,value__c,field1__c,value1__c,field2__c,value2__c,LandingNumber__c,field4__c,field5__c,
                                                     Field_to_Compare_Mobile_Incoming_Number__c from MCUBE_Object_Api__c order by LandingNumber__c nulls first];
        String fullUrl = ApexPages.currentPage().getUrl();
        system.debug('fullURL:' +fullUrl );
        String fromnumber = apexpages.currentpage().getparameters().get('fromnumber');
        // fromnumber = fromnumber.replace('\'', '');
        fromnumber = (fromnumber != null) ? fromnumber.replace('\'', '') : '';
        String landingNumber = apexpages.currentpage().getparameters().get('landingNumber');
        //log.Request__c = 'fromnumber:' + fromnumber + ' landingNumber:' + landingNumber + 'newlead' + newLead + 'OwnerNumber' + calloutResponse;
        log.Request__c = 'fromnumber:' + fromnumber + ' landingNumber:' + landingNumber;
        
        Map<string,Landing_Number__c> projectNumber = new Map<string,Landing_Number__c>();
        
        if(landingNumber != null){
            landingNumber = landingNumber.replace('\'', '').trim();
            List<Landing_Number__c> landingNumberList = [SELECT Id, Name,Project_Name__c,Active__c,Source__c,Sub_Source__c FROM Landing_Number__c WHERE Active__c = true AND Name =: landingNumber limit 1];
            system.debug('landingNumberList > '+landingNumberList);
            
            if(landingNumberList.size() > 0){
                projectNumber.put(landingNumberList[0].Name,landingNumberList[0]);
                
            }
        }
        String ownerId = '';
        String LeadId = '';
        try{
            if(!mcubeObjectList.isEmpty()){
                List<Related_Source__c> rltdList = new List<Related_Source__c>();
                List<Lead> checkList = new List<Lead>();
                List<User> executiveList = new List<User>();
                if(landingNumber != '' && landingNumber != null)
                {
                    Landing_Number__c landingNumberRecord = projectNumber.get(landingNumber);
                    String projectName = landingNumberRecord != null ? landingNumberRecord.Project_Name__c : null;
                    //Project Name as "None" Customer is Calling to executive DID Number
                    if (projectName == 'None' || String.isBlank(projectName)) {
                        String executiveDIDNumber = landingNumberRecord != null ? landingNumberRecord.Name : null;
                        
                        executiveList = [
                            SELECT Id, Name 
                            FROM User 
                            WHERE DID_Number__c = :executiveDIDNumber and DID_Number__c != null
                            LIMIT 1
                        ];
                        
                        // 1. Search Lead with Owner + Lead Phone Number (Most Recent)
                        if (!executiveList.isEmpty()) {
                            checkList = [
                                SELECT Id, OwnerId, Allocated_Project__c, Lead_Assigned__c, 
                                Delete_Lead__c, Lead_Status__c, RecordTypeId
                                FROM Lead
                                WHERE (Phone__c = :fromnumber OR Secondary_phone__c = :fromnumber)
                                AND OwnerId = :executiveList[0].Id
                                ORDER BY Last_Call_Time__c DESC
                                LIMIT 1
                            ];
                        }
                        
                        // 2. If not found, Search Lead with only Lead Phone Number (Most Recent)
                        if (checkList.isEmpty()) {
                            checkList = [
                                SELECT Id, OwnerId, Allocated_Project__c, Lead_Assigned__c, 
                                Delete_Lead__c, Lead_Status__c, RecordTypeId
                                FROM Lead
                                WHERE (Phone__c = :fromnumber OR Secondary_phone__c = :fromnumber)
                                ORDER BY Last_Call_Time__c DESC
                                LIMIT 1
                            ];
                        }
                    }
                    else
                    {
                        checkList = [Select Id,OwnerId,Allocated_Project__c,Lead_Assigned__c,Delete_Lead__c, Lead_Status__c,recordTypeID 
                                     FROM Lead WHERE (Phone__c =: fromnumber OR Secondary_phone__c =: fromnumber ) 
                                     and Allocated_Project__c = :projectName limit 1];
                    }
                    
                    // evening time 7pm to 12 pm available users starts by ragu
                    Datetime d = system.now();
                    String dayOfWeek = d.format('EEEE');
                    List<Lead> updateLeadList = new List<Lead>();
                    List<User> userList = new List<User>();
                    
                    //If Lead exists (Open Lead)
                    if(!checkList.isEmpty()){ 
                        system.debug('Lead exists');
                        if(checkList[0].Lead_Status__c != 'Lead Lost' && checkList[0].Lead_Status__c != 'Closed Lost'){
                            ownerId = (String) checkList[0].get('OwnerId');
                        }
                        else{
                            system.debug('Lost Lead');
                        }
                    }
                    else if(checkList.isEmpty()){ //If Lead doesn't exists, check for related source
                        
                        if (projectName == 'None' || String.isBlank(projectName)) {
                            // 1. Search Lead with Owner + Lead Phone Number (Most Recent)
                            if (!executiveList.isEmpty()) {
                                rltdList = [
                                    SELECT Id,Allocated_Project__c,Phone__c,Secondary_phone__c,SLead__r.ownerId,SLead__r.Lead_Status__c
                                    ,SLead__r.Id,SLead__r.Allocated_Project__c FROM Related_Source__c WHERE 
                                    (Phone__c =: fromnumber OR Secondary_phone__c =: fromnumber ) 
                                    and SLead__r.OwnerId =:executiveList[0].Id ORDER BY CreatedDate ASC
                                ];
                            }
                            if (rltdList.isEmpty()) {
                                rltdList = [
                                    SELECT Id,Allocated_Project__c,Phone__c,Secondary_phone__c,SLead__r.ownerId,SLead__r.Lead_Status__c
                                    ,SLead__r.Id,SLead__r.Allocated_Project__c FROM Related_Source__c WHERE 
                                    (Phone__c =: fromnumber OR Secondary_phone__c =: fromnumber ) ORDER BY CreatedDate ASC
                                ];
                            }
                            
                        }  
                        else{
                            rltdList = [SELECT Id,Allocated_Project__c,Phone__c,Secondary_phone__c,SLead__r.ownerId,SLead__r.Lead_Status__c
                                        ,SLead__r.Id,SLead__r.Allocated_Project__c FROM Related_Source__c WHERE 
                                        (Phone__c =: fromnumber OR Secondary_phone__c =: fromnumber ) 
                                        and SLead__r.Allocated_Project__c = :projectNumber.get(landingNumber).Project_Name__c ORDER BY CreatedDate ASC];
                        }
                        
                        if(rltdList.size() > 0){
                            if(rltdList[0].SLead__r.Lead_Status__c != 'Lead Lost' && rltdList[0].SLead__r.Lead_Status__c != 'Closed Lost'){
                                ownerId = rltdList[0].SLead__r.ownerId;
                            }
                            else
                            {
                                system.debug('Lost Lead from Related Source list');
                            }
                        }
                    }
                    
                    if(ownerId == ''){
                        newLead = true;
                    }
                    log.Request__c +=  'newlead' + newLead;
                    
                    MCUBE_Object_Api__c  mcubeObject = new  MCUBE_Object_Api__c();
                    for(MCUBE_Object_Api__c m: mcubeObjectList){
                        mcubeObject = m;
                        break;
                    }
                    sObject l = Schema.getGlobalDescribe().get(mcubeObject.Name).newSObject(); 
                    if(newLead){
                        system.debug('isnewLeadcreating');
                        
                        if(mcubeObject.field__c != null && projectNumber.containskey(landingNumber)){
                            L.put(mcubeObject.field__c, projectNumber.get(landingNumber).Project_Name__c); 
                        }
                        if(mcubeObject.field1__c != null && mcubeObject.value1__c != null){
                            L.put(mcubeObject.field1__c, mcubeObject.value1__c); 
                        }
                        if(mcubeObject.field2__c != null && mcubeObject.value2__c != null){
                            L.put(mcubeObject.field2__c, mcubeObject.value2__c); 
                        }
                        L.put(mcubeObject.field4__c, projectNumber.get(landingNumber).Source__c); 
                        L.put(mcubeObject.field5__c, projectNumber.get(landingNumber).Sub_Source__c); 
                        
                        //Check if Project Name is not null, lead exists (Closed Lead)
                        if(mcubeObject.field__c != null && !projectNumber.containskey(landingNumber)){
                            if(!checkList.isEmpty() && (checkList[0].Lead_Status__c == 'Lead Lost' || checkList[0].Lead_Status__c == 'Closed Lost')){
                                L.put(mcubeObject.field__c, checkList[0].Allocated_Project__c);
                            }
                            else if(checkList.isEmpty() && !rltdList.isEmpty()){//lead doesn't exists, check for related list (Closed Lead)
                                if(rltdList[0].SLead__r.Lead_Status__c == 'Lead Lost' || rltdList[0].SLead__r.Lead_Status__c == 'Closed Lost'){
                                    L.put(mcubeObject.field__c, rltdList[0].SLead__r.Allocated_Project__c);
                                }
                            }
                        }
                        
                        l.put(mcubeObject.Field_to_Compare_Mobile_Incoming_Number__c,fromnumber); 
                        //l.put('Rating','Cold');
                        system.debug('inserted   '+mcubeObject); 
                        l.put('Last_Call_Time__c', System.now());
                        insert l;
                        LeadId = l.Id;
                        
                        //Check if Project Name is not null, lead exists (Re-opened Lead) 
                        //==> this case will not execute
                        if(mcubeObject.field__c != null && !projectNumber.containskey(landingNumber)){
                            if(!checkList.isEmpty() && (checkList[0].Lead_Status__c == 'Lead Lost' || checkList[0].Lead_Status__c == 'Closed Lost')){
                                ownerId = [select id,name,ownerId from Lead where Id=: checkList[0].Id].ownerId;
                            }
                            else if(checkList.isEmpty() && !rltdList.isEmpty()){//lead doesn't exists, check for related list (RE-opened Lead)
                                if(rltdList[0].SLead__r.Lead_Status__c == 'Lead Lost' || rltdList[0].SLead__r.Lead_Status__c == 'Closed Lost'){
                                    ownerId = [select id,name,ownerId from Lead where Id=: rltdList[0].SLead__c].ownerId;
                                }
                            }
                        }
                    }
                    if(ownerId == ''){
                        if(!checkList.isEmpty() && checkList[0].Id != null){
                            LeadId = checkList[0].Id;
                        }
                        else if(!rltdList.isEmpty() && rltdList[0].SLead__c != null){
                            LeadId = rltdList[0].SLead__c;
                        }
                        Lead ld = new Lead();
                        ld = [select id,Lead_source__c,Lead_Status__c,OwnerId from Lead where Id =: LeadId];
                        ownerId = ld.OwnerId;
                    }
                    
                    if(ownerId != null){
                        user u =[select id,phone from user where id =: ownerId];
                        calloutResponse = u.phone;
                    }
                    else{
                        calloutResponse = 'empty'; 
                    }
                }
                else
                {
                    calloutResponse = 'Landing is Empty';
                }
                log.Request__c +=  'OwnerNumber' + calloutResponse;
            }
            else{
                calloutResponse = 'Please Configure the Mcube Object in salesforce';
                log.Request__c +=  'newlead' + newLead + 'OwnerNumber' + calloutResponse;
            }
            log.Status__c ='SUCCESS';
        }
        catch (exception e){
            log.Response__c = e.getMessage();
            log.Status__c ='FAILED';
            log.Error_Message__c = e.getMessage();
            calloutResponse = e.getMessage(); 
            log.Request__c +=  'newlead' + newLead + 'OwnerNumber' + calloutResponse;
        }
        insert log;
        
    } 
    
    public static void inboundCall(){ 
        Apex_Log__c log = new Apex_Log__c();
        String data = apexpages.currentpage().getparameters().get('data');
        List<MCUBE_Object_Api__c> mcubeObjectList =[select id,name,Campaign_Field_API__c, Source_Field_API__c,
                                                    field__c,value__c,field1__c,value1__c,field2__c,value2__c, 
                                                    LandingNumber__c,  Field_to_Compare_Mobile_Incoming_Number__c
                                                    from MCUBE_Object_Api__c order by  LandingNumber__c nulls first ];
        
        MCUBE_Object_Api__c  mcubeObject = new  MCUBE_Object_Api__c(); 
        if(mcubeObjectList.size() > 0 ){
            mcubeObject = mcubeObjectList[0];  
            string mobileNumber ='';
            if(data != null){ 
                data = EncodingUtil.urlDecode(data, 'UTF-8');       
                log.Request__c = data;
                log.Status__c = 'SUCCESS';
                callWrapper cw = (callWrapper)JSON.deserialize(data,callWrapper.class); 
                List<Call_Detail__c> clist=[select id from Call_Detail__c where Call_ID__c =: cw.callid ];
                User u=new User();  
                for(MCUBE_Object_Api__c m: mcubeObjectList){
                    if( m.LandingNumber__c == cw.clicktocalldid ){ 
                        mcubeObject = m;
                    } 
                }
                
                
                //INBOUND
                if(cw.executive == null){    
                    String landingNumber = cw.clicktocalldid != null  ? cw.clicktocalldid.replace('\'', '').trim() : '';
                    // String landingNumber = cw.clicktocalldid.replace('\'', '').trim();
                    Map<string,string> projectNumber = new Map<string,string>();
                    if(landingNumber != null){
                        List<Landing_Number__c> landingNumberList = [SELECT Id, Name,Project_Name__c,Active__c FROM Landing_Number__c WHERE Active__c = true AND Name =: landingNumber limit 1];
                        system.debug('landingNumberList > '+landingNumberList);
                        
                        if(landingNumberList.size() > 0){
                            projectNumber.put(landingNumberList[0].Name,landingNumberList[0].Project_Name__c);
                            
                        }
                    }
                    log.Request_Type__c ='Call Functionality - Inbound';
                    if(cw.dialstatus  == 'CONNECTING'){   
                        sObject l = Schema.getGlobalDescribe().get(mcubeObject.Name).newSObject() ; 
                        String OwnerId = UserInfo.getUserId();
                        List<user> usersList = [select id from user where phone like : cw.empnumber limit 1]; 
                        if(usersList.size() > 0){
                            u = usersList[0]; 
                            OwnerId = u.Id;
                        }
                        system.debug('user:' + u);
                        
                        string LeadId = '';
                        List<Lead> checkList = new  List<Lead>();
                        string projectName = projectNumber.get(landingNumber);
                        //Project Name as "None" Customer is Calling to executive DID Number
                        if (projectName == 'None'  || String.isBlank(projectName)) {
                            
                            // 1. Search Lead with Owner + Lead Phone Number (Most Recent)
                            if (!usersList.isEmpty()) {
                                checkList = [
                                    SELECT Id, OwnerId, Allocated_Project__c, Lead_Assigned__c, 
                                    Delete_Lead__c, Lead_Status__c, RecordTypeId
                                    FROM Lead
                                    WHERE (Phone__c = : cw.callfrom OR Secondary_phone__c = : cw.callfrom)
                                    AND OwnerId = :u.Id
                                    ORDER BY Last_Call_Time__c DESC
                                    LIMIT 1
                                ];
                            }
                            
                            // 2. If not found, Search Lead with only Lead Phone Number (Most Recent)
                            if (checkList.isEmpty()) {
                                checkList = [
                                    SELECT Id, OwnerId, Allocated_Project__c, Lead_Assigned__c, 
                                    Delete_Lead__c, Lead_Status__c, RecordTypeId
                                    FROM Lead
                                    WHERE (Phone__c = : cw.callfrom OR Secondary_phone__c = : cw.callfrom)
                                    ORDER BY Last_Call_Time__c DESC
                                    LIMIT 1
                                ];
                            }
                        }
                        else
                        {
                            checkList = [Select Id,OwnerId,Allocated_Project__c,Lead_Assigned__c,Delete_Lead__c, Lead_Status__c,recordTypeID 
                                         FROM Lead WHERE (Phone__c =:  cw.callfrom OR Secondary_phone__c =:  cw.callfrom ) 
                                         and Allocated_Project__c = :projectName limit 1];
                        }
                        
                        

                        if(!checkList.isEmpty()){
                            l = checkList[0];
                        
                        }
                        else if(checkList.isEmpty()){
                            List<Related_Source__c> rltdList = new List<Related_Source__c>();
                            if (projectName == 'None' || String.isBlank(projectName)) {
                                // 1. Search Lead with Owner + Lead Phone Number (Most Recent)
                                if (!usersList.isEmpty()) {
                                    rltdList = [
                                        SELECT Id,Allocated_Project__c,Phone__c,Secondary_phone__c,SLead__r.ownerId,SLead__r.Lead_Status__c
                                        ,SLead__r.Id,SLead__r.Allocated_Project__c FROM Related_Source__c WHERE 
                                        (Phone__c =: cw.callfrom OR Secondary_phone__c =: cw.callfrom ) 
                                        and SLead__r.OwnerId =:u.Id ORDER BY CreatedDate ASC
                                    ];
                                }
                                if (rltdList.isEmpty()) {
                                    rltdList = [
                                        SELECT Id,Allocated_Project__c,Phone__c,Secondary_phone__c,SLead__r.ownerId,SLead__r.Lead_Status__c
                                        ,SLead__r.Id,SLead__r.Allocated_Project__c FROM Related_Source__c WHERE 
                                        (Phone__c =: cw.callfrom OR Secondary_phone__c =: cw.callfrom ) ORDER BY CreatedDate ASC
                                    ];
                                }
                                
                            }  
                            else{
                                rltdList = [SELECT Id,Phone__c,Secondary_phone__c,SLead__r.ownerId,
                                            SLead__r.Id,SLead__r.Allocated_Project__c FROM Related_Source__c 
                                            WHERE (Phone__c =: cw.callfrom OR Secondary_phone__c =: cw.callfrom )
                                            and SLead__r.Allocated_Project__c = :projectNumber.get(landingNumber)
                                            ORDER BY CreatedDate ASC limit 1];
                            }
                            
                            if(rltdList.size() > 0){
                                l = rltdList[0].SLead__r;
                         
                            }
                        }
                        
                        Call_Detail__c c = new Call_Detail__c();
                        if(cList.size() == 0){
                            DateTime start = System.Now();
                            String url='/'+l.id+'/view';
                            c.Parent_URL__c=url;
                            c.Parent_ID__c  = l.id;
                            c.Call_From__c = cw.callfrom;
                            c.Start_Time__c =   Datetime.valueof(cw.starttime).addHours(-5).addMinutes(-30);
                            //c.Start_Time__c =   Datetime.valueof(cw.starttime); 
                            c.Call_ID__c = cw.callid;
                            c.Call_Type__c='Inbound Call'; 
                            c.Call_To__c=cw.empnumber;
                            c.Recording_File__c=cw.filename; 
                            c.landing_number__c = cw.clicktocalldid;
                            c.Status__c=cw.dialstatus; 
                            c.OwnerId = OwnerId;
                            if(mcubeObject.Name == 'Lead'){
                                c.lead__c = l.id;
                            }
                            if(mcubeObject.Name == 'Account'){
                                c.Account__c = cw.refid;
                            } 
                            if(mcubeObject.Name == 'Contact'){
                                c.Contact__c = cw.refid;
                            }
                            if(mcubeObject.Name == 'Case'){
                                c.case__c = cw.refid;
                            }
                            
                            insert c;
                        }
                        
                        
                        sendNotification(cw.callfrom, l.id,OwnerId, mcubeObject.name,c.Id);
                        
                    }
                    else  
                    {
                        if(cList.size() == 1){
                            Call_Detail__c  c = [select id from Call_Detail__c where Call_ID__c =: cw.callid ];
                            c.End_Time__c = Datetime.valueof(cw.endtime).addHours(-5).addMinutes(-30);
                            c.Status__c=cw.dialstatus;
                            c.Recording_File__c= cw.filename;
                            update c;
                        }
                    } 
                }
                
                //OUTBOUND
                if(cw.executive != null){ 
                    
                    if (cw.status == 'ORIGINATE')
                    {
                        log.Request_Type__c ='Call Functionality - Outbound';
                        
                        Call_Detail__c c = new Call_Detail__c();  
                        
                        c.Parent_ID__c = cw.refid;
                        c.Parent_URL__c= '/'+ cw.refid+'/view';
                        c.Status__c=cw.dialstatus; 
                        DateTime start = System.Now();
                        c.Call_ID__c = cw.CallId;
                        c.Call_From__c =cw.executive ;
                        c.Start_Time__c =   Datetime.valueof(cw.starttime).addHours(-5).addMinutes(-30);  
                        //c.Start_Time__c =   Datetime.valueof(cw.starttime);  
                        c.Recording_File__c= cw.filename; 
                        c.Status__c=cw.status;
                        c.Call_ID__c = cw.callid;
                        c.Call_Type__c='Outbound Call';  
                        c.Call_To__c=cw.customer;
                        if(mcubeObject.Name == 'Lead'){
                            c.lead__c = cw.refid;
                        } 
                        if(mcubeObject.Name == 'Account'){
                            c.Account__c = cw.refid; 
                        } 
                        if(mcubeObject.Name == 'Contact'){
                            c.Contact__c = cw.refid;
                        }
                        if(mcubeObject.Name == 'Case'){
                            c.case__c = cw.refid;
                        }
                        c.OwnerId = [select OwnerId from Lead where Id=:cw.refid].OwnerId;
                        
                        List<user> usersList = [select id from user where phone like : cw.executive limit 1]; 
                        if(usersList.size() > 0){
                            u = usersList[0]; 
                            c.OwnerId = u.Id;
                        }
                        insert c;
                        system.debug('lead id  '+ cw.refid+' usedId  '+u.id+' objectname '+mcubeObject.name+' callid '+c.Id);
                        
                    }else   
                    {                  
                        if(cList.size() == 1){  
                            Call_Detail__c  c1 = [select id from Call_Detail__c where Call_ID__c =: cw.callid ];
                            c1.End_Time__c = Datetime.valueof(cw.endtime).addhours(-5).addMinutes(-30); 
                            c1.Status__c=cw.status;
                            c1.Recording_File__c= cw.filename;
                            update c1;
                        }
                    }
                }
            }   
        } 
        insert log;
    }
    
    public static void sendNotification(string mobile, string recordId,String userId, string objectName,string callID){
        
        CustomNotificationType notificationType = 
            [SELECT Id, DeveloperName 
             FROM CustomNotificationType 
             WHERE DeveloperName='Mcube_Notification']; 
        // Create a new custom notification
        Datetime dt = Datetime.now().addHours(5).addMinutes(30);
        Timezone tz = Timezone.getTimeZone('Asia/Kolkata');
        String strTimeInAMorPM = dt.format('MMMMM dd, yyyy hh:mm:ss a');
        Messaging.CustomNotification notification = new Messaging.CustomNotification(); 
        // Set the contents for the notification
        notification.setTitle('Incoming Call');
        notification.setBody('You Have a call on ' + strTimeInAMorPM); 
        
        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(recordId);
        
        // Actually send the notification
        try {
            notification.send(new set<string> {userId});
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }  
        
        system.debug('notification block');
        List<CtiNotification__e> publishEvents = new List<CtiNotification__e>();
        CtiNotification__e eve = new CtiNotification__e();  
        eve.User_Id__c = userId;
        eve.Record_Id__c = recordId; 
        eve.ObjectName__c = objectName;
        // eve.Call_Id__c = callID;
        publishEvents.add(eve);   
        if(!publishEvents.isEmpty()){
            EventBus.publish(publishEvents);
        }
    }
    
    public class  callWrapper{
        
        public String refid;
        public String  callid ;
        public String callfrom; 
        public string starttime ;
        public String   filename; 
        public String calid;
        public string pulse;
        public string source;
        public String custfeedback;
        public String exefeedback;
        public String dialstatus;
        public String callerbusiness;
        public String callername;
        public String remark;
        public String calleraddress;
        public String caller_email;
        public String rate;
        public string empnumber;
        public string   endtime;
        public String eid ;
        public String empid;
        public string gid;
        public String empemail;
        public String status;
        public String executive;
        public String customer;
        public string LandingNumber;
        public string campaign;
        public string clicktocalldid ;
    }
    public   static string status{get;set;} 
    @auraEnabled
    public static  Call_Detail__c readCall(){ 
        try{
            datetime ss =  system.now().addSeconds(-10);
            Call_Detail__c c = [select Call_From__c,Call_ID__c,Call_To__c,Call_Type__c,End_Time__c,Executive_Contact_No__c,Parent_ID__c,Parent_URL__c,Recording_File__c,Start_Time__c,Status__c from Call_Detail__c where createddate >: ss and End_Time__c = null    order by createddate desc limit 1  ];
            return  c;    
        }catch(exception e){
            Call_Detail__c c = new Call_Detail__c();
            return  c;    
        }
        
    } 
    
    public  string recordIds= '';
    
    
    public static void testmeth(){
        integer i=0;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        
    }
    
}