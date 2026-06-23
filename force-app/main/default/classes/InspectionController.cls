public with sharing class InspectionController{
    @AuraEnabled
    public static String saveInspectionWithSnags(String bookingId, Date inspectionDate, String inspectionDescription, String snagListJson) 
    {
        try {
            // Validate Booking exists
            if (String.isBlank(bookingId)) {
                throw new AuraHandledException('Booking ID is required');
            }
            // Verify booking exists
            List<Booking__c> bookings = [SELECT Id, Project1__c,Block_Id__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
            if (bookings.isEmpty()) {
                throw new AuraHandledException('Booking not found');
            }
            
            list<Block__c> blockList = [SELECT Id, Inspection_Executive__c,Inspection_Executive__r.ManagerId FROM Block__c WHERE Id = :bookings[0].Block_Id__c];
            Block__c block = blockList[0];
            
            // Create Inspection record
            Inspection__c inspection = new Inspection__c();
            inspection.Booking__c = bookingId;
            inspection.Inspection_Date__c = inspectionDate;
            inspection.Description__c = inspectionDescription;
            inspection.OwnerId = block.Inspection_Executive__c;
            inspection.Approver__c = block.Inspection_Executive__c != null  ? block.Inspection_Executive__r.ManagerId  : null;
            insert inspection;
            
            System.debug('Inspection created with ID: ' + inspection.Id);
            
            // Parse snag list JSON
            List<Object> snagDataList = (List<Object>) JSON.deserializeUntyped(snagListJson);
            List<String> snagIds = new List<String>();
            
            // Create Snag List records
            if (snagDataList != null && !snagDataList.isEmpty()) {
                List<Snag_List__c> snags = new List<Snag_List__c>();
                
                for (Integer i = 0; i < snagDataList.size(); i++) {
                    Map<String, Object> snagData = (Map<String, Object>) snagDataList[i];
                    
                    Snag_List__c snag = new Snag_List__c();
                    snag.Inspection__c = inspection.Id;
                    snag.Description__c = (String) snagData.get('Description__c');
                    snag.Status__c     = (String) snagData.get('Status__c');
                    snag.Priority__c   = (String) snagData.get('Priority__c');
                    snag.Inspection_Type__c = (String) snagData.get('Inspection_Type__c');
                    snags.add(snag);
                }
                
                insert snags;
                System.debug('Created ' + snags.size() + ' snag records');
                
                for (Snag_List__c snag : snags) {
                    snagIds.add(snag.Id);
                }
            }
            
            Inspection__c inspectionRecord = [select Id,Name,Inspection_Date__c,Description__c from Inspection__c where Id =:inspection.Id ];
            
            // ── Send notifications to the Inspection Owner 
            sendInspectionNotifications(inspectionRecord, block.Inspection_Executive__c);
            
            // Return result
            Map<String, Object> result = new Map<String, Object>();
            result.put('inspectionId', inspection.Id);
            result.put('snagIds', snagIds);
            
            System.debug('Returning result: ' + JSON.serialize(result));
            return JSON.serialize(result);
            
        } catch (Exception e) {
            System.debug('Error in saveInspectionWithSnags: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error saving inspection: ' + e.getMessage());
        }
    }
    
    public static void sendInspectionNotifications(Inspection__c inspection, Id ownerId) {
        
        // ── 1. EMAIL NOTIFICATION ────────────────────────────────────────────────
        try {
            // Fetch owner's email address
            User owner = [SELECT Id, Email, Name FROM User WHERE Id = :ownerId LIMIT 1];
            
            if (String.isNotBlank(owner.Email)) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{ owner.Email });
                mail.setSubject('New Inspection Assigned: ' + inspection.Name);
                mail.setPlainTextBody(
                    'Dear ' + owner.Name + ',\n\n' +
                    'A new Inspection has been created and assigned to you.\n\n' +
                    'Inspection Name : ' + inspection.Name + '\n' +
                    'Inspection Date : ' + inspection.Inspection_Date__c + '\n' +
                    'Description     : ' + (String.isNotBlank(inspection.Description__c)
                                            ? inspection.Description__c : 'N/A') + '\n\n' +
                    'Please log in to Salesforce to review the details.\n\n' +
                    'Thank you.'
                );
                mail.setSaveAsActivity(false);
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
                System.debug('Email notification sent to: ' + owner.Email);
            }
        } catch (Exception e) {
            // Log but don't block the main flow
            System.debug('Email notification failed: ' + e.getMessage());
        }
        
        // ── 2. SALESFORCE IN-APP (BELL) NOTIFICATION ─────────────────────────────
        try {
            // Retrieve the Custom Notification Type — create one named
            // 'Inspection_Notification' in Setup → Notification Builder if absent
            CustomNotificationType notifType = [
                SELECT Id
                FROM CustomNotificationType
                WHERE DeveloperName = 'Inspection_Notification'
                LIMIT 1
            ];
            
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('New Inspection Assigned: ' + inspection.Name);
            notification.setBody(
                'Inspection ' + inspection.Name +
                ' has been created and assigned to you. Date: ' +
                String.valueOf(inspection.Inspection_Date__c)
            );
            notification.setNotificationTypeId(notifType.Id);
            
            // Target page — opens the Inspection record when clicked
            notification.setTargetId(inspection.Id);
            
            // Send to the owner
            notification.send(new Set<String>{ ownerId });
            System.debug('In-app notification sent to owner: ' + ownerId);
            
        } catch (Exception e) {
            // Log but don't block the main flow
            System.debug('In-app notification failed: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String uploadFileToSnag(String snagId, String fileName, String base64Data, String contentType) {
        try {
            System.debug('Starting file upload');
            System.debug('Snag ID: ' + snagId);
            System.debug('File Name: ' + fileName);
            System.debug('Content Type: ' + contentType);
            
            // Validate inputs
            if (String.isBlank(snagId)) {
                throw new AuraHandledException('Snag ID is required');
            }
            
            if (String.isBlank(fileName)) {
                throw new AuraHandledException('File name is required');
            }
            
            if (String.isBlank(base64Data)) {
                throw new AuraHandledException('File data is required');
            }
            
            // Create ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.IsMajorVersion = true;
            
            insert cv;
            
            System.debug('ContentVersion created with ID: ' + cv.Id);
            
            // Get ContentDocumentId
            ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
            Id contentDocumentId = insertedCV.ContentDocumentId;
            
            System.debug('ContentDocument ID: ' + contentDocumentId);
            
            // Create ContentDocumentLink to link file to Snag record
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = snagId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            
            insert cdl;
            
            System.debug('ContentDocumentLink created with ID: ' + cdl.Id);
            System.debug('File successfully linked to Snag: ' + snagId);
            
            return 'Success';
            
        } catch (Exception e) {
            System.debug('Error in uploadFileToSnag: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static String requestInspectionApproval(
        Id     inspectionId, 
        Date   extendedDate,
        String extensionReason    // NEW param
    ) {
        Inspection__c ins = [
            SELECT Id, Extended_Completed_Date__c, OwnerId, Extended_Completion_Reason__c
            FROM Inspection__c 
            WHERE Id = :inspectionId
        ];
        
        // ── Update Inspection ───────────────────────────────────────────────────
        ins.Extended_Completed_Date__c      = extendedDate;
        ins.Extended_Completion_Reason__c   = extensionReason;   // NEW
        update ins;
        
        // ── Update related Snag List Expected Dates ─────────────────────────────
        List<Snag_List__c> snagList = [
            SELECT Id, Expected_Completed_Date__c 
            FROM Snag_List__c 
            WHERE Inspection__c = :inspectionId
        ];
        
        List<Snag_List__c> updateList = new List<Snag_List__c>();
        for (Snag_List__c sg : snagList) {
            sg.Expected_Completed_Date__c = extendedDate;
            updateList.add(sg);
        }
        if (!updateList.isEmpty()) {
            update updateList;
        }
        
        // ── Submit for Approval ─────────────────────────────────────────────────
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(inspectionId);
        req.setSubmitterId(ins.OwnerId);
        req.setProcessDefinitionNameOrId('Extended_Completion_Date_Approval');
        req.setComments(extensionReason);   // ← reason also visible in approval history
        
        Approval.ProcessResult res = Approval.process(req);
        return res.getInstanceId();
    }
}