({
    helperMethod : function() {
        
    },
    showToast : function(message,type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "message":  message
        });
        toastEvent.fire();
    },
    getPicklistValues: function(component, event) {
        var action = component.get("c.getBhkType");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var fieldMap = [];
                for(var key in result){
                    fieldMap.push({key: key, value: result[key]});
                }
                component.set("v.fieldMap", fieldMap);
            }
        });
        $A.enqueueAction(action);
    },
    
    
    getFilteredUnit: function(component, event,helper) {
        // console.log('here1');
        component.set('v.spinner',true);
        component.set('v.showUsers',true);
        var leadOwnerId = component.get('v.userId');
        var bhkType = component.get("v.bhkType");
        var projectName = component.get("v.recordId");
        var wingValue = component.get("v.wingValue");
        var uss=  component.get("v.unitStatus");
        //alert('leadStatus-->'+ leadStatus +'  createdDate-->'+ createdDate +'  projectName-->'+ projectName +'  leadsource-->'+ leadsource  )
        var action = component.get("c.getcon");
        action.setParams({
            'currentUserId': leadOwnerId,
            'projectId': projectName,
            'bhkType': bhkType,
            'blockValue': wingValue,
            'unitStatusValue': uss
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            //alert(state)
            if (state === "SUCCESS") {
                 console.log('here3');
                var result = response.getReturnValue();
                component.set("v.mydata3", result);
                component.set('v.spinner',false);
            }else{
                 console.log('here4');
            }
        });
        $A.enqueueAction(action);
       
    },
    
    getPicklistValues1: function(component, event) {
        var action = component.get("c.getleadstatusFieldValue");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var fieldMap = [];
                for(var key in result){
                    fieldMap.push({key: key, value: result[key]});
                }
                component.set("v.fieldMap1", fieldMap);
            }
        });
        $A.enqueueAction(action);
    },
    getPicklistValues2: function(component, event) {
        var action = component.get("c.getBlocks");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var fieldMap = [];
                for(var key in result){
                    fieldMap.push({key: key, value: result[key]});
                }
                component.set("v.fieldMap3", fieldMap);
            }
        });
        $A.enqueueAction(action);
    },
     getUnitStatus: function(component, event) {
        var action = component.get("c.getUnitStatus");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var fieldMap = [];
                for(var key in result){
                    fieldMap.push({key: key, value: result[key]});
                }
                component.set("v.fieldMap2", fieldMap);
            }
        });
        $A.enqueueAction(action);
    },
    showToast: function(message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": type,
            "message": message
        });
        toastEvent.fire();
    },
    
    
    
    
    getUsers: function (component) {
        var action = component.get("c.getUsers");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.users", response.getReturnValue());
            } else {
                console.error("Error fetching users: " + state);
            }
        });
        $A.enqueueAction(action);
    },
    
    /*<!-- <div class="demo-only demo--inverse" style="height:5rem;position:relative">
                        <div role="status" class="slds-spinner slds-spinner_medium">
                            <span class="slds-assistive-text">Loading</span>
                            <div class="slds-spinner__dot-a"></div>
                            <div class="slds-spinner__dot-b"></div>
                        </div>
                    </div>   -->
    },*/
    
    doCancel : function(component, event,helper){
        component.set('v.searchText','');
        component.set('v.matchUsers',[]);
        component.set("v.leadStatus",'');
        component.set("v.leadSource",'');
        component.set('v.showFilter',false);
        component.set("v.lead.Allocated_Project__c",null);
        component.set("v.lead.BHK_Type__c",'');
        component.set("v.lead.Status__c",null);
        component.set("v.createdDateFilter",null);
        component.set("v.projectName",'');
        component.set('v.userId','');
        component.set('v.searchText2','');
        component.set('v.showUsers',false);
        component.set('v.selectedRowsCount4',0);
        //$A.get('e.force:refreshView').fire();
    },
    
    
})