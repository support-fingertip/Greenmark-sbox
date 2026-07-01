import { LightningElement, api } from 'lwc';
import { getBarcodeScanner } from 'lightning/mobileCapabilities';

/**
 * Mobile-only QR scanner. Uses the Salesforce mobile app's native barcode
 * scanner (lightning/mobileCapabilities). Embedded by the SiteVisitForm Aura
 * component; the parent "Scan QR" button calls startScan(), and the decoded
 * value is sent back via the "scanned" event. Business logic lives in the
 * parent — this component only replaces the scanning mechanism.
 */
export default class QrScannerMobile extends LightningElement {
    scanner;

    connectedCallback() {
        this.scanner = getBarcodeScanner();
    }

    @api
    startScan() {
        if (!this.scanner || !this.scanner.isAvailable()) {
            this.fire('error', null, 'QR scanning is only available in the Salesforce mobile app.');
            return;
        }
        const options = {
            barcodeTypes: [this.scanner.barcodeTypes.QR],
            instructionText: "Scan the customer's Site Visit QR code",
            successText: 'QR captured.'
        };
        this.scanner
            .beginCapture(options)
            .then((result) => {
                this.fire('scanned', result.value, null);
            })
            .catch((error) => {
                if (error && error.code === 'userDismissedScanner') {
                    this.fire('cancelled', null, null);
                } else {
                    this.fire('error', null, error && error.message ? error.message : 'Unable to scan the QR code.');
                }
            })
            .finally(() => {
                this.scanner.endCapture();
            });
    }

    @api
    reset() {
        if (this.scanner) {
            try {
                this.scanner.endCapture();
            } catch (e) {
                /* no active capture */
            }
        }
    }

    fire(status, value, message) {
        this.dispatchEvent(
            new CustomEvent('scanned', {
                detail: { status: status, value: value, message: message }
            })
        );
    }
}
