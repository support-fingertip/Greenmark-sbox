({
    doInit : function(component, event, helper) {
     component.set("v.isButtonDisabled", false);
        
    },
    pushToSalesComp : function(component, event, helper){
          component.set("v.isButtonDisabled", true);
       // var recordEditForm = component.get("v.selectedProject");
       // alert(recordEditForm)
        var transferNotes = component.get("v.newNote");
      
        if(transferNotes == '' || transferNotes == 'None' || transferNotes ==null || transferNotes == undefined){
            component.set("v.isButtonDisabled", false);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                message: 'Please Enter transfer notes',
                type : 'error'
            });
            toastEvent.fire();
        }
        
        else {
            component.set("v.isButtonDisabled", true);
            // Call moveToSales if the site visit is scheduled
            var action = component.get("c.moveToSales");
                action.setParams({ 
                    LeadId: component.get("v.recordId"),
                    addNote: component.get("v.newNote")
                });
                
                action.setCallback(this, function(response) {
                     component.set("v.isButtonDisabled", true);
                    var state = response.getState();
                    if (state === 'SUCCESS') {
                        helper.showToast("Success", "Lead moved to sales team", "Success");

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