({
    initializeFiles : function(component) {

        var parentIds = component.get("v.filesIds") || [];

        // Store default parent files
        component.set("v.defaultFileIds", [...parentIds]);

        // Copy into internal list
        component.set("v.internalFileIds", [...parentIds]);

        this.getUploadedFiles(component);
    },

    getUploadedFiles : function(component) {

        var action = component.get("c.getFiles");

        action.setParams({
            recordId: component.get("v.recordId"),
            IdsList : component.get("v.internalFileIds")
        });

        action.setCallback(this, function(response){

            if(response.getState() === "SUCCESS"){

                var result = response.getReturnValue();
                var defaultIds = component.get("v.defaultFileIds") || [];

                // Mark default files
                result.forEach(function(file){
                    file.isDefault = defaultIds.includes(file.Id);
                });

                component.set("v.files", result);
            }
        });

        $A.enqueueAction(action);
    },

    deleteUploadedFile : function(component, contentDocumentId) {

        var action = component.get("c.deleteFile");

        action.setParams({
            contentDocumentId : contentDocumentId
        });

        action.setCallback(this, function(response){

            if(response.getState() === "SUCCESS"){

                var currentIds = component.get("v.internalFileIds") || [];

                currentIds = currentIds.filter(id => id !== contentDocumentId);

                component.set("v.internalFileIds", currentIds);

                this.getUploadedFiles(component);

                component.set("v.showSpinner", false);

                this.showToast("File has been deleted successfully!", "success");
            }
        });

        $A.enqueueAction(action);
    },

    showToast : function(message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            message: message,
            type: type,
            duration: 2000
        });
        toastEvent.fire();
    }
})