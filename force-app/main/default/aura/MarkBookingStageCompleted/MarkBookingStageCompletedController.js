({
    doInit : function(component, event, helper) {
        component.set("v.isButtonDisabled", false);
    },
    markStageCompleted : function(component, event, helper){
        var comments = component.get("v.newNote");
        if(!comments)
        {
            helper.showToast("Error", "Please enter Comments", "Error");
            return;
        }

        component.set("v.isButtonDisabled", true);
        var action = component.get("c.markStageAsCompleted");
        action.setParams({ 
            bookingId: component.get("v.recordId"),
            newNote: component.get("v.newNote")
        });
        
        action.setCallback(this, function(response) {
            component.set("v.isButtonDisabled", true);
            var state = response.getState();
            if (state === 'SUCCESS') {
                helper.showToast("Success", "Stage marked complete. The booking has moved to the next stage and been reassigned to the configured CRM Executive.", "Success");
                
                var recordId = component.get("v.recordId");
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": recordId,
                    "slideDevName": "detail"
                });
                navEvt.fire();
                $A.get('e.force:refreshView').fire();
            }
            else {
                component.set("v.isButtonDisabled", false);
                var errors = response.getError();
                var message = 'Unknown error';
                
                if (errors && errors[0] && errors[0].message) {
                    
                    message = errors[0].message;
                    
                    // Extract only custom validation message
                    if (message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION,')) {
                        message = message.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,')[1];
                    }
                    
                    // Remove trailing brackets []
                    message = message.replace(/\[\]/g, '');
                    
                    //  Remove trailing colon if present
                    message = message.replace(/:\s*$/, '');
                    
                    message = message.trim();
                }
                
                $A.get("e.force:showToast").setParams({
                    title: "Error",
                    message: message,
                    type: "error"
                }).fire();
                
                
            }
        });
        $A.enqueueAction(action);
    },
    closeModel :function(component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
    }
})