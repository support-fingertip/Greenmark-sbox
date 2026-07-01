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

    // ---------- QR: resolve scanned value -> Lead, render in the QR tab ----------
    processScan : function(component, decodedText) {
        var helper = this;
        component.set("v.isLoading", true);
        var action = component.get("c.getLeadIdFromScan");
        action.setParams({ "scannedValue": decodedText });
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                helper.loadLead(component, response.getReturnValue());
            } else {
                component.set("v.isLoading", false);
                component.set("v.qrError", helper.errMsg(response, "Invalid QR Code."));
            }
        });
        $A.enqueueAction(action);
    },

    loadLead : function(component, leadId) {
        var helper = this;
        var action = component.get("c.getLead");
        action.setParams({ "leadId": leadId });
        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);
            if (response.getState() === "SUCCESS") {
                var rv = response.getReturnValue();
                component.set("v.leadRecord", rv.Lead);
                component.set("v.leadId", leadId);
                component.set("v.siteVisit", rv.siteVisit);
                component.set("v.qrShowDetails", true);
                component.set("v.qrError", null);
            } else {
                component.set("v.qrError", helper.errMsg(response, "Lead not found."));
            }
        });
        $A.enqueueAction(action);
    },

    errMsg : function(response, fallback) {
        var errs = response.getError();
        if (errs && errs[0] && errs[0].message) { return errs[0].message; }
        return fallback;
    },

    createSitevisit : function(component, event, helper,leadId)
    {
        var siteVisitComments = component.get("v.siteVisitComments");
        var selectedRating = component.get("v.selectedRating");
        
        var action = component.get("c.leadNotExists");
        action.setParams({
            "leadId" : leadId,
            "selectedRating": selectedRating,
            "remark": siteVisitComments,
            "salesUser": component.get("v.salesUserId")
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