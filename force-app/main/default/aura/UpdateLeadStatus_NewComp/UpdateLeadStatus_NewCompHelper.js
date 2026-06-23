({
    updateLeadAndRelated : function(component, status, scheduleDate, selectedReason,othcomment,selectedOpenReason,selectedAlloctReason,svProposedDate) {
        const action = component.get("c.updateLeadWithStatus");
        action.setParams({
            leadId: component.get("v.recordId"),
            status: status,
            scheduleDate: scheduleDate,
            rating: selectedReason,
            openreason: selectedOpenReason,
            alloctreason: selectedAlloctReason,
            othercom : othcomment,
            budget : component.get("v.budgetChecked"),
            possession : component.get("v.possessionChecked"),
            configuration : component.get("v.configurationChecked"),
            location : component.get("v.locationChecked"),
            svProposedDate : svProposedDate
        });
        
        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                var responseMessage = response.getReturnValue();
                if(responseMessage == 'Updated Successully'){
                    
                    $A.get("e.force:showToast").setParams({
                        "title": "Success",
                        "message": "Lead Status Updated Successfully!",
                        "type": "success"
                    }).fire();
                    
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                    if(status=='Lost Lead' || status=='Closed Lost'){ 
                        window.location.href = '/lightning/o/Lead/home';
                    }
                }
                else if (responseMessage == 'Schduled_Visit_Existed'){
                    $A.get("e.force:showToast").setParams({
                        "title": "Error",
                        "message": 'Please complete the existing visit to schedule a new visit',
                        "type": "Error"
                    }).fire();
                }
                else if (responseMessage == 'SV_Proposed_Already_Exists'){
                    $A.get("e.force:showToast").setParams({
                            "title": "Error",
                        "message": 'Please complete the existing SV Proposed site visit before creating a new one',
                        "type": "Error"
                    }).fire();    
                }
                else if(responseMessage == 'Approved_Quation_Not_Existed')
                {
                    this.showToast("Error", "Cannot change status to Booked. Please ensure an approved quotation exists.", "error");
                }
                 else if(responseMessage == 'Booking_Not_Found')
                {
                    this.showToast("Error", "Cannot change status to Booked. Please ensure an booking exists.", "error");
                }
                else {
                    if (responseMessage.includes('Please select future date / time') || responseMessage.includes('Please enter future Date')) {
                        $A.get("e.force:showToast").setParams({
                            "title": "Error",
                            "message": 'Choose Future Date and Time',
                            "type": "Error"
                        }).fire();
                    }
                }
                
            } 
            else {
                let errors = response.getError();
                console.error(errors);
                
                let errorMsg = "Something went wrong.";
                if (errors && errors[0] && errors[0].message) {
                    errorMsg = errors[0].message;
                    
                    if (errorMsg.includes("Please select future date / time")) {
                        // Show validation toast if future date message
                        $A.get("e.force:showToast").setParams({
                            "title": "Error",
                            "message": errorMsg,
                            "type": "Error"
                        }).fire();
                        return;
                    }
                }
                
                // Default error toast
                $A.get("e.force:showToast").setParams({
                    "title": "Error",
                    "message": errorMsg,
                    "type": "error"
                }).fire();
            }
        });
        
        $A.enqueueAction(action);
    },
    
    updateCurrentStatus : function(component, event, helper, curLead){
        // alert(JSON.stringify(curLead))
        component.set('v.leadStatus',curLead.Lead_Status__c);
        component.set('v.selectedOpenReason',curLead.Open_Reason__c);
        component.set('v.selectedAllocatedReason',curLead.Allocated_Reason__c);
        component.set('v.budgetChecked',curLead.Budget_Qualified__c);
        component.set('v.possessionChecked',curLead.Possession__c);
        component.set('v.locationChecked',curLead.Location_Qualified__c);
        component.set('v.configurationChecked',curLead.Configuration__c);
        component.set('v.selectedReason',curLead.Lead_Lost_Reasons__c);
        
    } ,
    showToast : function(title, message, type) {
        const toast = $A.get("e.force:showToast");
        if (toast) {
            toast.setParams({
                title: title,
                message: message,
                type: type,
                mode: 'dismissible'
            });
            toast.fire();
        }
    }
})