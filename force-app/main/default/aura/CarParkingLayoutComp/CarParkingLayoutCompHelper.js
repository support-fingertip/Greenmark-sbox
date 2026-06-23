({
    calculateTotals: function(component, event, helper) {
        
        var projects = component.get("v.projects");
        var totalAlottedCarParking = 0;
        var totalAvailableCarParkings = 0;

        projects.forEach(function(prj) {
            totalAlottedCarParking += prj.Sold_Units__c || 0;
            totalAvailableCarParkings += prj.Available_Units__c || 0;
        });
        
        component.set("v.totalAlottedCarParking", totalSoldUnits);
        component.set("v.totalAvailableCarParkings", totalAvailableUnits);
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
    
  filterPlots: function(component) {
    var plots = component.get("v.carParking");
    var filterStatus = component.get("v.filterStatus");

    // If "All" is selected (filterStatus is empty), return all records
    if (!filterStatus || filterStatus === "") {
        component.set("v.filteredCarParkings", plots);
        return;
    }

    // Otherwise, filter based on selected status
    var filteredPlots = plots.filter(function(plot) {
        return plot.Car_Parking_Status__c === filterStatus;
    });

    component.set("v.filteredCarParkings", filteredPlots);
}
,  
    getPicklistValues: function(component, event) {
        var action = component.get("c.getprojectFieldValue");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                
                 if (result) {
                var fieldOptions = [];
                       fieldOptions.push({ label: "All", value: "" });
                for (var key in result) {
                    if (result.hasOwnProperty(key)) {
                        fieldOptions.push({ label: result[key], value: key });
                    }
                }
                component.set("v.statusOptions", fieldOptions);
            }
            }
        });
        $A.enqueueAction(action);
    },
})