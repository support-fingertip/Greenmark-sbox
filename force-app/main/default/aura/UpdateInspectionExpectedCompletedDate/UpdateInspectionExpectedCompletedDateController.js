({
    submitForApproval : function(component, event, helper) {
        var extendedDate    = component.get("v.extendedDate");
        var extensionReason = component.get("v.extensionReason");
        
        // ── Validate Date ───────────────────────────────────────────────────
        if (!extendedDate || extendedDate.trim() === '') {
            var toast = $A.get("e.force:showToast");
            toast.setParams({
                title   : "Error",
                message : "Please enter an Extended Completed Date before submitting.",
                type    : "error"
            });
            toast.fire();
            return;
        }
        
        // ── Validate Reason ─────────────────────────────────────────────────
        if (!extensionReason || extensionReason.trim() === '') {
            var toast = $A.get("e.force:showToast");
            toast.setParams({
                title   : "Error",
                message : "Please provide a reason for the extension request.",
                type    : "error"
            });
            toast.fire();
            return;
        }
        
        // ── Call Apex ───────────────────────────────────────────────────────
        var action = component.get("c.requestInspectionApproval");
        action.setParams({
            inspectionId    : component.get("v.recordId"),
            extendedDate    : extendedDate,
            extensionReason : extensionReason   // NEW param
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var toast = $A.get("e.force:showToast");
                toast.setParams({
                    title   : "Success",
                    message : "Extension approval submitted successfully.",
                    type    : "success"
                });
                toast.fire();
                
                $A.get("e.force:closeQuickAction").fire();
                $A.get("e.force:refreshView").fire();
            } else {
                var errors  = response.getError();
                var message = errors && errors[0] && errors[0].message
                            ? errors[0].message
                            : "Unknown error";
                
                var toast = $A.get("e.force:showToast");
                toast.setParams({
                    title   : "Error",
                    message : message,
                    type    : "error"
                });
                toast.fire();
            }
        });
        
        $A.enqueueAction(action);
    },
    
    doCancel : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})