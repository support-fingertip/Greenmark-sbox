({
    getData : function(component, event, helper) {
        component.set('v.spinner',true);
        var action = component.get("c.getBookingData");
        action.setParams({  recordId : component.get("v.recordId"),
                         projectType : component.get("v.projectType")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var records =response.getReturnValue();
                component.set('v.Booking',records.bookingRec);
                component.set('v.isResponded',records.isResponded);
                component.set('v.coApplicants',records.coApplicants);
                component.set('v.paymentSchdules',records.paymentSchdules);
                
                var items = records.receiptLineItems || [];  
                component.set('v.isRecepitsExisted', items.length > 0);
                component.set('v.receiptLineItems',items);
                component.set('v.spinner',false);
            }
        });
        $A.enqueueAction(action);
    }
})