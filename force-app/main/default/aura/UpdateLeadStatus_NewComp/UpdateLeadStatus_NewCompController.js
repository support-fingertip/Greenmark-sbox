({
    doInit: function(component, event, helper) {
        var action = component.get("c.getLeadRecordTypeName");
        action.setParams({ leadId: component.get("v.recordId") });
        
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.recordTypeName", result.recordTypeName);
                component.set("v.openReasons", result.openReason);
                component.set("v.qualifiedReasons", result.qualificationReason);
                component.set("v.leadLostReasons", result.leadLostReason);
                component.set("v.closedLostReasons", result.closedLostReason);
                component.set("v.quotationReasons", result.quatationReason);
                component.set("v.leadRecord", result.curLead);
                component.set("v.callCount", result.callCount);

                let statusOptions = [];
                if (result.recordTypeName === "Pre Sales") {
                    statusOptions = ["Open", "Pre Sales Follow Up", "Qualified", "SV Scheduled", "Lead Lost"];
                } else {
                    statusOptions = ["SV Scheduled", "Sales Follow up", "Quotation", "Booked", "Closed Lost"];
                }
                component.set("v.statusOptions", statusOptions);
                setTimeout($A.getCallback(() => {
                    helper.updateCurrentStatus(component, event, helper, result.curLead);
                }), 0);
                
                var now = new Date();
                var iso = now.toISOString().slice(0,16); // remove seconds + Z
                component.set("v.currentTime", iso);
                
                
                

            } else {
                helper.showToast("Error", "Failed to load record type name", "error");
            }
        });
        
        $A.enqueueAction(action);
    },
    
    handleStatusChange : function(component, event, helper) {
        component.set("v.scheduleDate", null);
        component.set("v.rating", null);
    },
    
    handleSubmit : function(component, event, helper) {
        const status = component.get("v.leadStatus");
        const scheduleDate = component.get("v.scheduleDate");
        const selectedReason = component.get("v.selectedReason");
        const selectedOpenReason = component.get("v.selectedOpenReason");
        const selectedAlloctReason = component.get("v.selectedAllocatedReason");
        const othcomment = component.get("v.comment");
        const svProposedDate = component.get("v.svProposedDateTime");

        // Basic required validations
        if (!status) {
            helper.showToast("Error", "Please select a Lead Status.", "error");
            return;
        }

        if (status === 'Open' && !selectedOpenReason) {
            helper.showToast("Error", "Please select open reason", "error");
            return;
        }

        if ((status === 'Pre Sales Follow Up' || status === 'Sales Follow up') && !scheduleDate) {
            helper.showToast("Error", "Please select Follow Up Date " + status, "error");
            return;
        }

        if ((status === 'Pre Sales Follow Up' || status === 'Sales Follow up') && !othcomment) {
            helper.showToast("Error", "Please enter subject", "error");
            return;
        }

        if (status === 'SV Scheduled' && !othcomment) {
            helper.showToast("Error", "Please enter comments", "error");
            return;
        }

        if (status === 'Lead Lost' && !selectedReason) {
            helper.showToast("Error", "Please select Lead Lost Reason", "error");
            return;
        }

        // Qualified Logic
        if (status === 'Qualified') {
            const budget = component.get("v.budgetChecked");
            const possession = component.get("v.possessionChecked");
            const location = component.get("v.locationChecked");
            const configuration = component.get("v.configurationChecked");

            let selectedCount = 0;
            if (budget) selectedCount++;
            if (possession) selectedCount++;
            if (location) selectedCount++;
            if (configuration) selectedCount++;

            component.set("v.leadQualificationRating", selectedCount);

            if (selectedCount < 3) {
                helper.showToast("Error", "Please select at least 3 out of 4 lead qualification factors.", "error");
                return;
            }

            // SV Proposed validations inside Qualified only
            if (selectedAlloctReason === 'SV Proposed') {
                if (!svProposedDate) {
                    helper.showToast("Error", "Please select SV Proposed Date/Time", "error");
                    return;
                }

                var selectedDT = new Date(svProposedDate);
                var now = new Date();

                if (selectedDT.getTime() < now.getTime()) {
                    helper.showToast("Error", "SV Proposed Date & Time must be in the future.", "error");
                    return;
                }
            }
        }
        
         if (status === 'SV Scheduled') {
             if (!scheduleDate) {
                 helper.showToast("Error", "Please select schedule date", "error");
                 return;
             }
             
             var selectedDT = new Date(scheduleDate);
             var now = new Date();
             
             if (selectedDT.getTime() < now.getTime()) {
                 helper.showToast("Error", "Schedule date must be in the future.", "error");
                 return;
             }
         }

        if (status === 'Quotation' && !selectedReason) {
            helper.showToast("Error", "Please select Quotation Reason", "error");
            return;
        }

        // If everything is OK → call Apex
        helper.updateLeadAndRelated(
            component,
            status,
            scheduleDate,
            selectedReason,
            othcomment,
            selectedOpenReason,
            selectedAlloctReason,
            svProposedDate
        );
    },

    handleCheckboxChange: function(component, event, helper) {
        const name = event.getSource().get("v.name");
        const checked = event.getSource().get("v.checked");
        component.set("v." + name.toLowerCase() + "Checked", checked);
    },

    handleCancel : function(component, event, helper) {
        component.set("v.isOpen", false);
        $A.get("e.force:closeQuickAction").fire();
    },

    handleReasonChange: function(component, event, helper) {
        var selectedValue = event.getSource().get("v.value");
        component.set("v.selectedReason", selectedValue);
    },
    
    handleclosedReasonChange : function(component, event, helper) {
        var selectedReason = component.get("v.selectedReason");
        var curLead = component.get("v.leadRecord");
        var callCount = component.get("v.callCount");
       // alert(selectedReason)
        if(selectedReason == 'RNR'){
            
           // alert(curLead.No_Of_Times_Unqualified__c);
            //alert(curLead.callCount);
            
            if((curLead.Lead_Status__c == 'New' || curLead.Lead_Status__c == 'Open') && 
               (curLead.No_Of_Times_Unqualified__c == 0 && callCount < 7) || 
               curLead.No_Of_Times_Unqualified__c == 1 && callCount < 5){
                helper.showToast("Unable to update Lead Lost", "Not enough Calls found!", "error");
                
                component.set("v.isOpen", false);
                $A.get("e.force:closeQuickAction").fire();
                return;
                
            }
             
            
        }
        var reasonsRequiringDetail = [
            'Vaastu Concern','Dimension','Loan Eligibility','Duplicate Lead','Already Allocated',
            'Booked With Competitor','Booked With Zuari','Not A Valid Customer','Not In Location',
            'Not In Size','Not Interested','CP Clash','Junk Leads'
        ];
        
        var showDetail = reasonsRequiringDetail.includes(selectedReason);
        component.set("v.showDetailReason", showDetail);
    }
})