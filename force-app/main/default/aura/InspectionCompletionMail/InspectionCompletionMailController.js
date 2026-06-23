({
    doInit: function(component, event, helper) {
        helper.getEmailData(component, event, helper);
    },
    handleFileUpload: function(component, event, helper) {
        var files = event.getParam("files");
        var getFiles = component.get("v.filesIDS");
        if (!getFiles) {
            getFiles = [];
        }
        getFiles.push(...files);
        component.set("v.filesIDS", getFiles);
    },
    sendEmail: function(component, event, helper) {
        component.set("v.isSending", true);
        var content = component.get("v.emailContent");
        content = content.replace(/<p>(&nbsp;|\s)*<\/p>/g, '');
        content = content.replace(/(<br\s*\/?>\s*){2,}/g, '<br/>');
        var action = component.get("c.sendInspectionEmail");
        action.setParams({
            "inspectionId": component.get("v.recordId"),
            "emailContent": content,
            "contentIds": component.get("v.filesIDS"),
            "subject": component.get("v.subject")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                $A.get("e.force:closeQuickAction").fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "success",
                    "title": "Success",
                    "message": "Inspection completion email sent successfully!",
                    "duration": 3000
                });
                toastEvent.fire();
                $A.get("e.force:refreshView").fire();
            } else if (state === "ERROR") {
                var errors = response.getError();
                var errorMsg = "Unknown error";
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    errorMsg = errors[0].message;
                }
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error",
                    "message": errorMsg,
                    "duration": 5000
                });
                toastEvent.fire();
            }
            component.set("v.isSending", false);
        });
        $A.enqueueAction(action);
    },
    Cancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})