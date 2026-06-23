({
    doInit: function(component, event, helper){
		
    },
    handleSubmit: function(component, event, helper) {
        var status = component.get('v.SVStatus');
        
        event.preventDefault(); // Prevent the default form submission to handle it manually
        const eventFields = event.getParam("fields"); // Get the fields from the form
        var now = new Date();
        if (status === 'Rescheduled') {
            var rescheduleDate = component.find("Reschedule_Date__c").get("v.value");
            var rescheduleDateTime = new Date(rescheduleDate);
            if(!rescheduleDate)
            {
                helper.toastMsg('Error','Error','Please select reschedule date');
                return;
            }
            else if (rescheduleDateTime.getTime() < now.getTime()) {
                helper.toastMsg('Error','Error','Please select a future rescheduled date and time.');
                return;
            }
        }
        if (status === 'Scheduled') {
            var ScheduledDate = component.find("Date__c").get("v.value");
            var ScheduledDateTime = new Date(ScheduledDate);
            if(!ScheduledDate)
            {
                helper.toastMsg('Error','Error','Please select Scheduled date');
                return;
            }
            else if (ScheduledDateTime.getTime() < now.getTime()) {
                helper.toastMsg('Error','Error','Please select a future Scheduled date and time.');
                return;
            }
        }
        if (status === 'Completed') {
            var entryTime = component.find("entryTime").get("v.value");
            var entryDateTime = new Date(entryTime);
            
            var completedTime = component.find("completedTime").get("v.value");
            var completedDateTime = new Date(completedTime);
            
            // Check if ScheduledDate exists
            if (!entryTime) {
                helper.toastMsg('Error', 'Error', 'Please select site visit entry time');
                return;
            }
            else if(!completedTime)
            {
                helper.toastMsg('Error', 'Error', 'Please select site visit completed time');
                return;
            }
            
            // Today (date only)
            var today = new Date();
            today.setHours(0, 0, 0, 0);
            
            // Selected date (date only)
            var selectedDate = new Date(entryDateTime);
            selectedDate.setHours(0, 0, 0, 0);
            
            // Allow only today's DATE — time can be anything
            if (selectedDate.getTime() !== today.getTime()) {
                helper.toastMsg('Error', 'Error', 'Please select today’s date as the site visit entry time.');
                return;
            }
            
            
    
      
            
            // Selected date (date only)
            var selectedCompletedDate = new Date(completedDateTime);
            selectedCompletedDate.setHours(0, 0, 0, 0);
            
            // Allow only today's DATE — time can be anything
            if (selectedCompletedDate.getTime() !== today.getTime()) {
                helper.toastMsg('Error', 'Error', 'Please select today’s date as the site visit completed time.');
                return;
            }
            
        }
        
        component.set("v.isSubmitting", true); // Show the spinner while submitting
        if(status != null ){
            eventFields["Status__c"] = status;
        }
        component.find('myform').submit(eventFields); // Submit the form
        
    },

    handleSuccess: function(component, event, helper) {
        component.set("v.isSubmitting", false); // Hide the spinner after successful submission
        const recordId = component.get("v.recordId");
        $A.get("e.force:closeQuickAction").fire();
        
    },

    handleError: function(component, event, helper) {
        component.set("v.isSubmitting", false); // Hide the spinner after an error
        const errors = event.getParam("error");
        //alert('hello');
        console.log(JSON.stringify(errors));
        helper.toastMsg('Error', errors.message, 'Site Visit cannot be marked as Completed unless it has first been GRE Verified.'); // Show error message
    },

    closeModel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire(); // Close the modal after save or cancel
    },
    Status: function(component, event, helper){
        var status = event.getSource().get("v.value");
        component.set("v.status", status);
        
        // Get the record from attribute
        var siteVisitRecord = component.get("v.siteVisitRecord");
        
        // Only set value when status is Completed
        if (status === 'Completed') {
            var entryTimeField = component.find("entryTime");
            if (entryTimeField && siteVisitRecord && siteVisitRecord.Site_Visit_Entry_Time__c) {
                entryTimeField.set("v.value", siteVisitRecord.Site_Visit_Entry_Time__c);
            }
        }
        if (status === 'Scheduled') {
            var entryTimeField = component.find("Date__c");
            if (entryTimeField && siteVisitRecord && siteVisitRecord.Date__c) {
                entryTimeField.set("v.value", siteVisitRecord.Date__c);
            }
        }
    }

})