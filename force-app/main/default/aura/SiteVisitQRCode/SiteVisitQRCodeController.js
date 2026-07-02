({
    doInit: function(component, event, helper) {
        var action = component.get("c.getQrImageUrl");
        action.setParams({ recordId: component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.qrUrl", response.getReturnValue());
            } else {
                component.set("v.error", helper.getError(response, "Unable to load the QR code."));
            }
        });
        $A.enqueueAction(action);
    },

    sendQr: function(component, event, helper) {
        component.set("v.isLoading", true);
        var action = component.get("c.sendQrCodeEmail");
        action.setParams({ recordId: component.get("v.recordId") });
        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.toast("Success", "QR code emailed to " + response.getReturnValue(), "success");
            } else {
                helper.toast("Error", helper.getError(response, "Failed to send the QR code."), "error");
            }
        });
        $A.enqueueAction(action);
    }
})