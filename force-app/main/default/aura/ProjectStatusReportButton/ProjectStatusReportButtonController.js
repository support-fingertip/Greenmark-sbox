({
    handleRecordLoaded: function(component, event, helper) {
        var changeType = event.getParams().changeType;
        
        if (changeType === "ERROR") {
            console.error("Error loading record");
        } else if (changeType === "LOADED" || changeType === "CHANGED") {
            var record = component.get("v.bookingRecord");
            
            var showCustomButtons = record.fields.Show_Custom_Buttons__c.value;
            console.log("showCustomButtons:", showCustomButtons);
            component.set("v.showCustomButtons", showCustomButtons);
            
            var projectType = record.fields.Project_Type__c.value;
            var showAdjustLandAmountButton = projectType == 'Villas';
            console.log("showAdjustLandAmountButton:", showAdjustLandAmountButton);
            component.set("v.showAdjustLandAmountButton", showAdjustLandAmountButton);
            
            
        }
    },
    
    handleClick : function(component, event, helper) {
        component.set("v.showPopup", true);
    },
    handleDemandClick : function(component, event, helper) {
        component.set("v.showDemandPopup", true);
    },
    handlePenaltyClick : function(component, event, helper) {
        component.set("v.showPenaltyPopup", true);
    },
    paymentSchduleEdit : function(component, event, helper) {
        component.set("v.showPaymentSchduleEdit", true);
    },
    handlePaymentScheduleClose : function(component, event, helper) {
        component.set("v.showPaymentSchduleEdit", false);
    },
    landAmountEditClick : function(component, event, helper) {
        component.set("v.showAdjustLandAmount", true);
    },
    landAmountEditClickClose : function(component, event, helper) {
        component.set("v.showAdjustLandAmount", false);
    },
})