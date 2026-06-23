({
    doInit : function(component, event, helper) {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString); 
        
        // Read parameters from URL
        const recId = urlParams.get('id');
        const projectType = urlParams.get('type');
        
        // Set component attributes
        component.set("v.recordId", recId);
        component.set("v.projectType", projectType);
        
        console.log('Record Id:', recId);
        console.log('Project Type:', projectType);
        
        // Call helper
        helper.getData(component, event, helper);   
    },

    
    approve : function(component, event, helper) {
        component.set('v.spinner',true);
        component.set("v.IsSaveDisabled",true);
        var action = component.get("c.updateBooking");
        action.setParams({  recordId : component.get("v.recordId"),
                          comments : component.get("v.approvalComments"),
                          appovalStatus : 'Approved',
                          projectType : component.get("v.projectType")
                         });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                component.set('v.isResponded',true);
                component.set("v.IsSaveDisabled",false);
                component.set('v.spinner',false);
            }
        });
        $A.enqueueAction(action);
    },
    
    reject : function(component, event, helper) {
        component.set('v.spinner',true);
        component.set("v.IsSaveDisabled",true);
        var action = component.get("c.updateBooking");
        action.setParams({  recordId : component.get("v.recordId"),
                          comments : component.get("v.approvalComments"),
                          appovalStatus : 'Rejected',
                          projectType : component.get("v.projectType")
                         });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                component.set("v.isResponded",true);
                component.set("v.IsSaveDisabled",false);
                component.set('v.spinner',false);
            }
        });
        $A.enqueueAction(action);
    },
    
    
})