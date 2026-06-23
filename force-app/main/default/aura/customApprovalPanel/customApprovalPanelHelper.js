({
    loadApprovalData : function(component) {

        component.set("v.isLoading", true);

        var action = component.get("c.getApprovalData");
        action.setParams({ recordId: component.get("v.recordId") });

        action.setCallback(this, function(response) {

            component.set("v.isLoading", false);

            if (response.getState() === "SUCCESS") {
                component.set("v.approvalData", response.getReturnValue());
            } else {
                this.showToast("Error", this.getError(response), "error");
            }
        });

        $A.enqueueAction(action);
    },

    processAction : function(component, isApprove) {

        var action = component.get(isApprove ? "c.approve" : "c.reject");

        action.setParams({
            recordId: component.get("v.recordId"),
            comments: component.get("v.comments")
        });

        component.set("v.isLoading", true);

        action.setCallback(this, function(response) {

            component.set("v.isLoading", false);
            component.set("v.isModalOpen", false);
            component.set("v.comments", "");

            if (response.getState() === "SUCCESS") {

                this.showToast("Success",
                    isApprove ? "Quote Approved" : "Quote Rejected",
                    "success"
                );

                this.loadApprovalData(component);
                $A.get("e.force:refreshView").fire();

            } else {
                this.showToast("Error", this.getError(response), "error");
            }
        });

        $A.enqueueAction(action);
    },

    showToast : function(title, message, type) {
        var evt = $A.get("e.force:showToast");
        evt.setParams({
            title: title,
            message: message,
            type: type
        });
        evt.fire();
    },

    getError : function(response) {
        var errors = response.getError();
        return errors && errors[0] && errors[0].message
            ? errors[0].message
            : "Unknown error";
    }
});