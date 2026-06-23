({
    doInit : function(component, event, helper) {
        var action = component.get("c.getUnqualifiedReasons");
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                component.set("v.unqualifiedReasons", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    handleReasonChange: function(component, event, helper) {
        var selectedValue = event.getSource().get("v.value");
        component.set("v.selectedReason", selectedValue);
    },
    
    handleSubmit : function(component, event, helper) {
        
        var reason = component.get("v.selectedReason");
        var updatec = component.get("v.comment");
        
        /*  if (!comment || comment.trim() === '') {
            $A.get("e.force:showToast").setParams({
                "title": "Validation Error",
                "message": "Please enter a comment before submitting.",
                "type": "error"
            }).fire();
            return;
        }*/
        if (reason == 'Other'&& updatec=='') {
             $A.get("e.force:showToast").setParams({
                "title": "Validation Error",
                "message": "Please enter a comment before submitting.",
                "type": "error"
            }).fire();
            return; 
    }
        var action = component.get("c.updateLeadComment");
        action.setParams({
            leadId: component.get("v.recordId"),
            reason: reason,
            comment: updatec
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
                $A.get("e.force:showToast").setParams({
                    "title": "Success",
                    "message": "Marked Unqualifed successfully!",
                    "type": "success"
                }).fire();
            } else {
                let errors = response.getError();
                console.error(errors);
                $A.get("e.force:showToast").setParams({
                    "title": "Error",
                    "message": "Something went wrong.",
                    "type": "error"
                }).fire();
            }
        });
        
        $A.enqueueAction(action);
    },
    
    handleCancel : function(component, event, helper) {
        component.set("v.isOpen", false);
        $A.get("e.force:closeQuickAction").fire();
    }
})