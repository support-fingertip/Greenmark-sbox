({ 
    doInit : function(component, event, helper) {
        
        var action=component.get("c.callUnitHoldController");
        action.setParams({'recId':  component.get('v.recordId') })
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state == "SUCCESS" ){ 
                 var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                   var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "type":'Success',
                                "title": 'Success!',
                                "message":'Unit Status Updated to HOLD',
                                "duration":10000
                            });
                            toastEvent.fire();
            }
            else if (state === 'ERROR') {
            let errors = response.getError();
            var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":'Error',
                        "title": 'Error!',
                        "message": errors[0].message,
                        "duration":10000
                    });
                    toastEvent.fire();

            
        }

        });
        $A.enqueueAction(action); 
    },
   
})