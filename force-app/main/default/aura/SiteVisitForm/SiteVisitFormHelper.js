({
	toastMsg : function (type, title, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type": type,
            "message": msg
        });
        toastEvent.fire();
    },

    // ---------- QR camera scanning ("Search Lead with QR" tab) ----------
    // Returns the html5-qrcode constructor from whichever global the library exposed it on.
    getQrLib : function() {
        var w = window;
        if (w.__Html5QrcodeLibrary__ && w.__Html5QrcodeLibrary__.Html5Qrcode) {
            return w.__Html5QrcodeLibrary__.Html5Qrcode;
        }
        if (w.Html5Qrcode) {
            return w.Html5Qrcode;
        }
        return null;
    },

    startScan : function(component) {
        component.set("v.qrError", null);
        component.set("v.qrShowDetails", false);
        // The library is ~375KB; poll for it (it may still be loading) instead of failing immediately.
        this.waitForLibAndScan(component, 0);
    },

    waitForLibAndScan : function(component, attempt) {
        var Html5Qrcode = this.getQrLib();
        if (Html5Qrcode) {
            this.beginScan(component, Html5Qrcode);
            return;
        }
        if (attempt >= 50) { // ~10s
            component.set("v.qrError", "QR scanner failed to load. Please refresh the page and try again.");
            return;
        }
        var helper = this;
        window.setTimeout($A.getCallback(function() {
            helper.waitForLibAndScan(component, attempt + 1);
        }), 200);
    },

    beginScan : function(component, Html5Qrcode) {
        component.set("v.qrScanning", true);
        var helper = this;
        // Give the reader container a tick to render before starting the camera.
        window.setTimeout($A.getCallback(function() {
            try {
                var scanner = new Html5Qrcode("qr-reader");
                component.set("v.qrInstance", scanner);
                scanner.start(
                    { facingMode: "environment" },
                    { fps: 10, qrbox: 250 },
                    $A.getCallback(function(decodedText) {
                        helper.stopScanner(component, function() {
                            helper.processScan(component, decodedText);
                        });
                    }),
                    function(errorMessage) { /* per-frame decode miss - ignore */ }
                ).catch($A.getCallback(function(err) {
                    component.set("v.qrScanning", false);
                    component.set("v.qrError", "Unable to access the camera. Please allow camera permission and try again.");
                }));
            } catch (e) {
                component.set("v.qrScanning", false);
                component.set("v.qrError", "Unable to start the QR scanner.");
            }
        }), 300);
    },

    stopScanner : function(component, cb) {
        var scanner = component.get("v.qrInstance");
        component.set("v.qrScanning", false);
        if (scanner) {
            scanner.stop().then($A.getCallback(function() {
                try { scanner.clear(); } catch (e) {}
                component.set("v.qrInstance", null);
                if (cb) { cb(); }
            })).catch($A.getCallback(function() {
                component.set("v.qrInstance", null);
                if (cb) { cb(); }
            }));
        } else if (cb) {
            cb();
        }
    },

    // silent=true suppresses the "cancelled" message (used by Clear)
    cancelScan : function(component, silent) {
        var wasScanning = component.get("v.qrScanning");
        this.stopScanner(component, null);
        if (!silent && wasScanning) {
            component.set("v.qrError", "QR scan cancelled.");
        }
    },

    processScan : function(component, decodedText) {
        var helper = this;
        component.set("v.isLoading", true);
        var action = component.get("c.getLeadIdFromScan");
        action.setParams({ "scannedValue": decodedText });
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                helper.loadLead(component, response.getReturnValue());
            } else {
                component.set("v.isLoading", false);
                component.set("v.qrError", helper.errMsg(response, "Invalid QR Code."));
            }
        });
        $A.enqueueAction(action);
    },

    loadLead : function(component, leadId) {
        var helper = this;
        var action = component.get("c.getLead");
        action.setParams({ "leadId": leadId });
        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);
            if (response.getState() === "SUCCESS") {
                var rv = response.getReturnValue();
                component.set("v.leadRecord", rv.Lead);
                component.set("v.leadId", leadId);
                component.set("v.siteVisit", rv.siteVisit);
                component.set("v.qrShowDetails", true);
                component.set("v.qrError", null);
            } else {
                component.set("v.qrError", helper.errMsg(response, "Lead not found."));
            }
        });
        $A.enqueueAction(action);
    },

    errMsg : function(response, fallback) {
        var errs = response.getError();
        if (errs && errs[0] && errs[0].message) { return errs[0].message; }
        return fallback;
    },

    createSitevisit : function(component, event, helper,leadId)
    {
        var siteVisitComments = component.get("v.siteVisitComments");
        var selectedRating = component.get("v.selectedRating");
        
        var action = component.get("c.leadNotExists");
        action.setParams({
            "leadId" : leadId,
            "selectedRating": selectedRating,
            "remark": siteVisitComments,
            "salesUser": component.get("v.salesUserId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                component.set('v.isLoading',false);
                var selected = '1';
                component.find("tabs").set("v.selectedTabId", selected);
                component.set("v.otpStatus",null);
                component.set("v.showDetails",false);
                component.set("v.selectedProject",'None');
                component.set("v.phone",'');
                component.set("v.leadId",'');
            }else{
                helper.toastMsg('Error','Error','Something Went Wrong')
            }
        });
        $A.enqueueAction(action);
    }
})