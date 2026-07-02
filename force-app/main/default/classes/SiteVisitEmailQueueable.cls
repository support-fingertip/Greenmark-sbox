/**
 * Class Name  : SiteVisitEmailQueueable
 * Company     : Fingertipplus
 * @description : Async wrapper that runs Site Visit email automation off the synchronous trigger
 *               transaction. Implements Database.AllowsCallouts because the 'Scheduled' QR email
 *               fetches the QR image via HTTP. Delegates to SiteVisitEmailService.
 *               Mirrors the existing WhatsappController(records, template) enqueue pattern.
 */
public class SiteVisitEmailQueueable implements Queueable, Database.AllowsCallouts {

    public static final String MODE_SCHEDULED = 'SCHEDULED';
    public static final String MODE_COMPLETED = 'COMPLETED';

    private final Set<Id> siteVisitIds;
    private final String mode;

    public SiteVisitEmailQueueable(Set<Id> siteVisitIds, String mode) {
        this.siteVisitIds = siteVisitIds;
        this.mode = mode;
    }

    public void execute(QueueableContext context) {
        if (siteVisitIds == null || siteVisitIds.isEmpty()) {
            return;
        }
        if (MODE_SCHEDULED.equals(mode)) {
            SiteVisitEmailService.sendScheduledQrEmails(siteVisitIds);
        } else if (MODE_COMPLETED.equals(mode)) {
            SiteVisitEmailService.sendFeedbackEmails(siteVisitIds);
        }
    }
}