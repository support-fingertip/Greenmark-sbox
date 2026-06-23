({
    doInit: function(component, event, helper) {
        
        helper.onInit(component, event, helper);
        helper.readCallDetails(component, event, helper);
        
        const empApi = component.find("empApi");
        empApi.setDebugFlag(true);
        const replayId = -1;
        empApi
        .subscribe(
            "/event/CtitaskCreated__e",
            replayId,
            $A.getCallback(eventReceived => {
                helper.getDetails(
                component,
                event,
                helper,
                eventReceived.data.payload
                );
            })
                )
                .then(subscription => {});
                
                empApi
                .subscribe(
                "/event/CtiNotification__e",
                replayId,
                $A.getCallback(eventReceived => {
                helper.getCallDetails(
                component,
                event,
                helper,
                eventReceived.data.payload
                );
            })
                )
                .then(subscription => {});
                
                
                
                
            },
                
                handleClear: function(component, event, helper) {
                    component.set("v.selectedPhone", "");
                },
                
                handleCall: function(component, event, helper) {
                    component.set("v.isdisabled",true);
                    var phone = component.get("v.selectedPhone");
                    //var subject = component.get("v.subject");
                    component.set("v.callcomplete", false);
                    console.log("phone!!!!!!!!!" + phone);
                    if (phone != undefined && phone.trim() != "") {
                        helper.callNumber(component, event, helper); 
                    } else {
                        helper.displayMessage(
                            component,
                            "Please select Phone number to make a call.",
                            "error"
                        );
                    }
                },
                
                refresh: function(component, event, helper) {
                    helper.onInit(component, event, helper);
                },
                saveCall: function(component, event, helper) {
                  //  helper.saveCall(component, event, helper);
                },
                handleError: function (cmp, event, helper) {
                    var error = event.getParams();
                    // Get the error message
                    let errorMessage = event.getParam("message");
                    // alert(errorMessage);
                    if(errorMessage.includes('resource does not exist') || errorMessage.includes('do not have the level of access') || errorMessage.includes('insufficient access')){
                        cmp.set('v.spinner',false);
                        var navEvent = $A.get("e.force:navigateToList");
                        navEvent.setParams({
                            "listViewId": '00B2w00000Pwpf1EAB',
                            "listViewName": null,
                            "scope": "Contact"
                        });
                        navEvent.fire();
                        $A.get("e.force:closeQuickAction").fire();
                    }else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!",
                            "message": errorMessage,
                            "type":"Error"
                        });
                        toastEvent.fire();
                    }
                },
                handleLoad: function(component, event, helper) {
                    
                    
                    component.set('v.leadStatus',status);
                    component.set('v.spinner',false);
                    //alert(status);
                },
                handleOnSubmit : function(component, event, helper) {
                    
                    var todayDate = new Date().toISOString().split('T')[0];
                    var selectedValue = component.get('v.followUpDate');
                    if(selectedValue < todayDate){
                        helper.Toast('Error','Error','Please Select Future Date');
                        component.set('v.isError',true);
                        event.preventDefault();
                    }
                    else{
                        component.set('v.isError',false);
                    }
                    
                },
                handleSuccess : function(component,event,helper) {
                    var isError = component.get('v.isError');
                    if(isError == false){
                        $A.get("e.force:closeQuickAction").fire();
                        
                        var action = component.get("c.updateLastNote");
                        action.setParams({
                            leadId : component.get("v.recordId"),
                            newNote : component.get("v.addNotes"),
                            isPrimary : component.get("v.isPrimary"),
                            isSecondary : component.get("v.isSecondary"),
                            followUpDate : component.get("v.followUpDate"),
                            followUpSubject : component.get("v.followUpSubject"),
                            siteVisitScheduledDate : component.get("v.siteVisitScheduled")
                        });
                        action.setCallback(this, function(response){
                            var state = response.getState();
                            if(state == 'SUCCESS') {
                                var msg = 'Comments Updated Successfully';
                                helper.displayMessage(component, msg , "success");
                                
                            }else{
                                var msg = 'Something Went Wrong';
                                helper.displayMessage(component, msg , "success");
                            }
                            $A.get("e.force:closeQuickAction").fire();
                        });
                        $A.enqueueAction(action);
                        $A.get('e.force:refreshView').fire();
                    }
                },
                
                onLeadChange : function(component, event, helper){
                    component.set('v.spinner',true);
                    component.set('v.leadStatus',event.getParam('value'));
                    //alert(component.get('v.leadStatus'));
                    var status = component.find('leadStatus').get('v.value');
                    if(status == 'Unqualifed' || status == 'Closed Lost' || status == 'Unqualified'){
                        //alert('yes its true');
                        component.set('v.isClosedOrUnqualified',true);
                    }
                    if(status == 'Site Visit Scheduled' || status == 'Site Visit Conducted'){
                        alert('Status cannot be changed for site visit');
                        component.set('v.showSave',false);
                    }
                    else{
                        component.set('v.showSave',true);
                    }
                    //alert(component.get('v.leadStatus'));
                    var leadStatus1 = event.getParam('value');
                    component.set('v.spinner',false);
                },
                close : function(component, event, helper){
                    $A.get("e.force:closeQuickAction").fire();
                }
            });