({
    loadDemand: function (component) {
        component.set("v.isLoading", true);
        const action = component.get("c.getDemandDetails");
        action.setParams({ demandId: component.get("v.recordId") });

        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.demand", response.getReturnValue());
            } else {
                this.showToast("Error", this.getErrorMessage(response), "error");
            }
            component.set("v.isLoading", false);
        });

        $A.enqueueAction(action);
    },

    processCancellation: function (component) {
        component.set("v.isLoading", true);
        const action = component.get("c.cancelDemandAndCreateRefund");
        action.setParams({ demandId: component.get("v.recordId") });

        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                const refundId = response.getReturnValue();
                this.showToast("Success", "Demand cancelled and refund created successfully.", "success");

                // Navigate to refund record
                const navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    recordId: refundId,
                    slideDevName: "detail"
                });
                navEvt.fire();

            } else {
                this.showToast("Error", this.getErrorMessage(response), "error");
            }
            component.set("v.isLoading", false);
        });

        $A.enqueueAction(action);
    },

    showToast: function (title, message, type) {
        const toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({ title, message, type });
        toastEvent.fire();
    },

    getErrorMessage: function (response) {
        const errors = response.getError();
        return (errors && errors[0] && errors[0].message) ? errors[0].message : "Unknown error";
    }
});