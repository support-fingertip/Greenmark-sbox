({
    doInit : function(component, event, helper) {
        var bookingRecord = component.get("v.bookingRecord");
        if (bookingRecord && bookingRecord.Project_Type__c ) {
            component.set("v.projectType", bookingRecord.Project_Type__c);
        }
        component.set('v.showPdf',true);
    },
    close : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    sendEmail: function (component, event, helper) {
        var action = component.get("c.sendEmailToCustomerNOC");
        var bookingRecordId = component.get("v.recordId");
        action.setParams({ "recId": component.get("v.recordId")
                         });  
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": 'success',
                    "title": 'NOC',
                    "message": 'NOC Sent successfully.',
                    "duration": 10000
                });
                toastEvent.fire();
                
            } else {
                console.log('Failed to send email.');
            }
        });
        $A.enqueueAction(action);
    },
})