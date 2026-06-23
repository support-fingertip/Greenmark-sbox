({
    subscribeToChannel : function(component) {
        const empApi = component.find("empApi");
        const channel = component.get("v.channel");
        const userId = $A.get("$SObjectType.CurrentUser.Id");
        
        component.set("v.userId", userId);
        
        const replayId = -1;
        
        empApi.subscribe(channel, replayId, $A.getCallback(function (eventReceived) {
            const payload = eventReceived.data.payload;
            
            if (payload.UserId__c === userId) {
                const leadId = payload.LeadId__c;
                const leadName = payload.LeadName__c;
                component.set("v.latestLeadId", leadId);
                component.set("v.latestLeadName", leadName);
                // Use messageTemplate + messageTemplateData for clickable link
                $A.get("e.force:showToast").setParams({
                    title: "New Lead Assigned: " + leadName,
                    message: "Lead " + leadName + " has been assigned to you.",
                    type: "success",
                    mode: "pester"
                }).fire();
            }
        })).then(function (subscription) {
            console.log("Subscribed to channel " + channel);
            component.set("v.subscription", subscription);
        });
    }
})