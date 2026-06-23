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
   
})