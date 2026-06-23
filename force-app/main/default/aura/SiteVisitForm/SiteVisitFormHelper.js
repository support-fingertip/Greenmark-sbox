({
	toastMsg : function (type, title, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type": type,
            "message": msg
        });
        toastEvent.fire();
    },
    createSitevisit : function(component, event, helper,leadId)
    {
        var siteVisitComments = component.get("v.siteVisitComments");
        var selectedRating = component.get("v.selectedRating");
        
        var action = component.get("c.leadNotExists");
        action.setParams({
            "leadId" : leadId,
            "selectedRating": selectedRating,
            "remark": siteVisitComments
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                component.set('v.isLoading',false);
                var selected = '1';
                component.find("tabs").set("v.selectedTabId", selected);
                component.set("v.otpStatus",null);
                component.set("v.showDetails",false);
                component.set("v.selectedProject",'None');
                component.set("v.phone",'');
                component.set("v.leadId",'');
            }else{
                helper.toastMsg('Error','Error','Something Went Wrong')
            }
        });
        $A.enqueueAction(action);
    }
})