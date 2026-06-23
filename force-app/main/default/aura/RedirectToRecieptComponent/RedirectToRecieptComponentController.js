({
    doInit : function(component, event, helper) {
        console.log('recordId'+component.get("v.recordId"));
        console.log('sObjectName'+component.get("v.sObjectName"));
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:ReceiptComponentSampleDevComp",
            componentAttributes: {
                recordId : component.get("v.recordId"),
                sObjectName : component.get("v.sObjectName")
            }
        });
        evt.fire();
    }
})