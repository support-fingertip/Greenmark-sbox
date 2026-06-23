({
    doInit: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var action = component.get("c.getRecordData");
        action.setParams({
            "recordId": recordId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var result = response.getReturnValue();
                component.set("v.record", result.bookingRecord);
                
                var raw = result.emailTemplate;
                
                // 1. Decode HTML entities first
                var decoded = raw
                .replace(/&lt;/g, "<")
                .replace(/&gt;/g, ">")
                .replace(/&amp;/g, "&");
                
                // 2. Remove extra span wrappers added by RTE
                decoded = decoded.replace(/<span[^>]*>/g, "");
                decoded = decoded.replace(/<\/span>/g, "");
                
                // 3. Remove empty paragraphs created by editor
                decoded = decoded.replace(/<p><br><\/p>/g, "");
                
                // 4. Set to Rich Text
                var richText = component.find("emailContent");
                richText.set("v.value", decoded);

                
            }
            else {
                console.error("Error retrieving record data");
            }
        });
        
        $A.enqueueAction(action);
    },
    handleFileUpload: function(component, event, helper) {
        var files = event.getParam("files");
        var getFiles = component.get("v.filesIDS");
        getFiles.push(...files);
        component.set('v.filesIDS',getFiles);
        
        var afercomit = component.get('v.filesIDS');
    },
    sendEmail: function(component, event, helper) {
        // Prevent multiple clicks by checking if already sending
        if (component.get("v.isSending")) {
            return;
        }
        
        // Set sending flag to true to disable button
        component.set("v.isSending", true);
        
        var recList = component.get('v.recepients');
        var allFiles = component.get('v.files');
        var contentDocumentIds = component.get('v.filesIDS');

        var content = component.get("v.emailContent");
        // Remove empty paragraphs created by inputRichText
        content = content.replace(/<p>(&nbsp;|\s)*<\/p>/g, '');
        // Also handle multiple breaks
        content = content.replace(/(<br\s*\/?>\s*){2,}/g, '<br/>');
        
        var record = component.get("v.record");
        
        var toAddresses = [];
        if(recList) {
            var recList = recList.split(',');
            recList.forEach(function(email) {
                toAddresses.push(email.trim());
            });
        }
        if (record.Email__c) {
            toAddresses.push(record.Email__c);
        }
        
        if (toAddresses.length === 0) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "No email address available to send the email.",
                "type": "error"
            });
            toastEvent.fire();
            
            // Re-enable button on error
            component.set("v.isSending", false);
            return;
        }
        
        var action = component.get("c.sendUnitReadynessEmail");
        action.setParams({
            "recordId": component.get("v.record.Id"),
            "toAddresses": toAddresses,
            "emailContent": content,
            "contentIds": contentDocumentIds
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Unit Readiness Email Sent Successfully.",
                    "type": "success"
                });
                toastEvent.fire();
                
                $A.get('e.force:refreshView').fire();
                $A.get("e.force:closeQuickAction").fire();
            } else {
                console.error("Error sending email");
                
                // Re-enable button on error
                component.set("v.isSending", false);
                
                // Show error toast
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "Failed to send email. Please try again.",
                    "type": "error"
                });
                toastEvent.fire();
            }
        });
        
        $A.enqueueAction(action);
    },
    Cancel: function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },
    
})