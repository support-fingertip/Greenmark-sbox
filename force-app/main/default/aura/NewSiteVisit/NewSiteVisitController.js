({
    doInit: function(component, event, helper) {
        var action = component.get("c.getLeadDetails");
        action.setParams({ 'leadId': component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var Result = response.getReturnValue();
                if(Result.schduledVisitExisted)
                {
                    helper.showToast("Please complete the existing site visit to schedule a new visit","error");
                    $A.get("e.force:closeQuickAction").fire();
                }
                else
                {
                    console.log(' Result.Allocated_Project__c'+ Result.lead.Allocated_Project__c);
                    var visitData = {
                        SobjectTypoe :'Site_Visit__c',
                        SLead__c : Result.lead.Id,
                        LeadName :  Result.lead.Name,
                        OwnerId:Result.lead.ownerId,
                        Status__c: 'Scheduled',
                        Date__c:'',
                        Comments__c:'',
                        Site_Visit_Type__c : Result.siteVisitType,
                        Project__c: Result.lead.Allocated_Project__c
                    };
                    component.set("v.visitData", visitData);
                    component.set("v.projects", Result.projects);
                    component.set("v.statuslist", Result.status);
                    component.set("v.siteVisitTypes", Result.siteVisitTypes);               
                    component.set("v.isModalOpen", true);
                }
               
            } else {
                console.log('Failed to fetch lead details');
            }
        });
        $A.enqueueAction(action);
    },
    Cancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    save: function(component, event, helper) {
        var now = new Date();
        var today = now.toISOString();
        var sitevisitData = component.get("v.visitData");
        
        var selectedDateTime = new Date(sitevisitData.Date__c);
        var now = new Date();
        
        
        if(!sitevisitData.Date__c)
        {
            helper.showToast('Please select Scheduled Date','Error');
        }
        else if (selectedDateTime.getTime() < now.getTime()) {
            helper.showToast('Please select a future scheduled date and time.','Error');
        }
        else if(!sitevisitData.Project__c)
        {
            helper.showToast('Please select project','Error');
        }
        else if(!sitevisitData.Comments__c)
        {
            helper.showToast('Please enter comments','Error');
        }
        else
        {
            component.set("v.Saving", true);
            var action = component.get("c.saveSiteVisit");
            action.setParams({ 'siteVisitData': component.get("v.visitData")
                             });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                     var returnVal = response.getReturnValue();
                    if(returnVal == 'Schduled_Visit_Existed')
                    {
                        helper.showToast("Please complete the existing visit to schedule a new visit","Error");
                        
                    }
                    else
                    {
                         helper.showToast("Site visit created successfully","Success");
                    }
                    component.set("v.Saving", false);    
                    $A.get("e.force:closeQuickAction").fire();
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": component.get("v.recordId"),
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                } else {
                    component.set("v.Saving", false);
                    console.log('Failed to fetch lead details');
                }
            });
            $A.enqueueAction(action);
            
        }
    }
})