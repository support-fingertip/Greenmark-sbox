({
    doInit : function(component, event, helper) {
     component.set("v.isButtonDisabled", false);  
    },
    pushToCRMComp : function(component, event, helper){
        var comments = component.get("v.newNote");
        if(comments == null || comments == undefined)
        {
            $A.get("e.force:showToast").setParams({
                "title": "Error",
                "message": "Please enter comments",
                "type": "error"
            }).fire();
            return;
        }
        component.set("v.isButtonDisabled", true);
        var action = component.get("c.moveToCRM");
        action.setParams({ 
            bookingId: component.get("v.recordId"),
            comments: component.get("v.newNote")
        });
        
        action.setCallback(this, function(response) {
            component.set("v.isButtonDisabled", true);
            var state = response.getState();
            component.set("v.isButtonDisabled", false);
            if (state === 'SUCCESS') {
                
                var returnVal = response.getReturnValue();
                if(returnVal == 'BookingFormNotSent')
                {
                    helper.showToast("Error", "Please send the booking form to the customer before pushing it to CRM.", "Error");
                }
                else
                {
                    helper.showToast("Success", "Booking has been Submitted for Approval", "Success");
                    
                    
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": returnVal,
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                    $A.get('e.force:refreshView').fire();
                }
                
            }
            else {
                var errors = response.getError();
                var message = 'Unknown error';
                
                if (errors && errors[0] && errors[0].message) {
                    message = errors[0].message;
                    
                    // Extract only validation message after comma
                    if (message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                        message = message.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,')[1];
                    }
                    
                    // Optional: remove trailing characters like : []
                    if (message) {
                        message = message.replace(': []', '').trim();
                    }
                }
                
                $A.get("e.force:showToast").setParams({
                    "title": "Error",
                    "message": message,
                    "type": "error"
                }).fire();
            }
        });
        $A.enqueueAction(action);
    },
    closeModel :function(component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
    }
})