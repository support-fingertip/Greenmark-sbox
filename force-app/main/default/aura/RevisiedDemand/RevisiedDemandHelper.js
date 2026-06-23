({
    getData: function(component, event, helper) {
        var bookingId = component.get("v.recordId");
        
        var action = component.get("c.getRevisedDemandData");
        action.setParams({
            bookingId: bookingId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnData = response.getReturnValue();
                component.set("v.canRaiseDemand", returnData.isDemandRaised);
                component.set("v.lastPymtSchedule", returnData.lastPymtSchedule);
                component.set("v.subject", returnData.subject);
                
                var raw = returnData.emailContent;
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
                console.log("richText" , richText);
                richText.set("v.value", decoded);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    console.log("Error message: " + errors[0].message);
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
    showToast: function(message, type, title) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
    
})