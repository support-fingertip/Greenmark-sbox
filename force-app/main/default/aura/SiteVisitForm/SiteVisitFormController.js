({
    doInit : function(component, event, helper) {
        var action = component.get("c.getData");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                component.set("v.projects", data.projects);
                component.set("v.siteVisitRatings", data.siteVisitRatings);
                component.set("v.sourceToSubSoruce", data.sourceToSubSoruce);
                component.set("v.sectionLabels", data.countryMap);
                component.set("v.channelPartnerList", data.channelPatnerList);
                component.set("v.cpExectiveList", data.CpUsersList);
            }
        });
        $A.enqueueAction(action);
        
    },
    checkLead : function(component, event, helper) {
    
        var selectedProject = component.get("v.selectedProject");
        var phone = component.get("v.phone");
        if(!selectedProject || selectedProject == 'None'){
            helper.toastMsg('Error','Error','Please Select Project');
            return;
        }
        if(!phone){
            helper.toastMsg('Error','Error','Please enter the Phone/Email/Lead Id.');
            return;
        }
        component.set("v.showDetails", false);
        component.set("v.isLoading", true);
        
        var action = component.get("c.checkLeadWithPhoneProject");
        action.setParams({ "project_name": selectedProject, "searchText": phone });
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
                component.set("v.siteVisitComments", '');
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
        component.set("v.leadId",'');
    },
    handleCountryChange: function(component, event, helper) {
        var selectedUnitId = component.find("CountryLookupField").get("v.value");
        var countryMap = component.get("v.sectionLabels");
        var selectedCountryCode = countryMap[selectedUnitId];
        component.set("v.selectedCountryCode", selectedCountryCode);
    },
    handleLeadSourceChange: function(component, event, helper) {
        var selectedSource = component.get("v.selectedSource");
        var sourceToSubSoruce = component.get("v.sourceToSubSoruce");
        component.set("v.selectedSubSource", 'None');
        
        if (selectedSource && sourceToSubSoruce && sourceToSubSoruce[selectedSource]) {
            // inner map: { "Search Ads" : "Search_Ads", "Display Ads" : "Display_Ads" }
            var subSourceMap = sourceToSubSoruce[selectedSource];
            var subSources = [];
    
            // Extract labels (keys) as list
            for (var label in subSourceMap) {
                subSources.push(label);
            }
    
            component.set("v.SubSourceList", subSources);
            // select default value AFTER list is updated
            if (selectedSource === "Channel Partner") {
                setTimeout(function(){
                    component.set("v.selectedSubSource", "Channel Partner");
                }, 0);
            }
            
        } else {
            component.set("v.SubSourceList", []); // reset if nothing found
        }
    },
    
    handleError: function (component, event, helper) {
        component.set("v.isLoading", false);
        
        var errorMessage = event.getParam("message");
        if (errorMessage === 'The requested resource does not exist') {
            
            
            var leadId = component.get("v.leadId");
            if(leadId != null && leadId != '')
            {
                console.log('leadId---'+leadId);
                helper.createSitevisit(component,event, helper,leadId);
            }
            helper.toastMsg('error', 'Duplicate', 'Lead already exists in the system');
            component.set("v.selectedProject",'None');
            component.set("v.phone",'');
            component.set("v.showDetails",false);
            component.set("v.otpStatus",null);
            component.set("v.siteVisitComments", '');
            component.set("v.selectedRating", 'None');
            component.set("v.tabId", "1");
        } else {
            helper.toastMsg('error', 'Error', errorMessage);
        }
    },

    handleSubmit : function(component, event, helper) {
        event.preventDefault();
        var leadName = component.find("leadName").get("v.value");
        var leadFirstName = component.find("leadFirstName").get("v.value");
        var salutation = component.find("salutation").get("v.value");
        const primaryphone =component.get("v.phone");
        var pattern = /^[A-Za-z ]+$/;
        var numberPattern = /^[0-9]+$/;
        var siteVisitComments = component.get("v.siteVisitComments");
        var selectedRating = component.get("v.selectedRating");
        var selectedSource = component.get("v.selectedSource");
        var selectedSubSource = component.get("v.selectedSubSource");
        var otpStatus = component.get("v.otpStatus");
        
        var primaryPhone = component.find("PhoneNumber").get("v.value");
        var secondaryPhone = component.find("secondPhoneNumber").get("v.value");
        var leadSource = component.get("v.selectedSubSource");
        
        var localitofCustomer = component.find("localitofCustomer").get("v.value");
        var companyNameOfCustomer = component.find("companyNameOfCustomer").get("v.value");
        
        
        if(!pattern.test(leadName)|| !pattern.test(leadFirstName)) {
            component.set("v.isSubmitting", false);
            helper.toastMsg('Warning','Name','Please enter alphabets only in Name!');
            return; // Do not submit if invalid
        }
        if (!salutation) {
            component.set("v.isSubmitting", false);
            helper.toastMsg('Warning', 'Salutation', 'Please select a Salutation!');
            return;
        }
        if (!siteVisitComments ) {
            helper.toastMsg('Error', 'Error', 'Please enter Site Visit Comments');
            return;
        } 
        if ((!selectedRating || selectedRating =='None') && (otpStatus == "Active Lead Exist")) {
            helper.toastMsg('Error', 'Error', 'Please select Site Visit Rating');
            return;
        }
        if (!selectedSource || selectedSource =='None') {
            helper.toastMsg('Error', 'Error', 'Please select Lead Source');
            return;
        }
        if (!selectedSubSource || selectedSubSource =='None') {
            helper.toastMsg('Error', 'Error', 'Please select Lead Sub Source');
            return;
        }
        
        // Validate primary phone (only numbers)
        if (primaryPhone && (!numberPattern.test(primaryPhone) || primaryPhone.length != 10)) {
          
            helper.toastMsg('Error', 'Primary Phone', 'Please enter a valid 10-digit primary phone number');
            return;
        }
        
        // Validate secondary phone (only numbers)
        if (secondaryPhone && (!numberPattern.test(secondaryPhone) || secondaryPhone.length != 10)) {
           
            helper.toastMsg('Error', 'Secondary Phone', 'Please enter a valid 10-digit secondary phone number');
            return;
        }
        
        if(leadSource =='Channel Partner' )
        {
            var sourcingMember = component.find("sourcingMember").get("v.value");
            if(!sourcingMember)
            {
                helper.toastMsg('Error', 'Sourcing Member', 'Please select sourcing member');
                return;
            }
        }
        if(leadSource =='Channel Partner')
        {
             var channelPartner = component.find("channelPartner").get("v.value");
            if(!channelPartner)
            {
                helper.toastMsg('Error', 'Channel Partner', 'Please select Channel Partner');
                return;
            }
        }
        if (!localitofCustomer ) {
            helper.toastMsg('Error', 'Error', 'Please enter Locality of Customer');
            return;
        } 
        if (!companyNameOfCustomer ) {
            helper.toastMsg('Error', 'Error', 'Please enter Company Name of Customer');
            return;
        } 
        
        component.set("v.isLoading", true);
        
        var eventFields = event.getParam("fields");

        eventFields["Country_Code__c"] = component.get('v.selectedCountryCode');
        eventFields["Source_Type__c"] = selectedSource;
        eventFields["Lead_source__c"] = selectedSubSource;
        eventFields.LastName = leadName;
        eventFields.FirstName = leadFirstName;
        eventFields.Salutation = salutation;
        eventFields.Walking_Lead_Form__c = true;
        
        component.find('myform').submit(eventFields);
        
    },
    handleSuccess : function(component, event, helper) {
        console.log('entered');
        var record = event.getParam("response");
        var apiName = record.apiName;
        var myRecordId = record.id;
        var siteVisitComments = component.get("v.siteVisitComments");
        var selectedRating = component.get("v.selectedRating");
        
        var action = component.get("c.leadNotExists");
        action.setParams({
            "leadId" : myRecordId,
            "selectedRating": selectedRating,
            "remark": siteVisitComments
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                component.set('v.isLoading',false);
                helper.toastMsg('Success','Success','Lead created successfully');
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
        
    },
    svWithLead : function(component, event, helper) {
        
        // Retrieve values
        var dateValue = component.get("v.datevalue");
        var project = component.get("v.selectedProject");
        var siteVisitComments = component.get("v.siteVisitComments");
        var location = component.get("v.location");
        var selectedRating = component.get("v.selectedRating");
        var leadId = component.get("v.leadId");
        var selectedDateTime = new Date(dateValue);
        var now = new Date();
        
        // Validation
        if (!dateValue) {
            helper.toastMsg('Error', 'Error', 'Please select Site Visit Date');
            return;
        } 

        if (selectedDateTime.getTime() < now.getTime()) {
            helper.toastMsg('Error', 'Error', 'Sv Scheduled Date & Time must be in the future.');
            return;
        }
        if (!project || project == 'None') {
            helper.toastMsg('Error', 'Error', 'Please select Project');
            return;
        } 
        if (!siteVisitComments) {
            helper.toastMsg('Error', 'Error', 'Please enter Site Visit GRE Comments');
            return;
        } 
        if (!location) {
            helper.toastMsg('Error', 'Error', 'Please enter location');
            return;
        } 
        component.set("v.isLoading", true);
        // Apex call
        var action = component.get("c.createSv");
        action.setParams({
            "remark": siteVisitComments,
            "svDate": dateValue,
            "selectedProject": project,  
            "leadId": leadId,
            "selectedRating": selectedRating,
            "sourcingMember": component.get("v.cpExecutiveId"),
            "channelPartner": component.get("v.channelPartnerId"),
            "location":component.get("v.location")
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.isLoading", false);
                helper.toastMsg('Success', 'Success', 'Site visit verification is completed by GRE');
                // Refresh view
                $A.get('e.force:refreshView').fire();
            } else {
                helper.toastMsg('Error', 'Error', 'Something went wrong while creating Site Visit');
            }
        });
        
        $A.enqueueAction(action);
    },
    openLead : function(component, event, helper) {
        var leadId = event.currentTarget.getAttribute("data-id");
        
        var url = '/lightning/r/Lead/' + leadId + '/view';
        window.open(url, '_blank');
    },
	
    /**Search Channel Partners**/
    searchChannelPartner: function (component, event, helper) {
        var channelPartners = component.get("v.channelPartnerList");
        var searchText = component.get('v.cpSearchText');
        console.log('searchText:' + searchText)
        
        var matchchannelPartners = [];
        if (searchText != '') {
            
            for (var i = 0; i < channelPartners.length; i++) {
                
                if (channelPartners[i].Name.toLowerCase().indexOf(searchText.toLowerCase()) != -1) {
                    matchchannelPartners.push(channelPartners[i]);
                }
            }
            console.log('matchchannelPartners:' + matchchannelPartners)
            if (matchchannelPartners.length > 0) {
                component.set('v.searchedChannelPartners', matchchannelPartners);
            }
            else 
            {
                component.set('v.searchedChannelPartners', []);
            }
        } else {
            component.set('v.searchedChannelPartners', []);
            component.set('v.channelPartnerId', '');
            component.set('v.cpSearchText', '');
        }
    },
    updateChannelPartner: function (component, event, helper) {
        var eid = event.currentTarget.dataset.id;
        var Name = event.currentTarget.dataset.name;
        console.log('Name'+Name);
        console.log('Id'+eid);
        component.set('v.channelPartnerId', eid);
        component.set('v.cpSearchText',Name);
        component.set('v.searchedChannelPartners', []);
    },
    
    /**Search Cp Executives **/
    searchCpExecutive: function (component, event, helper) {
        var cpExecutives = component.get("v.cpExectiveList");
        var searchText = component.get('v.cpExeSearchText');
        console.log('searchText:' + searchText)
        
        var matchcpExecutives = [];
        if (searchText != '') {
            
            for (var i = 0; i < cpExecutives.length; i++) {
                
                if (cpExecutives[i].Name.toLowerCase().indexOf(searchText.toLowerCase()) != -1) {
                    matchcpExecutives.push(cpExecutives[i]);
                }
            }
            console.log('matchcpExecutives:' + matchcpExecutives)
            if (matchcpExecutives.length > 0) {
                component.set('v.searchedcpExectives', matchcpExecutives);
            }
            else 
            {
                component.set('v.searchedcpExectives', []);
            }
        } else {
            component.set('v.searchedcpExectives', []);
            component.set('v.cpExeSearchText', '');
            component.set('v.cpExecutiveId', '');
        }
    },
    updateCpExecutive: function (component, event, helper) {
        var eid = event.currentTarget.dataset.id;
        var Name = event.currentTarget.dataset.name;
        component.set('v.cpExecutiveId', eid);
        component.set('v.cpExeSearchText',Name);
        component.set('v.searchedcpExectives', []);
    },
    

})