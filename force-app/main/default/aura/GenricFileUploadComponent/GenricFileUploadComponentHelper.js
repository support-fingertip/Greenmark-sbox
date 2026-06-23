({
    fetchUploadedFiles: function(component, recordId, documentName) {
        var action = component.get("c.getFiles");

        action.setParams({
            recordId: recordId,
            fileName: documentName || ''
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.contentDocIds",result);
                console.log('uploaded FIles '+ JSON.stringify(result));
            } else {
                console.log("Error fetching files: " + response.getError());
            }
        });

        $A.enqueueAction(action);
    },
    showToast: function(cmp, type, message){
        var notification = $A.get("e.force:showToast");
        notification.setParams({
            message: message,
            duration: '1000',
            type: type,
            mode: 'pester'
        });
        notification.fire();
    }
})