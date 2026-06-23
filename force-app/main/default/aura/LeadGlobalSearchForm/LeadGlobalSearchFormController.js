({
    checkLead : function(component, event, helper) {

        var phone = component.get("v.phone");

        if(!phone){
            helper.toastMsg('Error','Error','Please enter the Name/Phone/Email/Lead Id.');
            return;
        }
        component.set("v.showDetails", false);
        component.set("v.isLoading", true);
        
        var action = component.get("c.checkLeadWithPhoneProject");
        action.setParams({"searchText": phone });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var leadDetailsString = response.getReturnValue();
                var leadDetails = JSON.parse(leadDetailsString);
                var otpStatus = leadDetails.leadStatus;
                component.set("v.leadName", leadDetails.leadname);
                component.set("v.phonenumer", leadDetails.phone);
                component.set("v.otpStatus", leadDetails.leadStatus);
                component.set("v.leadId", leadDetails.leadId);
                component.set("v.selectedRating", 'None');
                if(otpStatus == 'Active Lead Exist' || otpStatus == 'Lead exists but In-Active'){ 
                    var action1 = component.get("c.getLead");
                    action1.setParams({ "leadId": leadDetails.leadId});
                    action1.setCallback(this, function(response) {
                        var state = response.getState();
                        if (state === "SUCCESS") {
                             component.set("v.showDetails",true);
                            component.set("v.isLoading", false);
                            var returnValue = response.getReturnValue()
                            component.set('v.leadRecord',returnValue.Lead);
                            component.set('v.siteVisit',returnValue.siteVisit);
              


                            if(otpStatus == 'Active Lead Exist'){
                                helper.toastMsg('Success','Lead Status','Active Lead Exist');
                            }
                            if (otpStatus == 'Lead exists but In-Active') {
                                helper.toastMsg('Success', 'Lead Status', 'Lead exists but In-Active');
                            }
                            
                        }
                    });
                    $A.enqueueAction(action1);
                }
                else if(otpStatus == 'No Lead Exists'){
                     component.set("v.showDetails",true);
                    component.set("v.isLoading", false);
                    helper.toastMsg('Error','Lead Status','No Lead Exists');
                }
            }
        });
        $A.enqueueAction(action);
    },
    clearValues : function(component, event, helper) {
        component.set("v.selectedProject",'None');
        component.set("v.phone",'');
        component.set("v.showDetails",false);
        component.set("v.otpStatus",null);
        component.set("v.siteVisitComments", '');
        component.set("v.selectedRating", 'None');
    },
    cancel : function(component, event, helper) {
        component.set("v.selectedProject",'None');
        component.set("v.phone",'');
        component.set("v.datevalue",null);
        component.set("v.showDetails",false);
        component.set("v.otpStatus",null);
        component.set("v.siteVisitComments", '');
        component.set("v.selectedRating", 'None');
        component.set("v.tabId", "1");
    },
    openLead : function(component, event, helper) {
        var leadId = event.currentTarget.getAttribute("data-id");
        
        var url = '/lightning/r/Lead/' + leadId + '/view';
        window.open(url, '_blank');
    }
})