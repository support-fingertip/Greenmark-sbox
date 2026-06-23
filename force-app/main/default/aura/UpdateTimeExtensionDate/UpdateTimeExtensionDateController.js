({
    doInit : function(component, event, helper) {
     component.set("v.isButtonDisabled", false);
        
    },
    pushToSalesComp : function(component, event, helper){

        var comment = component.get("v.comment");
        var extensionDays = component.get("v.extensionDays");
        component.set("v.isButtonDisabled", true);
        if(comment == '' || comment == 'None' || comment ==null || comment == undefined){
            component.set("v.isButtonDisabled", false);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                message: 'Please Enter Comments',
                type : 'error'
            });
            toastEvent.fire();
        }
        else if(extensionDays == 0 || extensionDays ==null || comment == undefined){
            component.set("v.isButtonDisabled", false);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                message: 'Please Enter Agreement Extension Days',
                type : 'error'
            });
            toastEvent.fire();
        }
        
        else {
            component.set("v.isButtonDisabled", true);
            
            var status = event.getSource().get("v.name");
            // Call moveToSales if the site visit is scheduled
            var action = component.get("c.moveToSales");
                action.setParams({ 
                    bookingId: component.get("v.recordId"),
                    newNote: component.get("v.comment"),
                    extensionDays : component.get("v.extensionDays"),
                    status : status
                });
                
                action.setCallback(this, function(response) {
                     component.set("v.isButtonDisabled", true);
                    var state = response.getState();
                    if (state === 'SUCCESS') {
                        
                        helper.showToast(
                            "Success",
                            "Agreement Time Extension has been " + status + " successfully.",
                            "success"
                        );


                        var recordId = response.getReturnValue();
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": recordId,
                            "slideDevName": "detail"
                        });
                        navEvt.fire();
                        $A.get('e.force:refreshView').fire();
                    }
                });
                $A.enqueueAction(action);
                
            }
           
        
    },
    closeModel :function(component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
    }
})