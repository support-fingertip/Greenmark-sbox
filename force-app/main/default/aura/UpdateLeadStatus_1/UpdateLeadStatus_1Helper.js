({
    Toast: function (type, title, msg) 
    {
        var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": title,
                    "message": msg,
                    "type":type
                });
                toastEvent.fire();
    },
    getFilteredLeadStages: function (component, event, helper)
    {
        var actionLeadStages = component.get("c.getFilteredLeadStages");
        actionLeadStages.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                //alert(JSON.stringify(response.getReturnValue()));
                component.set("v.LeadStages",response.getReturnValue());  
            }
        });
        $A.enqueueAction(actionLeadStages);
    },
    getFollowUps: function (component, event, helper)
    {
       var action = component.get("c.getFollowUps"); // Ensure you're calling the method correctly
        action.setParams({
            RecordId: component.get("v.recordId") // Set the RecordId parameter from the component's attribute
        });
        
        // Set the callback for handling the response
        action.setCallback(this, function(response) {
            var state = response.getState(); // Get the state of the response
            if (state === 'SUCCESS') {
                 var returnValue = response.getReturnValue();
                // Display the returned value in an alert
                if (returnValue == null || (Array.isArray(returnValue) && returnValue.length === 0)) {
                    console.log("The returned value is null or an empty array.");
                   // alert("No follow-up records found.");
                } else {
                    //alert('Please mark the follow-up as completed.');
                    // Process the array if it's not null or empty
                    console.log("Returned value:", JSON.stringify(returnValue)); // Log the response
                    // component.set("v.projectList", returnValue); // Uncomment this line to use the data
                     component.set("v.LastFollowupScheduledDate",returnValue[0].Scheduled_Date__c);
                     component.set("v.LastFollowupDescription",returnValue[0].Description__c);
                    //helper.Toast('warning', 'warning', 'Please mark the follow-up as completed.');
                    component.set("v.completedSec",true);
                }
                // Uncomment the line below to set the projectList attribute with the returned value
                // component.set("v.projectList", response.getReturnValue());  
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors && errors.length > 0) {
                    console.error("Error message: " + errors[0].message); // Log the error message
                } else {
                    console.error("Unknown error"); // Handle unknown errors
                }
            }
        });
        
        // Enqueue the action to send the request to the server
        $A.enqueueAction(action); 
    },
    getProject: function (component, event, helper)
    {
        var action = component.get("c.getProject");
        action.setParams({
            RecordId : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                var responseValue = response.getReturnValue();
                component.set("v.projectList",response.getReturnValue()); 
                //alert(JSON.stringify(response.getReturnValue()));
                /*if(responseValue.length > 0){
                   component.set("v.projectList",responseValue); 
                }*/
            }
        });
        $A.enqueueAction(action);
    },
    getAllocatedProject: function (component, event, helper)
    {
       var action = component.get("c.getAllocatedProject");
        action.setParams({
            RecordId : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                //alert(JSON.stringify(response.getReturnValue()));
                component.set("v.AllocatedprojectList",response.getReturnValue());  
            }
        });
        $A.enqueueAction(action); 
    },
    getMissedFollowUps: function (component, event, helper)
    {
        var actionFollowupMissed = component.get("c.getMissedFollowUps");
        actionFollowupMissed.setParams({
            RecordId : component.get("v.recordId")
        });
        actionFollowupMissed.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                component.set("v.MissedFollowup",response.getReturnValue());  
            }
        });
        $A.enqueueAction(actionFollowupMissed);
    }
})