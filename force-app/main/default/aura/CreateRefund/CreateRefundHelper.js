({
    toastMsg: function(type, title, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": type,
            "title": title,
            "message": msg,
            "duration": 6000
        });
        toastEvent.fire();
    },

    getErrorMessage: function(response) {
        var errors = response.getError();
        if (errors && errors[0] && errors[0].message) {
            return errors[0].message;
        }
        return "An unexpected error occurred.";
    }
})