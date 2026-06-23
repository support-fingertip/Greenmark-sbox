({
    handleRecordLoaded: function(component, event, helper) {
        var changeType = event.getParams().changeType;
        
        if (changeType === "ERROR") {
            console.error("Error loading record");
        } else if (changeType === "LOADED" || changeType === "CHANGED") {
            var record = component.get("v.bookingRecord");
            
            var showCustomButtons = record.fields.Show_Custom_Buttons__c.value;
            
            console.log("showCustomButtons:", showCustomButtons);
            
            component.set("v.showCustomButtons", showCustomButtons);
        }
    },
    openModal : function(component, event, helper) {
        component.set("v.showModal", true);
        component.set("v.buttonstate", false);
        helper.loadReceipts(component);
    },

    closeModal : function(component, event, helper) {
        component.set("v.showModal", false);
        component.set("v.selectedReceiptId", "");
        component.set("v.emailContent", "");
        component.set("v.subject", "");
        component.set("v.previewUrl", "");
        component.set("v.buttonstate", false);
        component.set("v.filesIDS", []);
        component.set("v.uploadedFiles", []);
    },

    handleReceiptChange : function(component, event, helper) {
        helper.loadPreview(component);
    },

    handleToggle : function(component, event, helper) {
        var buttonstate = component.get("v.buttonstate");
        component.set("v.buttonstate", !buttonstate);
    },

    handleFileUpload : function(component, event, helper) {
        var uploadedFiles = event.getParam("files");
        var fileIds = component.get("v.filesIDS") || [];
        var uploadedFileList = component.get("v.uploadedFiles") || [];
        
        uploadedFiles.forEach(function(file) {
            fileIds.push(file.documentId);
            uploadedFileList.push({
                name: file.name,
                documentId: file.documentId,
                url: '/lightning/r/ContentDocument/' + file.documentId + '/view'
            });
        });
        
        component.set("v.filesIDS", fileIds);
        component.set("v.uploadedFiles", uploadedFileList);
    },
    
    sendEmail : function(component, event, helper) {
        helper.sendReceipt(component);
    }
})
/*({
    openModal : function(component, event, helper) {
        component.set("v.showModal", true);
        component.set("v.buttonstate", false);
        helper.loadReceipts(component);
    },

    closeModal : function(component, event, helper) {
        component.set("v.showModal", false);
        component.set("v.selectedReceiptId", "");
        component.set("v.emailContent", "");
        component.set("v.subject", "");
        component.set("v.previewUrl", "");
        component.set("v.buttonstate", false);
    },

    handleReceiptChange : function(component, event, helper) {
        helper.loadPreview(component);
    },

  handleToggle : function(component, event, helper) {
        var currentState = component.get("v.buttonstate");
        component.set("v.buttonstate", !currentState);
    },
    handleToggle : function(component, event, helper) {
    var buttonstate = component.get("v.buttonstate");
    component.set("v.buttonstate", !buttonstate);
    },
    
    handleFileUpload: function(component, event, helper) {
        var uploadedFiles = event.getParam("files");
        var fileIds = component.get("v.filesIDS") || [];
        
        uploadedFiles.forEach(function(file) {
            fileIds.push(file.documentId);
        });

    component.set("v.filesIDS", fileIds);
},

    sendEmail : function(component, event, helper) {
        helper.sendReceipt(component);
    }
})*/