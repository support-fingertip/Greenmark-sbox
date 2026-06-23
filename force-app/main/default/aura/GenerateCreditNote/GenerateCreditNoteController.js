({
    doInit: function (component, event, helper) {
        helper.loadDemand(component);
    },

    handleSubmit: function (component, event, helper) {
        helper.processCancellation(component);
    }
});