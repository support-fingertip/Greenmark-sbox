({
    doInit : function(component, event, helper) {
        component.set("v.isProcessing", false); 
    },
    submitforApproval : function(component, event, helper) {
        
        var comments = component.get("v.Comments");
        var extensionDays = component.get("v.extensionDays");
        if(extensionDays == 0 || extensionDays ==null || extensionDays == undefined){
            component.set("v.Saving", false);
            helper.showToast("Please Enter Agreement Extension Days","error");
        }
        else if(comments == null || comments== undefined || comments == '')
        {
            helper.showToast("Please enter  comments","error");
            component.set("v.Saving", false);
        }      
        else
        {
            component.set("v.isProcessing", true);
            
            var bookingId  = component.get("v.recordId");
            var action = component.get("c.submitforextensionApproval");
            action.setParams({ bookingId: bookingId ,
                              extensionDays: extensionDays ,
                              newNote:comments});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {	
                    var result = response.getReturnValue();
                    helper.showToast('Agreement time extension request submitted successfully','Success');
                    $A.get("e.force:closeQuickAction").fire();
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": bookingId,
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                    $A.get('e.force:refreshView').fire();
                    
                    
                } else {
                    component.set("v.resultMessage", "Error occurred: " + response.getError()[0].message);
                }
                
                component.set("v.isProcessing", false);
            });
            
            $A.enqueueAction(action);
        }
    },
    closeModel: function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
})