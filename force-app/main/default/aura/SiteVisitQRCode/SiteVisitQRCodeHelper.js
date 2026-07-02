({
    toast: function(title, message, variant) {
        var evt = $A.get("e.force:showToast");
        if (evt) {
            evt.setParams({ title: title, message: message, type: variant });
            evt.fire();
        }
    },

    getError: function(response, fallback) {
        var errors = response.getError();
        if (errors && errors[0] && errors[0].message) {
            return errors[0].message;
        }
        return fallback;
    }
})