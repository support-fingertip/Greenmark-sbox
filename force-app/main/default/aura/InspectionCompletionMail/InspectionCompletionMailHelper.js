({
    getEmailData: function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var action = component.get("c.getEmailData");
        action.setParams({
            "recordId": recordId
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();

                component.set("v.customerEmail", result.customerEmail);
                component.set("v.customerName", result.customerName);
                component.set("v.subject", result.subject);

                var raw = result.emailContent;

                var decoded = raw
                    .replace(/&lt;/g, "<")
                    .replace(/&gt;/g, ">")
                    .replace(/&amp;/g, "&");

                decoded = decoded.replace(/<span[^>]*>/g, "");
                decoded = decoded.replace(/<\/span>/g, "");
                decoded = decoded.replace(/<p><br><\/p>/g, "");

                var richText = component.find("emailContent");
                richText.set("v.value", decoded);

            } else {
                console.error("Error retrieving inspection data");
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": "error",
                    "title": "Error",
                    "message": "Failed to load inspection data. Please try again."
                });
                toastEvent.fire();
            }
        });

        $A.enqueueAction(action);
    },

    showToast: function(type, title, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": type,
            "title": title,
            "message": message
        });
        toastEvent.fire();
    }
})