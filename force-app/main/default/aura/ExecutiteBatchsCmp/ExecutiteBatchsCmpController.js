({
    runBatch : function(component, event, helper) {

        var action = component.get("c.runPaymentReminderBatch");

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === "SUCCESS") {
                helper.showToast('Success', 'Success', 'Batch Called Successfully');
                
            } else {
                component.set("v.message", "Error starting batch.");
            }
        });

        $A.enqueueAction(action);
    },
    runBatchAgreement : function(component, event, helper) {
        
        var action = component.get("c.agreementbatch");
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                helper.showToast('Success', 'Success', 'Batch Called Successfully');
                
            } else {
                component.set("v.message", "Error starting batch.");
            }
        });

        $A.enqueueAction(action);
    }
})