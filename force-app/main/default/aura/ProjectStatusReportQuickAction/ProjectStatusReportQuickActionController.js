({
	doInit: function(component, event, helper) {
        component.set("v.isLoading", true);
        let action = component.get("c.getBookingRecord");
        action.setParams({ recordId: component.get("v.recordId")  });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.data", result.paymentSchdules);
                component.set("v.coApplicant", result.coApplicant);
                component.set("v.booking", result.booking);
                component.set("v.currentMilestone", result.currentMilestone);
                component.set("v.emailTemplateContent", result.template);
            } else {
                console.error("Error fetching data: ", response.getError());
            }
            component.set("v.isLoading", false);
        });
        
        $A.enqueueAction(action);
        
    },
    handleClosePopup : function(component, event, helper) {
		component.set("v.visible",false);
	},
    handleRadioSelection: function(component, event, helper) {
        const selectedIndex = parseInt(event.currentTarget.getAttribute('data-index'), 10);
        const selectedIndexId = event.currentTarget.getAttribute('value');
        const selectedMilestone = event.currentTarget.getAttribute('data-value');
       
        component.set("v.selectedIndexId", selectedIndexId);
        component.set("v.selectedMilestone", selectedMilestone);
        component.set("v.selectedIndex", selectedIndex);
        // Call generate logic after radio selection is set
        helper.generateDocument(component, event, helper);
    },

    handleSendProjectStatus: function(component, event, helper) {
        component.set("v.isLoading", true);
        var selectedIndexId =  component.get('v.milestoneId');
        var emailContent = component.get("v.emailContent");
        emailContent = emailContent.replace(/<p>(&nbsp;|\s)*<\/p>/g, '');
        emailContent = emailContent.replace(/(<br\s*\/?>\s*){2,}/g, '<br/>');
        var contentDocumentIds = component.get("v.filesIDS");
        console.log('contentDocumentIds'+JSON.stringify(contentDocumentIds)); 
        if(selectedIndexId){
            let action = component.get("c.sendPSREmail");
            action.setParams({
                "bookingId": component.get("v.recordId"),
                "paymentScheduleId": selectedIndexId,
                "messageBody": emailContent,
                "fileDocumentIds": contentDocumentIds
            });
            
            // Set the callback function to handle the response from Apex
            action.setCallback(this, function(response) {
                var state = response.getState(); // Get the response state
                component.set("v.isLoading", true);
                if (state === 'SUCCESS') {
                    console.log('here sucess');
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success",
                        "message": "Project Status Report send Successfully",
                        "type": "Success"
                    });
                    toastEvent.fire();
                    
                    // Close the quick action panel
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    // Refresh the view to reflect changes
                    $A.get('e.force:refreshView').fire();
                } 
                else if (state === 'ERROR') {
                    console.log('here Error');
                    // Handle error case
                    var errors = response.getError();
                    if (errors && Array.isArray(errors) && errors.length > 0) {
                        console.log('Error message: ' + errors[0].message);
                    } else {
                        console.log('Unknown error');
                    }
                }
                component.set("v.visible",false);
            });
            
            // Enqueue the action to call the Apex method
            $A.enqueueAction(action);
        }else{
            var toastEvent = $A.get("e.force:showToast");
            var type = 'error';
            toastEvent.setParams({
                "type": type,
                "title": type.charAt(0).toUpperCase() + type.slice(1), // Capitalize title
                "message": 'Please select a milestone',
                "duration": 10000
            });
            toastEvent.fire();
        }
    },
    handleFileUpload: function(component, event, helper) {
        var files = event.getParam("files");
        var getFiles = component.get("v.filesIDS");
        getFiles.push(...files);
        component.set('v.filesIDS',getFiles);
        
        var afercomit = component.get('v.filesIDS');
    },

})