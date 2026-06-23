({
    doInit : function(component, event, helper) {
        var action = component.get("c.getInitData");
        action.setParams({
            bookingId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.userList", result.users);
                component.set("v.filteredUserList", result.users);
                component.set("v.stageList", result.stages);
                
                // Set current stage as selected
                if(result.booking && result.booking.Stage__c) {
                    component.set("v.selectedStage", result.booking.Stage__c);
                }
                
                // Set current owner as selected user
                if(result.booking && result.booking.OwnerId) {
                    component.set("v.selectedUser", result.booking.OwnerId);
                    // Find and set the user name
                    var users = result.users;
                    for(var i = 0; i < users.length; i++) {
                        if(users[i].Id === result.booking.OwnerId) {
                            component.set("v.selectedUserName", users[i].Name);
                            component.set("v.searchKey", users[i].Name);
                            break;
                        }
                    }
                }
            } else {
                var errors = response.getError();
                var message = 'Unknown error';
                if (errors && errors[0] && errors[0].message) {
                    message = errors[0].message;
                }
                $A.get("e.force:showToast").setParams({
                    "title": "Error",
                    "message": message,
                    "type": "error"
                }).fire();
            }
        });
        $A.enqueueAction(action);
    },
    
    handleUserSearch : function(component, event, helper) {
        var searchKey = event.getSource().get("v.value");
        component.set("v.searchKey", searchKey);
        helper.filterUsers(component, searchKey);
    },
    
    handleInputFocus : function(component, event, helper) {
        component.set("v.showDropdown", true);
        var searchKey = component.get("v.searchKey");
        helper.filterUsers(component, searchKey);
    },
    
    handleInputBlur : function(component, event, helper) {
        // Delay to allow click event on dropdown item
        window.setTimeout(
            $A.getCallback(function() {
                component.set("v.showDropdown", false);
            }), 300
        );
    },
    
    handleUserSelect : function(component, event, helper) {
        var userId = event.currentTarget.getAttribute("data-userid");
        var userName = event.currentTarget.getAttribute("data-username");
        
        component.set("v.selectedUser", userId);
        component.set("v.selectedUserName", userName);
        component.set("v.searchKey", userName);
        component.set("v.showDropdown", false);
    },
    
    handleRemoveUser : function(component, event, helper) {
        component.set("v.selectedUser", "");
        component.set("v.selectedUserName", "");
        component.set("v.searchKey", "");
        component.set("v.filteredUserList", component.get("v.userList"));
    },
    
    handleSave : function(component, event, helper) {
        var selectedUser = component.get("v.selectedUser");
        var selectedStage = component.get("v.selectedStage");
        var comment = component.get("v.comment");
        
        if(!selectedUser || selectedUser === "") {
            $A.get("e.force:showToast").setParams({
                "title": "Error",
                "message": "Please select a user",
                "type": "error"
            }).fire();
            return;
        }
        
        if(!selectedStage || selectedStage === "") {
            $A.get("e.force:showToast").setParams({
                "title": "Error",
                "message": "Please select a stage",
                "type": "error"
            }).fire();
            return;
        }
        
        var action = component.get("c.updateBooking");
        action.setParams({
            bookingId : component.get("v.recordId"),
            newOwnerId : selectedUser,
            newStage : selectedStage,
            newNote : comment
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                $A.get("e.force:closeQuickAction").fire();
                
                $A.get("e.force:showToast").setParams({
                    "title": "Success",
                    "message": "Booking stage updated successfully",
                    "type": "success"
                }).fire();
                
                var recordId =  component.get("v.recordId");
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": recordId,
                    "slideDevName": "detail"
                });
                navEvt.fire();
                $A.get('e.force:refreshView').fire();
            } 
            else {
                var errors = response.getError();
                var message = 'Unknown error';
                
                if (errors && errors[0] && errors[0].message) {
                    
                    message = errors[0].message;
                    
                    // Extract only custom validation message
                    if (message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION,')) {
                        message = message.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,')[1];
                    }
                    
                    // Remove trailing brackets []
                    message = message.replace(/\[\]/g, '');
                    
                    //  Remove trailing colon if present
                    message = message.replace(/:\s*$/, '');
                    
                    message = message.trim();
                }
                
                $A.get("e.force:showToast").setParams({
                    title: "Error",
                    message: message,
                    type: "error"
                }).fire();


            }
        });
        $A.enqueueAction(action);
    },
    
    handleCancel : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})