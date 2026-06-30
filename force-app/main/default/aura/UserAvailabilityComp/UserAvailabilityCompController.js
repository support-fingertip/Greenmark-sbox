({
    doInit: function(component, event, helper){
        helper.getUsers(component);
    },
    selectChange:function(component, event, helper){
        var isAvailable = event.getSource().get("v.checked");
        
        // Set the CSS class dynamically based on the toggle state
        if(isAvailable) {
            component.set("v.toggleClass", "custom1-toggle-style"); // Green for available
        } else {
            component.set("v.toggleClass", "custom2-toggle-style"); // Red for offline
        }
        var user=component.get('v.usr');
        helper.onChange(component,event,'');
    },
    workingChange:function(component, event, helper){
        var isWorking = event.getSource().get("v.checked");
        var user = component.get('v.usr');
        user.is_working__c = isWorking;
        // Rule: if user marks "Leave" (not working), move Available status to "Unavailable".
        if(!isWorking){
            user.Availability__c = false;
            component.set("v.toggleClass", "custom2-toggle-style"); // Red for offline
        }
        component.set('v.usr', user);
        helper.onChange(component,event,'');
    },
    closePopUP:function(component, event, helper){
        var user=component.get('v.usr');
        user.Availability__c = true;
        component.set('v.usr', user);
        component.set("v.isFalse", false);
    },
    submitDetails:function(component, event, helper){
        var reasone= component.find('reasone').get('v.value');
        if(reasone.length>0){
            helper.onChange(component,event,reasone);
            component.set('v.isFalse',false);
        }
        else{
            var toastsuccessEvent = $A.get("e.force:showToast");
            toastsuccessEvent.setParams({
                "title": "Select Reasone.",
                "message": "Please Select the Reasone.",
                "type" : "error"
            });
            toastsuccessEvent.fire(); 
        }
    }
})