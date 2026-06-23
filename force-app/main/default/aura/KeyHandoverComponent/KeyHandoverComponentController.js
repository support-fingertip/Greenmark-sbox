({
    doInit : function(component, event, helper) {
        var booking = component.get("v.booking");
        var recordId = component.get("v.recordId");
        var vfName = "";

        if (booking) {
            var pType = booking.Project_Type__c;
            if (pType === 'Villas') {
                vfName = "VillasKeyHandoverVfp";
            } else if (pType === 'Row House') {
                vfName = "RowHouseKeyHandoverVfp";
            } else if (pType === 'Apartments' || pType === 'Plots') {
                vfName = "FlatKeyHandoverVfp";
            }

            if (vfName !== "") {
                // Ensure URL parameters are correct for Visualforce
                component.set("v.pdfUrl", "/apex/" + vfName + "?id=" + recordId);
                component.set("v.showPdf", true);
            }
        }
    },

    close : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

    openConfirm : function(component, event, helper) {
        component.set("v.isPopup", true);
    },

    closeConfirm : function(component, event, helper) {
        component.set("v.isPopup", false);
    },

    processSend : function(component, event, helper) {
        component.set("v.isSending", true);
        component.set("v.isPopup", false); 

        var action = component.get("c.sendKeyHandoverEmail");
        action.setParams({ bookingId: component.get("v.recordId") });

        action.setCallback(this, function(response) {
            component.set("v.isSending", false);
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var res = response.getReturnValue();
                var isSuccess = res && res.startsWith("Success");
                
                helper.showToast(
                    isSuccess ? "Success" : "Error", 
                    res, 
                    isSuccess ? "success" : "error"
                );

                if (isSuccess) {
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get("e.force:refreshView").fire();
                }
            } else {
                helper.showToast("Error", "Server error occurred", "error");
            }
        });
        $A.enqueueAction(action);
    }
})