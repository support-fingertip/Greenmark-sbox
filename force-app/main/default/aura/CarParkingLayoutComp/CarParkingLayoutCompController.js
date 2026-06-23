({
    doInit: function(component, event, helper) {
        
        helper.getPicklistValues(component, event);
        var action = component.get("c.getProjects");
        // action.setParams({'recId':  component.get('v.recordId') });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var db = response.getReturnValue();
                component.set('v.projects', db);
                
                // Calculate totals after projects are set
                helper.calculateTotals(component);
            } else {
                console.error('Failed to retrieve projects with state: ' + state);
            }
        });
        
        $A.enqueueAction(action);
     
    },
    
    loadCarParking: function(component, event, helper) {
        var target = event.currentTarget;
        var dataIndex = target.dataset.index;
        var record = target.dataset.id;
        var projectName = target.dataset.name;
        component.set("v.projectName",projectName||'');
        var action = component.get("c.getCarParkings");
        action.setParams({'Project':  record });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == "SUCCESS") { 
                var db = response.getReturnValue();
                
                var alottedCarParking = [];
                var blockedCarParking = [];
                var availableCarParking = [];
                
                db.forEach(function(carParking) {
                    switch(carParking.Car_Parking_Status__c) {
                        case 'Allotted':
                            alottedCarParking.push(carParking);
                            break;
                        case 'Blocked':
                            blockedCarParking.push(carParking);
                            break;
                        case 'Not Alotted':
                            availableCarParking.push(carParking);
                            break;
                    }
                });
                
                component.set('v.showCarParking', true);
                component.set('v.showProjects', false);
                component.set('v.carParking',db);
                component.set('v.filteredCarParkings',db);
            }
        });
        $A.enqueueAction(action);
    },
  
    handleFilterChange: function(component, event, helper) {
    var filterName = event.getSource().get("v.name");
    var selectedValue = event.getParam("value");

    if (filterName === "statusFilter") {
        component.set("v.filterStatus", selectedValue);
    }

    console.log("Selected Status:", selectedValue); // Debugging
    helper.filterPlots(component);
},

    navigatePlots: function(component, event, helper) {
        var plotId = event.currentTarget.dataset.id;
        console.log('plotId'+plotId);
        var navService = component.find("navService");
        var pageReference = {
            type: "standard__recordPage",
            attributes: {
                recordId: plotId,
                objectApiName: "Car_Parking__c",
                actionName: "view"
            }
        };
        navService.navigate(pageReference);
    },
    
})