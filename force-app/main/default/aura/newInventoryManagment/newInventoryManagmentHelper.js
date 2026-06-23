({
    showToast: function(type, title, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":    type,
            "title":   title,
            "message": message
        });
        toastEvent.fire();
    },

    calculateTotals: function(component) {
        var projects          = component.get("v.projects");
        var totalSoldUnits      = 0;
        var totalAvailableUnits = 0;

        projects.forEach(function(prj) {
            totalSoldUnits      += prj.Sold_Units__c      || 0;
            totalAvailableUnits += prj.Available_Units__c || 0;
        });

        component.set("v.totalSoldUnits",      totalSoldUnits);
        component.set("v.totalAvailableUnits", totalAvailableUnits);
        this.calculateProgress(component);
    },

    calculateProgress: function(component) {
        var projects = component.get("v.projects");
        projects.forEach(function(prj) {
            var totalUnits  = prj.Total_Units__c  || 0;
            var bookedUnits = prj.Booked_Units__c || 0;

            if (totalUnits === 0) {
                prj.progressWidth      = 0;
                prj.progressPercentage = "0%";
            } else {
                var percentage         = Math.min(100, (bookedUnits / totalUnits) * 100);
                var formatted          = parseFloat(percentage.toFixed(2));
                prj.progressWidth      = formatted;
                prj.progressPercentage = formatted + "%";
            }
        });
        component.set("v.projects", projects);
    },

    getPicklistValues: function(component, objectName, fieldName, attributeName) {
        var action = component.get("c.getPicklistValues");
        action.setParams({ objectName: objectName, fieldName: fieldName });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v." + attributeName, response.getReturnValue());
            } else {
                console.error('Error fetching picklist values:', response.getError());
            }
        });

        $A.enqueueAction(action);
    },
    
    handleProjectChange: function(component, record) {
        if (record) {
            var action = component.get("c.getBlockNames");
            action.setParams({ projectId: record });
            
            action.setCallback(this, function(response) {
                if (response.getState() === "SUCCESS") {
                    component.set("v.blockNames", response.getReturnValue());
                }
            });
            
            $A.enqueueAction(action);
        } else {
            component.set("v.blockNames", []);
        }
    },
    applyFilters: function(component) {
        var filterBlock   = component.get("v.filterBlock")   || "";
        var filterBHKType = component.get("v.filterBHKType") || "";
        var filterStatus  = component.get("v.filterStatus")  || "";
        var filterWing    = component.get("v.filterWing")    || "";
        var searchText    = component.get("v.searchText")    || "";
        
        if (filterBlock   === "All") filterBlock   = "";
        if (filterBHKType === "All") filterBHKType = "";
        if (filterStatus  === "All") filterStatus  = "";
        if (filterWing    === "All") filterWing    = "";
        
        var allUnits   = component.get("v.Plots");
        var searchTerm = searchText.trim().toLowerCase();
        
        // Pre-check: skip search matching if searchTerm is empty
        var hasSearch = searchTerm !== "";
        
        var filteredUnits = allUnits.filter(function(unit) {
            // Short-circuit: cheapest checks first
            if (filterBlock  && unit.Block_Name__c !== filterBlock)  return false;
            if (filterBHKType && unit.BHK_Type__c  !== filterBHKType) return false;
            if (filterStatus && unit.Status__c      !== filterStatus) return false;
            if (filterWing   && unit.Wing__c        !== filterWing)   return false;
            
            // Search is the most expensive — run last
            if (hasSearch) {
                var unitName   = (unit.Name           || "").toLowerCase();
                var unitNumber = (unit.Unit_Number__c  || "").toLowerCase();
                var unitDesc   = (unit.Description__c  || "").toLowerCase();
                return unitName.includes(searchTerm)   ||
                    unitNumber.includes(searchTerm) ||
                    unitDesc.includes(searchTerm);
            }
            
            return true;
        });
        
        component.set("v.filteredPlots", filteredUnits);
        this.updateUnitStats(component, filteredUnits);
    },
    /**
     * Recalculates and sets the 7 stat attributes from the given units array.
     */
    updateUnitStats: function(component, units) {
        var total      = units.length;
        var available  = 0;
        var blocked    = 0;
        var investor   = 0;
        var management = 0;
        var booked     = 0;
        var sold       = 0;
        var landowner  = 0;
        var commercial = 0;
        var modelVilla = 0;

        units.forEach(function(u) {
            switch (u.Status__c) {
                case 'Available':             available++;  break;
                case 'Blocked':               blocked++;    break;
                case 'Blocked by Investor':   investor++;   break;
                case 'Blocked by Management': management++; break;
                case 'Booked':                booked++;     break;
                case 'Sold':                  sold++;       break;
                case 'Landowner Share':       landowner++;  break;
                case 'Commercial':            commercial++; break;
                case 'Model Villa':           modelVilla++; break;
                default: break;
            }
        });

        component.set("v.statTotal",      total);
        component.set("v.statAvailable",  available);
        component.set("v.statBlocked",    blocked);
        component.set("v.statInvestor",   investor);
        component.set("v.statManagement", management);
        component.set("v.statBooked",     booked);
        component.set("v.statSold",       sold);
        component.set("v.statLandowner",  landowner);
        component.set("v.statCommercial", commercial);
        component.set("v.statModelVilla", modelVilla);
    }
})