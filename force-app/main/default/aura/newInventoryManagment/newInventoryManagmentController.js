({
    doInit: function(component, event, helper) {
        var action = component.get("c.getProjects");
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var db = response.getReturnValue();
                component.set('v.projects', db);
                helper.calculateTotals(component);
            } else {
                console.error('Failed to retrieve projects with state: ' + state);
            }
        });
        
        $A.enqueueAction(action);
        
        helper.getPicklistValues(component, 'Plot__c', 'BHK_Type__c', 'bhkTypeOptions');
        helper.getPicklistValues(component, 'Plot__c', 'Status__c', 'statusOptions');
        helper.getPicklistValues(component, 'Plot__c', 'Wing__c', 'wingNames');
    },
    
    loadPlots: function(component, event, helper) {
        var target = event.currentTarget;
        var record = target.dataset.id;
        var projectName = target.dataset.name;
        
        helper.handleProjectChange(component, record);
        component.set("v.projectName", projectName || '');
        component.set("v.isLoading", true);
        component.set("v.filterBlock", "");
        component.set("v.filterBHKType", "");
        component.set("v.filterStatus", "");
        component.set("v.searchText", "");
        
        var action = component.get("c.getPlots");
        action.setParams({ 'Project': record });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var db = response.getReturnValue();
                
                var bookedPlots       = [];
                var notReleasedPlots  = [];
                var soldPlots         = [];
                var blockedPlots      = [];
                var availablePlots    = [];
                
                db.forEach(function(plot) {
                    switch (plot.Status__c) {
                        case 'Booked':    bookedPlots.push(plot);      break;
                        case 'NFS':       notReleasedPlots.push(plot); break;
                        case 'Sold':      soldPlots.push(plot);        break;
                        case 'Blocked':   blockedPlots.push(plot);     break;
                        case 'Available': availablePlots.push(plot);   break;
                    }
                });
                
                component.set('v.BookedPlots',      bookedPlots);
                component.set('v.NotReleasedPlots',  notReleasedPlots);
                component.set('v.SoldPlots',         soldPlots);
                component.set('v.BlockedPlots',      blockedPlots);
                component.set('v.AvailablePlots',    availablePlots);
                component.set('v.Plots',             db);
                component.set('v.filteredPlots',     db);
                component.set('v.showPlots',         true);
                component.set('v.showProjects',      false);
                
                helper.updateUnitStats(component, db);
                component.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action);
    },
    
    backToProjects: function(component, event, helper) {
        event.preventDefault();
        component.set("v.showPlots",    false);
        component.set("v.showProjects", true);
        component.set("v.filterBlock",   "");
        component.set("v.filterBHKType", "");
        component.set("v.filterStatus",  "");
        component.set("v.searchText",    "");
    },
    
    navigatePlots: function(component, event, helper) {
        var plotId = event.currentTarget.dataset.id;
        var navService = component.find("navService");
        var pageReference = {
            type: "standard__recordPage",
            attributes: {
                recordId:      plotId,
                objectApiName: "Plot__c",
                actionName:    "view"
            }
        };
        navService.navigate(pageReference);
    },
    
    handleCreateBooking: function(component, event, helper) {
        var target = event.currentTarget;
        var record = target.dataset.id;
        component.set("v.unitId",            record);
        component.set("v.showCreateBooking", true);
    },
    
    // In your Helper
    handleFilterChange: function(component, event, helper) {
        // Clear any pending debounce timer
        var existingTimer = component.get("v.debounceTimer");
        if (existingTimer) {
            clearTimeout(existingTimer);
        }
        
        // Set a new timer — only fires 300ms after user stops typing
        var timer = setTimeout(function() {
            helper.applyFilters(component);
        }, 300);
        
        component.set("v.debounceTimer", timer);
    },
})