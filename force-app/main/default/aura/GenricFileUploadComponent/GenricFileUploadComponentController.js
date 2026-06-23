({
    doInit : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        console.log('recordId :'+recordId );

        let commaSeparatedValues = component.get('v.picklistValues');

        // Convert to array and format for lightning:combobox
        let picklistOptions = commaSeparatedValues.split(',').map(value => {
            return { label: value.trim(), value: value.trim() };
        });

        picklistOptions.unshift({ label: "All", value: "" ,selected:true});

        // Set the formatted picklist values in component
        component.set("v.picklistValues", picklistOptions);

        var documentName = component.get("v.selectedDocumentName");
        console.log('documentName :'+documentName );

        if (recordId) {
            if (documentName && documentName !== '') {
                helper.fetchUploadedFiles(component, recordId, documentName);
            } else {
                helper.fetchUploadedFiles(component, recordId,'');
            }
        }
    },

    handleChange: function(component, event, helper) {
        let selectedValue = event.getParam("value");
        var recordId = component.get("v.recordId");
        console.log('selectedValue'+selectedValue);
        component.set("v.selectedDocumentName",selectedValue);
        if (recordId) {
            if (selectedValue && selectedValue !== '') {
                helper.fetchUploadedFiles(component, recordId, selectedValue);
            } else {
                helper.fetchUploadedFiles(component, recordId,'');
            }
        }
    },

    /**
     * Fires after lightning:fileUpload uploads each file chunk-by-chunk to
     * ContentVersion + creates the ContentDocumentLink for v.recordId.
     * We then hand the new ContentDocumentId(s) to Apex so the file title
     * is renamed to the picklist-selected documentName and the matching
     * Booking__c flag is flipped (Aadhaar_Uploaded__c, Pan_Uploaded__c, etc.).
     */
    handleUploadFinished: function(component, event, helper) {
        $A.util.removeClass(component.find("mySpinner"), "slds-hide");

        var uploadedFiles  = event.getParam("files") || [];
        var parentId       = component.get("v.recordId");
        var selectedDoc    = component.get("v.selectedDocumentName");
        var completed      = 0;

        if (uploadedFiles.length === 0) {
            $A.util.addClass(component.find("mySpinner"), "slds-hide");
            helper.showToast(component, 'error', 'No file uploaded');
            return;
        }

        uploadedFiles.forEach(function (f) {
            var action = component.get("c.handleUploadedFile");
            action.setParams({
                parentId: parentId,
                contentDocumentId: f.documentId,
                documentName: (selectedDoc && selectedDoc.trim() !== '')
                                  ? selectedDoc : f.name
            });
            action.setCallback(this, function (response) {
                completed++;
                if (response.getState() !== 'SUCCESS') {
                    var errs = response.getError();
                    helper.showToast(component, 'error',
                        'Post-upload processing failed: ' +
                        (errs && errs.length ? errs[0].message : 'Unknown error'));
                }
                // Only refresh + toast after the LAST file is processed
                if (completed === uploadedFiles.length) {
                    $A.util.addClass(component.find("mySpinner"), "slds-hide");
                    helper.showToast(component, 'success', 'Document Inserted Successfully');
                    helper.fetchUploadedFiles(component, parentId, selectedDoc || '');
                    $A.get('e.force:refreshView').fire();
                }
            });
            $A.enqueueAction(action);
        });
    }
})