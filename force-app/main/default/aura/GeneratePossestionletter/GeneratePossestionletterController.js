({
    // Runs after record is loaded
onRecordLoad : function(component, event, helper) {
    var eventParams = event.getParams();
    // Only proceed if the record is successfully loaded or changed
    if(eventParams.changeType === "LOADED" || eventParams.changeType === "CHANGED") {
        var booking = component.get("v.BookingRecord");
        if (booking) {
            var projectType = booking.Project_Type__c;
            var pageName = '';

            if(projectType === 'Villas') {
                pageName = 'VillaPossessionLetter';
            } else if(projectType === 'Row House') {
                pageName = 'RowHousePossessionLetter';
            } else if(projectType === 'Apartments' || projectType === 'Plots') {
                pageName = 'FlatPossessionLetter';
            } else {
                // If the field is blank in Salesforce, this triggers
                component.set("v.errorMessage", "Project Type is empty or invalid on this record.");
            }
            
            component.set("v.vfPageName", pageName);
            component.set("v.projectType", projectType);
            component.set("v.isLoading", false);
        }
    } else if(eventParams.changeType === "ERROR") {
        component.set("v.errorMessage", "Error loading record data.");
        component.set("v.isLoading", false);
    }
},

    close : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

sendEmail: function(component, event, helper) {

    component.set("v.errorMessage", "");

    
    var booking = component.get("v.BookingRecord");
    var possessionDate = booking ? booking.Possession_Date__c : null;

    if (!possessionDate) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": "warning",
            "title": "Warning",
            "message": "Please provide the Possession Date before sending Mail"
           
        });
        toastEvent.fire();

        component.set("v.errorMessage", "Please provide the Possession Date before sending Mail");
        return; // stop here
    }

    
    component.set("v.isLoading", true);

    var action = component.get("c.sendPossessionLetterViaProjectType");
    action.setParams({ bookingId: component.get("v.recordId") });
    action.setCallback(this, function(response) {
        component.set("v.isLoading", false);
        var state = response.getState();
        var ret = response.getReturnValue();

        if (state === 'SUCCESS' && ret && ret.indexOf('Success') === 0) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "success",
                "title": "Email Sent",
                "message": ret,
                "duration": 8000
            });
            toastEvent.fire();
            $A.get("e.force:closeQuickAction").fire();
        } else {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type": "error",
                "title": "Error",
                "message": ret || response.getError()[0].message,
                "duration": 8000
            });
            toastEvent.fire();
            component.set("v.errorMessage", ret || response.getError()[0].message);
        }
    });
    $A.enqueueAction(action);
}
})