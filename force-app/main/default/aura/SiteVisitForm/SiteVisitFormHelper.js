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

    // ---------- Shared post-identification flow (Search Lead AND Search Lead with QR) ----------
    // leadDetailsString is the JSON returned by checkLeadWithPhoneProject / checkLeadFromScan.
    handleLeadResult : function(component, leadDetailsString) {
        var helper = this;
        var leadDetails = JSON.parse(leadDetailsString);
        var otpStatus = leadDetails.leadStatus;
        component.set("v.leadName", leadDetails.leadname);
        component.set("v.phonenumer", leadDetails.phone);
        component.set("v.otpStatus", leadDetails.leadStatus);
        component.set("v.leadId", leadDetails.leadId);
        component.set("v.siteVisitComments", '');
        component.set("v.selectedRating", 'None');
        component.set("v.salesUserId", '');
        component.set("v.salesUserSearchText", '');
        component.set("v.searchedSalesUsers", []);
        if (otpStatus === 'Active Lead Exist' || otpStatus === 'Lead exists but In-Active') {
            var action1 = component.get("c.getLead");
            action1.setParams({ "leadId": leadDetails.leadId });
            action1.setCallback(this, function(response) {
                component.set("v.isLoading", false);
                if (response.getState() === "SUCCESS") {
                    component.set("v.showDetails", true);
                    var returnValue = response.getReturnValue();
                    component.set("v.leadRecord", returnValue.Lead);
                    component.set("v.siteVisit", returnValue.siteVisit);
                    if (otpStatus === 'Active Lead Exist') {
                        helper.toastMsg('Success', 'Lead Status', 'Active Lead Exist');
                    } else {
                        helper.toastMsg('Success', 'Lead Status', 'Lead exists but In-Active');
                    }
                }
            });
            $A.enqueueAction(action1);
        } else if (otpStatus === 'No Lead Exists') {
            component.set("v.showDetails", true);
            component.set("v.isLoading", false);
            helper.toastMsg('Error', 'Lead Status', 'No Lead Exists');
        } else {
            component.set("v.isLoading", false);
        }
    },

    errMsg : function(response, fallback) {
        var errs = response.getError();
        if (errs && errs[0] && errs[0].message) { return errs[0].message; }
        return fallback;
    },

    // Shared reset for both the Search Lead and Search Lead with QR "Clear" actions.
    clearAll : function(component) {
        component.set("v.selectedProject", 'None');
        component.set("v.phone", '');
        component.set("v.qrScanValue", '');
        component.set("v.showDetails", false);
        component.set("v.otpStatus", null);
        component.set("v.leadRecord", {});
        component.set("v.leadId", null);
        component.set("v.siteVisit", {});
        component.set("v.siteVisitComments", '');
        component.set("v.selectedRating", 'None');
        component.set("v.salesUserId", '');
        component.set("v.salesUserSearchText", '');
        component.set("v.searchedSalesUsers", []);
        component.set("v.qrShowDetails", false);
        component.set("v.qrError", null);
        component.set("v.isLoading", false);
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