({
    scriptsLoaded: function(component, event, helper) {
        // Library loaded; global becomes available (no Locker at API 39).
    },
    startScan: function(component, event, helper) {
        helper.startScan(component);
    },
    cancelScan: function(component, event, helper) {
        helper.stopScanner(component, function() {
            helper.fireEvent(component, 'cancelled', null);
        });
    }
})
