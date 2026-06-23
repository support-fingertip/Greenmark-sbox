({
    doInit : function(component, event, helper) {
        helper.loadApprovalData(component);
    },

    openApproveModal : function(component) {
        component.set("v.actionType", "Approve");
        component.set("v.isModalOpen", true);
    },

    openRejectModal : function(component) {
        component.set("v.actionType", "Reject");
        component.set("v.isModalOpen", true);
    },

    closeModal : function(component) {
        component.set("v.isModalOpen", false);
        component.set("v.comments", "");
    },

    handleApprove : function(component, event, helper) {
        helper.processAction(component, true);
    },

    handleReject : function(component, event, helper) {
        helper.processAction(component, false);
    }
})