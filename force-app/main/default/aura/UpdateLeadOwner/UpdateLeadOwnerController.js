({  
     doinit: function(component, event, helper) {
        // Get the selected profile from the component attribute
        var selectedProfile = component.get("v.selectedProfile");
        
        // Call the server-side action to fetch users based on the selected profile
        var action = component.get("c.getUsers");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.users", response.getReturnValue());
            } else {
                console.log("Error fetching users: " + state);
            }
        });
        $A.enqueueAction(action);
    }, 
    getUsersByProfile : function(component, event, helper) {
        var usersl = component.get('v.users');
        var getType = component.get('v.selectedProfile');
        if(getType  == 'Presales'){
            var useList1 = [];
            for(var i = 0 ; i < usersl.length ; i++){
                if(usersl[i].Profile.Name == 'Pre Sales' || usersl[i].Profile.Name == 'Pre Sales Manager' ){
                    useList1.push(usersl[i]);
                }
            }
            component.set('v.usersListShow',useList1);
        }
        else if(getType  == 'Sales'){
            var useList2 = [];
            for(var i = 0 ; i < usersl.length ; i++){
                if(usersl[i].Profile.Name == 'Sales'||usersl[i].Profile.Name == 'Sales Manager'){
                    useList2.push(usersl[i]);
                }
            }
            component.set('v.usersListShow',useList2);
        }
        else if(getType  == 'Assistant Pre Sales Manager'){
            var useList3 = [];
            for(var i = 0 ; i < usersl.length ; i++){
                if(usersl[i].Profile.Name == 'Assistant Pre Sales Manager'){
                    useList3.push(usersl[i]);
                }
            }
            component.set('v.usersListShow',useList3);
        }
        
   },
    saveIt: function(component, event, helper) {
        var tyep = component.get('v.selectedProfile');
        var useId = component.get('v.selectedUserId');
        var recId = component.get('v.recordId');
        var ischeck = component.get("v.check");
        
        if(tyep == 'Presales' ||'Assistant Pre Sales Manager'){
            var action = component.get("c.UpdateUser");
            action.setParams({'userID':  useId,
                              'recordId': recId,
                              'ischcek':ischeck})
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    helper.showToast("Lead Owner Updated Successfully","SUCCESS");
                    window.location.reload();
                    $A.get("e.force:closeQuickAction").fire();
                } else {
                    alert("Error Updating Lead: " + state);
                    $A.get("e.force:closeQuickAction").fire();
                }
            });
            $A.enqueueAction(action);
        }
        if(tyep == 'Sales' && ischeck == false){
            helper.showToast("Please select the checkbox","Warning");
        }
        if(tyep == 'Sales' && ischeck == true){
            var action = component.get("c.UpdateUser");
            action.setParams({'userID':  useId,
                              'recordId': recId,
                              'ischcek': ischeck})
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    helper.showToast("Lead Owner Updated Successfully","SUCCESS");
                    $A.get("e.force:closeQuickAction").fire();
                    window.location.reload();
                } else {
                    alert("Error Updating Lead: " + state);
                    $A.get("e.force:closeQuickAction").fire();
                }
            });
            $A.enqueueAction(action);
            
        }
    }
    
})