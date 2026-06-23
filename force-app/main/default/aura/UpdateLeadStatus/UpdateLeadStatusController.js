({
    doInit123 : function(component, event, helper) {
      
            component.set('v.spinner',true);
            
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
    },
    doInit: function(component, event, helper) {
        component.set('v.spinner',true);
        component.set("v.recordOwner", component.get("v.LeadRecord").OwnerId);
        var userId = $A.get("$SObjectType.CurrentUser.Id");
            var primaryUser = component.get("v.LeadRecord").isCurrentUser__c;
            //alert(primaryUser);
            var secondaryUser = component.get("v.LeadRecord").isCurrentUserSec__c;
            //alert(secondaryUser);
            if(primaryUser == true){
                component.set('v.isPrimary',true);
            }
            if(secondaryUser == true){
                component.set('v.isSecondary',true);
            }
        //alert(component.get("v.recordOwner"));
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
                followUpSubject : component.get("v.followUpSubject")
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if(state == 'SUCCESS') {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "Record Updated.",
                        "type":"success"
                    });
                    toastEvent.fire();
                    
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": "Something went wrong",
                        "type":"error"
                    });
                    toastEvent.fire();
                }
                $A.get("e.force:closeQuickAction").fire();
            });
            $A.enqueueAction(action);
            $A.get('e.force:refreshView').fire();
        }
    },
    doCancel: function (component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
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
        else if(status == 'Booked'){
            alert('Status cannot be changed to Booking');
            component.set('v.showSave',false);
        }
        else{
            component.set('v.showSave',true);
        }
        //alert(component.get('v.leadStatus'));
        var leadStatus1 = event.getParam('value');
        component.set('v.spinner',false);
    }
})
/*
     searchText : function(component, event, helper) {
        var accounts= component.get('v.accounts');
        var searchText= component.get('v.searchText');
         //alert(searchText);
        var matchaccounts=[];
        if(searchText !=''){
            //alert(searchText);
            for(var i=0;i<accounts.length; i++){ 
                if(accounts[i].toLowerCase().indexOf(searchText.toLowerCase())  != -1  ){
                    
                    if(matchaccounts.length <50){
                        matchaccounts.push( accounts[i] );
                    }else{
                        break;
                    }
                    
                } 
            } 
            if(matchaccounts.length >0){
                component.set('v.matchaccounts',matchaccounts);
            }
        }else{
            component.set('v.matchaccounts',[]);
            component.set('v.SubStatus','');
        }
    },
    update: function(component, event, helper) {
        
        component.set('v.SubStatus', event.currentTarget.dataset.id);
        var edi = component.get('v.SubStatus');
        var accounts= component.get('v.matchaccounts');
        for(var i=0;i<accounts.length; i++){ 
            if(accounts[i] ===  edi ){
                component.set('v.searchText', accounts[i]);
                component.set('v.SubStatus', accounts[i]);
                break;
            } 
        } 
        
        component.set('v.matchaccounts',[]);
        
    },
     updateLead: function (component, event, helper) {
        
        var SubStatus=component.get("v.SubStatus");
         var reason=component.get("v.reason");
       // alert(SubStatus);
        var rec=component.get("v.recordId");
        if(SubStatus!=null && SubStatus!=undefined && SubStatus!='' && SubStatus!='None')
        {
           
                  
        }
          
    },
    doCancel: function (component, event, helper) {
    $A.get("e.force:closeQuickAction").fire();
}
})*/