({
    doInit : function(component, event, helper) {
        component.set("v.isProcessing", true);
        var bookingId = component.get("v.recordId");
        var action = component.get("c.bookingChecking");
        
        action.setParams({ bookingId: bookingId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {	
                var result = response.getReturnValue();
                if(result) {
                    helper.showToast('Cancellation Already Requested','info');
                    component.set("v.isProcessing", false);
                    $A.get("e.force:closeQuickAction").fire();
                    
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": bookingId,
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                    $A.get('e.force:refreshView').fire();
                } else {
                    component.set("v.isProcessing", false);
                }
            } else {
                component.set("v.isProcessing", false);
                console.error("Error: ", response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    orderCancel : function(component, event, helper) {
      

        component.set("v.isProcessing", true);
        var bookingId = component.get("v.recordId");
        var action = component.get("c.cancelBooking");
        
        action.setParams({ 
            bookingId: bookingId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {	
                helper.showToast('Booking cancellation request sent successfully','Success');
                $A.get("e.force:closeQuickAction").fire();
                
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": bookingId,
                    "slideDevName": "detail"
                });
                navEvt.fire();
                $A.get('e.force:refreshView').fire();
            } else {
                var errors = response.getError();
                helper.showToast("Error: " + (errors[0] ? errors[0].message : "Unknown error"), "error");
            }
            component.set("v.isProcessing", false);
        });
        $A.enqueueAction(action);
    },

    closeModel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})