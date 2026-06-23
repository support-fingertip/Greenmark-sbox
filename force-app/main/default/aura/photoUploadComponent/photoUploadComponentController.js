({
    doInit : function(component, event, helper) {
        helper.initializeFiles(component);
    },

    syncParentFiles : function(component, event, helper) {
        helper.initializeFiles(component);
    },

    previewFile : function(component, event, helper) {
        $A.get('e.lightning:openFiles').fire({
            recordIds: [event.currentTarget.id]
        });
    },

    uploadFinished : function(component, event, helper) {

        var uploadedFiles = event.getParam("files");
        var newIds = uploadedFiles.map(file => file.documentId);

        var existingIds = component.get("v.internalFileIds") || [];

        // Merge without duplicates
        var mergedIds = existingIds.concat(
            newIds.filter(id => !existingIds.includes(id))
        );

        component.set("v.internalFileIds", mergedIds);

        helper.getUploadedFiles(component);

        // Notify parent
        var fileUploadEvent = component.getEvent("fileUploadEvent");
        fileUploadEvent.setParams({ "files": mergedIds });
        fileUploadEvent.fire();

        helper.showToast("Files have been uploaded successfully!", "success");
    },

    deleteSelectedFile : function(component, event, helper) {
        if(confirm("Confirm deleting this file?")){
            component.set("v.showSpinner", true);
            helper.deleteUploadedFile(component, event.currentTarget.id);
        }
    }
})