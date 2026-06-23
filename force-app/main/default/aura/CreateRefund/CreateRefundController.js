({
    doInit: function(component, event, helper) {
        var today = new Date().toISOString().slice(0, 10);
        component.set("v.refundDate", today);

        var action = component.get("c.getRefundFormData");
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var data = response.getReturnValue() || {};
                var types = (data.refundTypes || []).filter(function(t){ return t !== "TDS Refund"; });
                component.set("v.refundTypes", types);
                component.set("v.paymentModes", data.paymentModes || []);
                component.set("v.bankNames", data.bankNames || []);
            } else {
                helper.toastMsg("error", "Error", helper.getErrorMessage(response));
            }
        });
        $A.enqueueAction(action);
    },

    save: function(component, event, helper) {
        var refundType = component.get("v.refundType");
        var amount = component.get("v.amount");

        if (!refundType) {
            helper.toastMsg("warning", "Required", "Please select a Refund Type.");
            return;
        }
        if (!amount || Number(amount) <= 0) {
            helper.toastMsg("warning", "Required", "Please enter a valid Refund Amount.");
            return;
        }

        var requiredFields = [
            { value: component.get("v.bankName"), label: "Bank Name" },
            { value: component.get("v.branchName"), label: "Branch Name" },
            { value: component.get("v.paymentMode"), label: "Payment Mode" },
            { value: component.get("v.transactionChequeNo"), label: "Transaction / Cheque No" },
            { value: component.get("v.drawnOn"), label: "Drawn On" },
            { value: component.get("v.reason"), label: "Reason" }
        ];
        for (var i = 0; i < requiredFields.length; i++) {
            var f = requiredFields[i];
            if (!f.value || (typeof f.value === "string" && f.value.trim() === "")) {
                helper.toastMsg("warning", "Required", "Please enter " + f.label + ".");
                return;
            }
        }

        if (component.get("v.paymentMode") === "Cheque" && !component.get("v.chequeDate")) {
            helper.toastMsg("warning", "Required", "Please enter Cheque Date.");
            return;
        }

        component.set("v.isSaving", true);
        var action = component.get("c.createRefund");
        action.setParams({
            bookingId: component.get("v.recordId"),
            refundType: refundType,
            amount: amount,
            refundDateStr: component.get("v.refundDate"),
            bankName: component.get("v.bankName"),
            branchName: component.get("v.branchName"),
            chequeDateStr: component.get("v.chequeDate"),
            transactionChequeNo: component.get("v.transactionChequeNo"),
            drawnOnStr: component.get("v.drawnOn"),
            paymentMode: component.get("v.paymentMode"),
            reason: component.get("v.reason")
        });
        action.setCallback(this, function(response) {
            component.set("v.isSaving", false);
            if (response.getState() === "SUCCESS") {
                helper.toastMsg("success", "Success", "Refund created successfully.");
                component.set("v.visible",false);
                $A.get("e.force:closeQuickAction").fire();
                $A.get("e.force:refreshView").fire();
            } else {
                helper.toastMsg("error", "Error", helper.getErrorMessage(response));
            }
        });
        $A.enqueueAction(action);
    },

    close: function(component, event, helper) {
        component.set("v.visible",false);
    }
})