({
	  showToast : function(type,title,message) {
        console.log(message)
      //  alert('h')
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "title":title,
            "message":message
        });
        toastEvent.fire();
    },
    calculateTotals: function(component, event, helper) {
        console.log('calculateTotals');
        var projects = component.get("v.projects");
        var totalSoldUnits = 0;
        var totalAvailableUnits = 0;

        projects.forEach(function(prj) {
            totalSoldUnits += prj.Sold_Units__c || 0;
            totalAvailableUnits += prj.Available_Units__c || 0;
        });
        
        component.set("v.totalSoldUnits", totalSoldUnits);
        component.set("v.totalAvailableUnits", totalAvailableUnits);
        this.calculateProgress(component,helper);
    },
    

    calculateProgress: function(component,helper) {
        console.log('here');
        var projects = component.get("v.projects");
        projects.forEach(function(prj) {
            var totalUnits = prj.Total_Units__c;
            var bookedUnits = prj.Booked_Units__c;

            if (totalUnits === 0) {
                prj.progressWidth = "0%";
                prj.progressPercentage = "0%";
            } else {
               var percentage = parseFloat(Math.min(100, (bookedUnits / totalUnits) * 100).toFixed(2));
                prj.progressWidth = percentage;
                prj.progressPercentage = percentage + "%";
            }
        });
        
        component.set("v.projects", projects);
    },
     initializeFilters: function(component) {
    // Call Apex to get picklist values
    this.getPicklistValues(component, 'Plot__c', 'Plot_Type__c', 'plotTypeOptions');
    this.getPicklistValues(component, 'Plot__c', 'BHK_Type__c', 'bhkTypeOptions');
    this.getPicklistValues(component, 'Plot__c', 'Status__c', 'statusOptions');
},
    getPicklistValues: function(component, objectName, fieldName, attributeName) {
    // Call Apex method to fetch picklist values
    var action = component.get("c.getPicklistValues");
    action.setParams({
        objectName: objectName,
        fieldName: fieldName
    });

    action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === "SUCCESS") {
            // Set the picklist values to the component attribute
            component.set("v." + attributeName, response.getReturnValue());
        } else if (state === "ERROR") {
            console.error('Error fetching picklist values:', response.getError());
        }
    });

    $A.enqueueAction(action);
},
   /* filterPlots: function(component) {
        var plots = component.get("v.Plots");
        var filteredPlots = plots.filter(function(plot) {
            var plotTypeMatch = !component.get("v.filterPlotType") || plot.Plot_Type__c === component.get("v.filterPlotType");
            var bhkTypeMatch = !component.get("v.filterBHKType") || plot.BHK_Type__c === component.get("v.filterBHKType");
            var statusMatch = !component.get("v.filterStatus") || plot.Status__c === component.get("v.filterStatus");
            return plotTypeMatch && bhkTypeMatch && statusMatch;
        });
        component.set("v.filteredPlots", filteredPlots);
    },*/
 
    handleProjectChange: function(component, record) {
        //var projectId = component.get("v.projectId");
	
        if (record) {
            var action = component.get("c.getBlockNames");
            action.setParams({ projectId: record });

            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.blockNames", response.getReturnValue());
                }
            });

            $A.enqueueAction(action);
        } else {
            component.set("v.blockNames", []);
        }
    },
  
})