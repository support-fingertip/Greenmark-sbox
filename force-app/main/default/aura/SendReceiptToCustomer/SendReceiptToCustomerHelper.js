({
    loadReceipts : function(component) {
        component.set("v.isLoading", true);
        
        var action = component.get("c.getReceiptsForBooking");
        action.setParams({
            bookingId: component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);
            
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.receiptOptions", result);
            } else {
                this.showToast("Error", "Unable to load receipts.", "error");
            }
        });
        
        $A.enqueueAction(action);
    },
    
    loadPreview : function(component) {
        var receiptId = component.get("v.selectedReceiptId");
        
        if (!receiptId) {
            component.set("v.emailContent", "");
            component.set("v.subject", "");
            component.set("v.previewUrl", "");
            return;
        }
        
        component.set("v.isLoading", true);
        
        var action = component.get("c.getReceiptEmailPreview");
        action.setParams({
            receiptId: receiptId
        });
        
        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);
            
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                
                component.set("v.subject", data.subject);
                component.set("v.previewUrl", data.previewUrl);
                
                var raw = data.emailContent ? data.emailContent : '';
                var decoded = raw
                .replace(/&lt;/g, "<")
                .replace(/&gt;/g, ">")
                .replace(/&amp;/g, "&");
                
                decoded = decoded.replace(/<span[^>]*>/g, "");
                decoded = decoded.replace(/<\/span>/g, "");
                decoded = decoded.replace(/<p><br><\/p>/g, "");
                
                component.set("v.emailContent", decoded);
            } else {
                var errors = response.getError();
                var msg = "Unable to load email preview.";
                if (errors && errors[0] && errors[0].message) {
                    msg = errors[0].message;
                }
                this.showToast("Error", msg, "error");
            }
        });
        
        $A.enqueueAction(action);
    },
    
    sendReceipt : function(component) {
        var receiptId = component.get("v.selectedReceiptId");
        
        if (!receiptId) {
            this.showToast("Error", "Please select a receipt.", "error");
            return;
        }
        
        var content = component.get("v.emailContent") || '';
        
        component.set("v.isLoading", true);
        
        var action = component.get("c.sendReceiptToCustomer");
        action.setParams({
            receiptId: receiptId,
            emailContent: content,
            extraFileIds: component.get("v.filesIDS")
        });
        
        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);
            
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                this.showToast("Success", result, "success");
                
                component.set("v.showModal", false);
                component.set("v.selectedReceiptId", "");
                component.set("v.emailContent", "");
                component.set("v.subject", "");
                component.set("v.previewUrl", "");
                component.set("v.buttonstate", false);
                component.set("v.filesIDS", []);
                component.set("v.uploadedFiles", []);
                
                $A.get("e.force:refreshView").fire();
            } else {
                var errors = response.getError();
                var msg = "Error sending receipt.";
                if (errors && errors[0] && errors[0].message) {
                    msg = errors[0].message;
                }
                this.showToast("Error", msg, "error");
            }
        });
        
        $A.enqueueAction(action);
    },
    
    showToast : function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        if (toastEvent) {
            toastEvent.setParams({
                title: title,
                message: message,
                type: type
            });
            toastEvent.fire();
        } else {
            alert(message);
        }
    }
})
/*({
    loadReceipts : function(component) {
        component.set("v.isLoading", true);

        var action = component.get("c.getReceiptsForBooking");
        action.setParams({
            bookingId: component.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);

            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.receiptOptions", result);
            } else {
                this.showToast("Error", "Unable to load receipts.", "error");
            }
        });

        $A.enqueueAction(action);
    },

    loadPreview : function(component) {
        var receiptId = component.get("v.selectedReceiptId");

        if (!receiptId) {
            component.set("v.emailContent", "");
            component.set("v.subject", "");
            component.set("v.previewUrl", "");
            return;
        }

        component.set("v.isLoading", true);

        var action = component.get("c.getReceiptEmailPreview");
        action.setParams({
            receiptId: receiptId
        });

        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);

            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();

                component.set("v.subject", data.subject);
                component.set("v.previewUrl", data.previewUrl);

                var raw = data.emailContent ? data.emailContent : '';
                var decoded = raw
                    .replace(/&lt;/g, "<")
                    .replace(/&gt;/g, ">")
                    .replace(/&amp;/g, "&");

                decoded = decoded.replace(/<span[^>]*>/g, "");
                decoded = decoded.replace(/<\/span>/g, "");
                decoded = decoded.replace(/<p><br><\/p>/g, "");

                component.set("v.emailContent", decoded);
            } else {
                var errors = response.getError();
                var msg = "Unable to load email preview.";
                if (errors && errors[0] && errors[0].message) {
                    msg = errors[0].message;
                }
                this.showToast("Error", msg, "error");
            }
        });

        $A.enqueueAction(action);
    },

    sendReceipt : function(component) {
        var receiptId = component.get("v.selectedReceiptId");

        if (!receiptId) {
            this.showToast("Error", "Please select a receipt.", "error");
            return;
        }

        var content = component.get("v.emailContent") || '';
        content = content.replace(/<p>(&nbsp;|\s)*<\/p>/g, '');
        content = content.replace(/(<br\s*\/?>\s*){2,}/g, '<br/>');

        component.set("v.isLoading", true);

        var action = component.get("c.sendReceiptToCustomer");
        action.setParams({
            receiptId: receiptId,
            emailContent: content
        });

        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);

            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                this.showToast("Success", result, "success");

                component.set("v.showModal", false);
                component.set("v.selectedReceiptId", "");
                component.set("v.emailContent", "");
                component.set("v.subject", "");
                component.set("v.previewUrl", "");
                component.set("v.buttonstate", false);

                $A.get("e.force:refreshView").fire();
            } else {
                var errors = response.getError();
                var msg = "Error sending receipt.";
                if (errors && errors[0] && errors[0].message) {
                    msg = errors[0].message;
                }
                this.showToast("Error", msg, "error");
            }
        });

        $A.enqueueAction(action);
    },

    showToast : function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        if (toastEvent) {
            toastEvent.setParams({
                title: title,
                message: message,
                type: type
            });
            toastEvent.fire();
        } else {
            alert(message);
        }
    }
})*/