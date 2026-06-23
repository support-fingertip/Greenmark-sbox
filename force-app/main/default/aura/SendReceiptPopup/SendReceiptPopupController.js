({
    doInit: function(component, event, helper) {
        helper.getReceiptEmailData(component);
    },

    sendEmail: function(component, event, helper) {
        helper.sendReceipt(component);
    },

    close: function(component, event, helper) {
        component.set("v.visible", false);
        var parentCmp = component.getSuper();
        $A.get("e.force:refreshView").fire();
        window.location.reload();
    },

    handleClick : function(component, event, helper) {
        var buttonstate = component.get("v.buttonstate");
        component.set("v.buttonstate", !buttonstate);
    }
})