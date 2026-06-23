({
	Toast: function (type, title, msg) 
    {
        var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": title,
                    "message": msg,
                    "type":type
                });
                toastEvent.fire();
    }
})