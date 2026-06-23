({
    doInit : function(component, event, helper) {
        
        var recordId = component.get("v.recordId");
        var action = component.get("c.getBookingDetails");
        action.setParams({
            "recordId": recordId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var booking = result.booking;
                if (!booking) {
                    console.error("Booking data is missing!");
                    return;
                }
                if(booking.Total_received_Amount__c < booking.Agreement_Execution_Amount__c){
                 var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": 'error',
                        "title": 'Payment Pending',
                        "message": 'Customer has not yet payed the full agreement amount!',
                        "duration": 2000
                    });
                    toastEvent.fire();
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    console.error("Customer has not yet payed the full agreement amount!");
                    return;
                }else if(booking.Agreement_Expected_Date__c == null){
                     var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": 'error',
                        "title": 'Missing Expected Date',
                        "message": 'Agreement expected date is missing please update in the agreement section!',
                        "duration": 2000
                    });
                    toastEvent.fire();
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    console.error("Agreement expected date is missing please update in the agreement section!");
                    return;
                }
                
                var applicantName = result.customerNames;
                var agreementDueDate = helper.formatDate(booking.Agreement_Execution_Date__c); 
                var agreementExpectedDate = helper.formatDate(booking.Agreement_Expected_Date__c);
                var ProjectName = booking.Project1__r.Name;
                var PlotName = booking.Plot__r.Name;
                
                var defaultEmailContent = 
                    "<div style='color: black; font-family: Arial, sans-serif; line-height: 1.6;'>" +
                    "<p><strong>Dear " + applicantName + ",</strong></p><br/>" +
                    "<p><strong>Greetings from Zuari.</strong></p><br/>" +
                    "<p>This is a gentle reminder to confirm the date for signing the sale agreement concerning " +
                    "<strong>Plot/Unit No. " + PlotName + "</strong> at <strong>Zuari " + ProjectName + "</strong>. " +
                    "As per our previous correspondence, the final sale agreement is pending your confirmation. " +
                    "The <strong>Agreement Expected Date</strong> is <strong>" + agreementExpectedDate + "</strong> " +
                    "and the <strong>Agreement Due Date</strong> is <strong>" + agreementDueDate + "</strong>.</p><br/>" +
                    "<p>We kindly request you to confirm a suitable date for finalizing the agreement at your earliest convenience. " +
                    "Should you need any assistance or further clarification, please feel free to reach out. We are happy to assist you.</p><br/>" +
                    "<p>Thank you for your prompt attention to this matter.</p><br/>" +
                    "<p><strong>Warm regards,</strong><br/>Zuari Infraworld India Ltd.</p>" +
                    "</div>";
                                
                component.set("v.emailContent", defaultEmailContent);
            } else {
                console.error("Error retrieving record data");
            }
        });
        
        $A.enqueueAction(action);
    },
  
    sendEmail: function(component, event, helper) {
        console.log('Here in the sendEmail');
        const modifiedEmailContent =  component.get("v.emailContent");
        console.log('modifiedEmailContent'+modifiedEmailContent);
        console.log('Here in the sendEmail 1');
        var action = component.get("c.sendAgreementRequestMail");
        
        // Set the parameter for the Apex method - receiptId is passed from the component
        action.setParams({
            "recId": component.get("v.recordId"),
            "emailContent": modifiedEmailContent
        });
        console.log('Here in the sendEmail 3');
        // Set the callback function to handle the response from Apex
        action.setCallback(this, function(response) {
            var state = response.getState(); // Get the response state
            if (state === 'SUCCESS') {
                console.log('Here in the sendEmail 4');
                // Retrieve the return value from the Apex method
                var res_string = response.getReturnValue();
                
                // Stop the event propagation
                event.stopPropagation();
                
                // Close the quick action panel
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                
                // Determine the toast type based on the response
                var type = res_string === 'Email sent successfully' ? 'success' : 'error';
                
                // Show toast notification
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": type,
                    "title": type,
                    "message": res_string,
                    "duration": 10000
                });
                toastEvent.fire();
                
                // Refresh the view to reflect changes
                $A.get('e.force:refreshView').fire();
            } else if (state === 'ERROR') {
                console.log('Here in the sendEmail 5');
                // Handle error case
                console.log('Failed to send email: ', response.getError());
            }
        });
        
        // Enqueue the action to call the Apex method
        $A.enqueueAction(action);
    },
    close : function(component, event, helper) {
        event.stopPropagation();
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },
})