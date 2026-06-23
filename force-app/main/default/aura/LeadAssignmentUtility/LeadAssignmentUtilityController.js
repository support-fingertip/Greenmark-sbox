({
    doInit : function(component, event, helper) {
        helper.subscribeToChannel(component);
    },
    

    handleViewLead : function(component, event, helper) {
        const leadId = component.get("v.latestLeadId");
        const navService = component.find("navService");

        const pageReference = {
            type: "standard__recordPage",
            attributes: {
                recordId: leadId,
                objectApiName: "Lead",
                actionName: "view"
            }
        };
        navService.navigate(pageReference);

        // ✅ Optionally clear the lead info to hide the button
        component.set("v.latestLeadId", null);
        component.set("v.latestLeadName", null);
    }
})