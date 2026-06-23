({
    doInit : function(component, event, helper) {
        
        component.set('v.showPdf',true);;

    },
    sendEmail: function(component,event,helper){
        var action = component.get("c.sendEmailtoCustomer");
        action.setParams({"recId":component.get("v.recordId"),
                         "projectType":"Construction"});
        action.setCallback(this,function(response){
            if(response.getState() == 'SUCCESS' ) {
                
                var res_string= response.getReturnValue();
                event.stopPropagation();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                var type;
                if(res_string == 'Booking form sent to customer'){
                    //system.debug(res_string);
                    type = 'success';
                }
                else{
                    type = 'error';
                }
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type":type,
                    "title": type,
                    "message":res_string,
                    "duration":10000
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            }
            else
            {
                (state === 'ERROR')
                {
                    console.log('failed');
                }
            }
        });
        $A.enqueueAction(action);
    },
    close : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
 
    closeModal : function(component, event, helper) {
        // Close the confirmation modal
        component.set("v.isPopup", false);
    },	
})