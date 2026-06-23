({
    doInit : function(component, event, helper) {
        component.set('v.spinner',true);
        let action = component.get("c.getRecordTypeId");
        action.setParams({
            RecordId : component.get("v.recordId")// <-- Change based on your logic
        });
         action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                alert(response.getReturnValue())
                let recordTypeId = response.getReturnValue();
                component.set("v.recordTypeId", response.getReturnValue());
                
                   let picklistAction = component.get("c.getLeadStatusValues");
                picklistAction.setParams({ recordTypeId: recordTypeId });
                
                 picklistAction.setCallback(this, function(picklistResponse) {
                    if (picklistResponse.getState() === "SUCCESS") {
                        component.set("v.LeadStages", picklistResponse.getReturnValue());
                    } else {
                        console.error("Failed to fetch picklist values:", picklistResponse.getError());
                    }
                });

                $A.enqueueAction(picklistAction);
                
            } else {
                console.error("Failed to fetch RecordTypeId:", response.getError());
            }
        });

        $A.enqueueAction(action);
        
        helper.getFollowUps(component, event, helper);
        //helper.getProject(component, event, helper);
		helper.getAllocatedProject(component, event, helper);
        helper.getMissedFollowUps(component, event, helper);
       // helper.getFilteredLeadStages(component, event, helper);
        /*var action = component.get("c.getStatus");
        action.setParams({
            RecordId : component.get("v.recordId")
        });
         action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
     			//Handle success.
     			if(response.getReturnValue() == 'Site Visit'){
            		component.set('v.showFields',true);
                }else{
                    component.set('v.showFields',false);
                }
                if(response.getReturnValue() == 'SV Completed'){
            		component.set('v.showFields1',true);
                }else{
                    component.set('v.showFields1',false);
                }
            }
        });
        $A.enqueueAction(action); */
        
        
        const now = new Date();
        const istTime = new Date(now.getTime() + 5.5 * 60 * 60 * 1000); // Convert to IST
        const formattedDateTime = istTime.toISOString().slice(0, 19).replace('T', 'T'); // Keep datetime-local format
        component.set("v.FollowupCompletedDateTime", formattedDateTime);
    },
    FetchLeadData : function(component, event, helper) {
        component.set('v.spinner',true);
        var proj = component.get("v.leadsRecord.Allocated_Project__c");
        var leadNotIntersted = component.get("v.leadsRecord.Lead_not_interested__c");
        component.set("v.leadlost",component.get("v.leadsRecord.Closed_Lost_Reason__c"));
        //alert(component.get("v.leadsRecord.Lead_Stage__c"));
        component.set("v.leadStatus",component.get("v.leadsRecord.Lead_Status__c"));
        //alert(component.get("v.leadStatus"));
        //alert('leadNotIntersted '+leadNotIntersted);
        if(leadNotIntersted == true && component.get("v.leadsRecord.Lead_Status__c") == 'SV Completed'){
           component.set('v.FollowUpRequired',false);
        }
        else if(component.get("v.leadsRecord.Lead_Status__c") == 'Site Visit Schedule' || component.get("v.leadsRecord.Lead_Status__c") == 'Closed Lost' || component.get("v.leadsRecord.Lead_Stage__c") == 'Negotiation'){
           component.set('v.FollowUpRequired',false); 
        }
        else{
            component.set('v.FollowUpRequired',true);
        }
        //alert('Hello '+component.get("v.project"));
        //alert(component.get("v.project1"));
        if(proj != undefined && component.get("v.project") == undefined){
            component.set("v.project",proj);
        }
        component.set('v.spinner',false);
    },
    handleError: function (cmp, event, helper) {
        cmp.set('v.spinner',true);
        //alert('error');
        var error = event.getParams();
        // Get the error message
        let errorMessage = event.getParam("message");
        let errorMessages = event.getParam("detail");
        //alert(errorMessages);
        //alert(errorMessage);
        console.log('errorMessage'+errorMessage);
        console.log('errorMessages'+errorMessages);
        if(errorMessage.includes('resource does not exist') || errorMessage.includes('do not have the level of access') || errorMessage.includes('insufficient access')){
            cmp.set('v.spinner',false);
            var homeEvt = $A.get("e.force:navigateToObjectHome");
            homeEvt.setParams({
                "scope": "Lead"
            });
            homeEvt.fire(); 
        }
        else if(errorMessages.includes('Please change Scheduled SiteVist status as Completed or Cancelled for Previous SV'))
        {
            helper.Toast('ERROR', 'Error', 'Please change Scheduled SiteVist status as Completed or Cancelled for Previous SV');
            /*var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": "Please change Scheduled SiteVist status as Completed or Cancelled for Previous SV",
                "type":"Error"
            });
            toastEvent.fire();*/
        }
            else if(errorMessages.includes('Choose Future Date and Time'))
            {
                helper.Toast('ERROR', 'Error', 'Choose Future Date and Time');
                /*var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "Choose Future Date and Time",
                    "type":"Error"
                });
                toastEvent.fire(); */
            }else if(errorMessages.includes('Please create followup record before changing stage to analysis.'))
            { 
                helper.Toast('ERROR', 'Error', 'Please create followup record before changing stage to analysis.');
                /*var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "Please create followup record before changing stage to analysis.",
                    "type":"Error"
                });
                toastEvent.fire(); */
                cmp.set('v.spinner',false);
                
                
            }
        else if(errorMessages.includes('Please enter the correct name.'))
            { 
                helper.Toast('ERROR', 'Error', 'Please enter the correct name.');
                /*var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "Please enter the correct name.",
                    "type":"Error"
                });
                toastEvent.fire(); */
                cmp.set('v.spinner',false);
                
                
            }
                else{
                    helper.Toast('ERROR', 'Error', errorMessages);
                    /*var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": errorMessages,
                        "type":"Error"
                    });
                    toastEvent.fire();*/
                }
        cmp.set('v.spinner',false);
    },
    handleLoad: function(component, event, helper) {
        /*var status = component.find('leadStatus').get('v.value');
        component.set('v.leadStatus',status);*/
        component.set('v.spinner',false);
    },
    handleOnSubmit : function(component, event, helper) {
        component.set('v.spinner',true);
        /*var proj = component.get("v.leadsRecord.Allocated_Project__c");*/
        var leadStatus = component.get('v.leadStatus');
        event.preventDefault();   
        var eventFields = event.getParam("fields");
        if(leadStatus != null)
        {
            eventFields["Lead_Status__c"] = leadStatus;
        }
        component.find('myform').submit(eventFields);
    },
   
   handleSuccess : function(component,event,helper) {
        component.set('v.spinner',true);
        //$A.get("e.force:closeQuickAction").fire();
        //alert(component.get("v.recordId"))
        var recId = component.get("v.recordId");
        var ButtonValue = component.get("v.ButtonValue");
        var leadStatus = component.get("v.leadStatus") || component.get("v.leadsRecord.Lead_Status__c");
      //  alert(leadStatus)
        // Function to handle the follow-up updates
        function handleFollowUpUpdate(responseMessage) {
            if (!responseMessage) {
                helper.Toast('SUCCESS', 'Success', 'Record Updated');
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
                component.set('v.spinner',false);
            } else if (responseMessage.includes('Choose Future Date and Time')) {
                helper.Toast('ERROR', 'Error', 'Choose Future Date and Time');
                component.set('v.spinner',false);
            } else {
                helper.Toast('ERROR', 'Error', responseMessage);
                $A.get("e.force:closeQuickAction").fire();
                component.set('v.spinner',false);
            }
        }
        //alert('Success '+leadStatus);
        // Handle different lead statuses
        if (['RNR', 'Pre Sales Follow Up'].includes(leadStatus)) {
            var UpdateLeadStatus = true;
            var action1 = component.get("c.UpdateFollowUps");
            action1.setParams({
                recId: recId,
                ButtonValue: ButtonValue,
                UpdateLeadStatus: UpdateLeadStatus
            });
            action1.setCallback(this, function (response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    
                    handleFollowUpUpdate(response.getReturnValue());
                } else {
                    helper.Toast('ERROR', 'Error', 'Something went wrong');
                    $A.get("e.force:closeQuickAction").fire();
                    component.set('v.spinner',false);
                }
            });
            $A.enqueueAction(action1);
        } else if (['Site Visit Schedule', 'SV Completed'].includes(leadStatus)) {
            //alert(component.get("v.projectList[0]"));
            let projectName = component.get("v.projectList[0]");
            if(component.get("v.SelectedProject") == '' && projectName != ''){
              component.set("v.SelectedProject",projectName);  
            }
            var action = component.get("c.createALog");
            action.setParams({
                RecordId: recId,
                Project: component.get("v.SelectedProject"),
                status: leadStatus
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                //alert(state);
                if (state === 'SUCCESS') {
                    //alert('hi');
                    var responseMessage = response.getReturnValue();
                    if (responseMessage === 'success') {
                        //alert('hello');
                        var UpdateLeadStatus = true;
                        var action2 = component.get("c.UpdateFollowUps");
                        action2.setParams({
                            recId: recId,
                            ButtonValue: ButtonValue,
                            UpdateLeadStatus: UpdateLeadStatus
                        });
                        action2.setCallback(this, function (response) {
                            var state = response.getState();
                            if (state === 'SUCCESS') {
                                //handleFollowUpUpdate(null);
                                handleFollowUpUpdate(response.getReturnValue());
                            } else {
                                helper.Toast('ERROR', 'Error', 'Something went wrong');
                                $A.get("e.force:closeQuickAction").fire();
                                 component.set('v.spinner',false);
                            }
                        });
                        $A.enqueueAction(action2);
                        
                    } else {
                        if (responseMessage.includes('Choose Future Date and Time') || responseMessage.includes('Please enter future Date')) {
                            helper.Toast('ERROR', 'Error', 'Choose Future Date and Time');
                             component.set('v.spinner',false);
                        }
                    }
                } else if (state === 'ERROR') {
                    helper.Toast('ERROR', 'Error', 'Something went wrong');
                    $A.get("e.force:closeQuickAction").fire();
                     component.set('v.spinner',false);
                }
            });
            $A.enqueueAction(action);
        }else{
            helper.Toast('SUCCESS','Success','Record Updated');
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
            component.set('v.spinner',false);
        }
        //alert('success');
        
    },
    doCancel: function (component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
    },
    onLeadChange : function(component, event, helper){
        component.set('v.spinner',true);
        //alert('hello');
        component.set('v.leadlost','');
        //alert('Status'+event.getSource().get("v.value"));
        component.set('v.leadStatus',event.getSource().get("v.value"));
         var ldstatus = component.get("v.leadStatus");
        
       /*  if(ldstatus=='Analysis'){
              var recId = component.get("v.recordId");
             var action = component.get("c.checkfollowUp");
            action.setParams({ RecordId: recId  });
           action.setCallback(this, function (response) {
                var state = response.getState();
               
               if(state == 'SUCCESS') {
                   if(response.getReturnValue() == 'Yes'){
                       
                        component.set('v.analysissec',false);
                   }
                   else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!",
                            "message": "Please create followup record before changing stage to analysis.",
                            "type":"Error"
                        });
                        toastEvent.fire(); 
                        component.set('v.spinner',false);
                        component.set('v.analysissec',true);
                       
                   }
               }
           });
            $A.enqueueAction(action);
          
        }
       */
        if(component.get("v.leadsRecord.Lead_not_interested__c") == true && component.get("v.leadStatus") == 'SV Completed'){
           component.set('v.FollowUpRequired',false);
        }
        else if(component.get("v.leadStatus") == 'Closed Lost' || component.get("v.leadStatus") == 'SV Schedule' || component.get("v.leadStatus") == 'Negotiation'){
            component.set('v.FollowUpRequired',false);
        }
        else{
            component.set('v.FollowUpRequired',true);
        }
        var leadStatus1 = event.getSource().get("v.value");
        if(leadStatus1 == 'Invalid' || leadStatus1 =='Site Visit' || leadStatus1 == 'Lost'){
            component.set('v.showFields2',false);
        }
        else{
            component.set('v.showFields2',true); 
        }
        component.set('v.spinner',false);
    },
    onLeadlost : function(component, event, helper){
        component.set('v.spinner',true); 
        component.set('v.leadlost',event.getParam('value'));
        //var leadlost1 = event.getParam('value');
        component.set('v.spinner',false);
    },
    onProjectChange: function(component, event, helper){
        //alert('change'+event.getSource().get("v.value"));
        component.set('v.spinner',true); 
        component.set('v.SelectedProject',event.getSource().get("v.value"));
        //component.set('v.project1',event.getSource().get("v.value"));
        component.set('v.spinner',false);
    },
    /*handleUploadAdhar: function (cmp, event) {
        var uploadedFiles = event.getParam("files");
        var recordId = cmp.get("v.recordId");
        for (var i = 0; i < uploadedFiles.length; i++) {
            var uploadedFile = uploadedFiles[i];
            
            var fileName = 'Aadhar_' + uploadedFile.name; // Use a unique identifier, for example, index + 1
            
            // Call the server-side controller method to update the file name
            var action = cmp.get("c.updateFileName");
            action.setParams({
                fileId: uploadedFile.documentId,
                newFileName: fileName
            });
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    console.log('File name updated successfully: ' + fileName);
                } else {
                    console.error('Error updating file name: ' + response.getError()[0].message);
                }
            });
            
            $A.enqueueAction(action);
        }
        
        
        // Get the file name
        uploadedFiles.forEach(file => console.log(file.name));
    },
    handleUploadPAN: function (cmp, event) {
        var uploadedFiles = event.getParam("files");
        
        var recordId = cmp.get("v.recordId");
        for (var i = 0; i < uploadedFiles.length; i++) {
            var uploadedFile = uploadedFiles[i];
            
            var fileName = 'PAN_' + uploadedFile.name; // Use a unique identifier, for example, index + 1
            
            var action = cmp.get("c.updateFileName");
            action.setParams({
                fileId: uploadedFile.documentId,
                newFileName: fileName
            });
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    console.log('File name updated successfully: ' + fileName);
                } else {
                    console.error('Error updating file name: ' + response.getError()[0].message);
                }
            });
            
            $A.enqueueAction(action);
        }
        
        
        // Get the file name
        uploadedFiles.forEach(file => console.log(file.name));
    },
    NewhandleClick: function(component,event,helper){
        //alert('new');
        component.set("v.ActiveDiv",false);
       // component.set("v.Status",'Scheduled');
        component.set('v.VarientValue',"brand");
        component.set('v.VarientValues',"neutral");
        component.set('v.ButtonValue',"New Follow Up");
        //alert(component.get("v.Status"));
    },
    UpdatehandleClick: function(component,event,helper){
        //alert('Update');
        component.set("v.ActiveDiv",true);
      //  component.set("v.Status",'Completed'); 
        component.set('v.VarientValue',"neutral");
        component.set('v.VarientValues',"brand");
        component.set('v.ButtonValue',"Update Follow Up");
        //alert(component.get("v.Status"));
    },*/
    FollowUpComments: function (component, event, helper){
      //alert(event.getParam('value'));  
        if(event.getParam('value') == 'Other Option'){
            component.set('v.FollowUpOther',true);
        }
        else{
            component.set('v.FollowUpOther',false);
        }
    },
    LeadNotIntersted: function(component, event, helper){
      //alert(event.getParam('value'));  
        if(event.getParam('value') == true && component.get('v.leadStatus')=='SV Completed'){
           component.set('v.FollowUpRequired',false);
        }
        else{
            component.set('v.FollowUpRequired',true);
        }
    }
    /*validateDateTime: function (component, event, helper) {
        var selectedDate = component.get("v.selectedDate");
        var selectedTime = component.get("v.selectedTime");

        // Validate if both date and time are selected
        if (selectedDate && selectedTime) {
            var currentDate = new Date();
            var selectedDateTimeString = selectedDate + 'T' + selectedTime;
            var selectedDateTime = new Date(selectedDateTimeString);

            if (selectedDateTime > currentDate) {
                // The selected datetime is in the future
                console.log("Selected datetime is in the future.");
                // You can perform additional actions or show a success message here
            } else {
                // The selected datetime is not in the future
                console.error("Selected datetime must be in the future.");
                // You can display an error message to the user
            }
        } else {
            // Handle the case where either date or time is not selected
            console.error("Please select both date and time.");
            // You can display an error message to the user
        }
    }*/
})