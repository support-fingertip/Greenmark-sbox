({
    getLib: function() {
        var w = window;
        if (w.__Html5QrcodeLibrary__ && w.__Html5QrcodeLibrary__.Html5Qrcode) {
            return w.__Html5QrcodeLibrary__.Html5Qrcode;
        }
        return w.Html5Qrcode || null;
    },

    startScan: function(component) {
        component.set("v.error", null);
        this.waitForLib(component, 0);
    },

    waitForLib: function(component, attempt) {
        var Html5Qrcode = this.getLib();
        if (Html5Qrcode) {
            this.begin(component, Html5Qrcode);
            return;
        }
        if (attempt >= 50) { // ~10s
            component.set("v.error", "QR scanner failed to load. Please refresh the page and try again.");
            return;
        }
        var helper = this;
        window.setTimeout($A.getCallback(function() {
            helper.waitForLib(component, attempt + 1);
        }), 200);
    },

    begin: function(component, Html5Qrcode) {
        component.set("v.scanning", true);
        var helper = this;
        window.setTimeout($A.getCallback(function() {
            try {
                var scanner = new Html5Qrcode("qr-reader-el");
                component.set("v.instance", scanner);
                scanner.start(
                    { facingMode: "environment" },
                    { fps: 10, qrbox: 250 },
                    $A.getCallback(function(decodedText) {
                        helper.stopScanner(component, function() {
                            helper.fireEvent(component, 'scanned', decodedText);
                        });
                    }),
                    function(errorMessage) { /* per-frame decode miss - ignore */ }
                ).catch($A.getCallback(function(err) {
                    component.set("v.scanning", false);
                    component.set("v.error", "Unable to access the camera. Please allow camera permission and try again.");
                }));
            } catch (e) {
                component.set("v.scanning", false);
                component.set("v.error", "Unable to start the QR scanner.");
            }
        }), 300);
    },

    stopScanner: function(component, cb) {
        var scanner = component.get("v.instance");
        component.set("v.scanning", false);
        if (scanner) {
            scanner.stop().then($A.getCallback(function() {
                try { scanner.clear(); } catch (e) {}
                component.set("v.instance", null);
                if (cb) { cb(); }
            })).catch($A.getCallback(function() {
                component.set("v.instance", null);
                if (cb) { cb(); }
            }));
        } else if (cb) {
            cb();
        }
    },

    fireEvent: function(component, status, value) {
        var evt = component.getEvent("scanned");
        evt.setParams({ status: status, value: value });
        evt.fire();
    }
})