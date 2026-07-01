/**
 * Controller for the SiteVisitQR Visualforce page. The page URL is encoded in the
 * QR code placed on each Site Visit. When a phone camera opens the URL, this
 * controller validates that the logged-in user is the Site Visit owner, the
 * assigned GRE (Assisted_By__c) or a GRE-profile user, then redirects to the
 * record. Otherwise the page renders "Access to the record is prohibited."
 */
public with sharing class SiteVisitQRController {

    public String message { get; private set; }
    public Id siteVisitId { get; private set; }

    public SiteVisitQRController() {
        this.message = '';
    }

    /** Page action: redirect to the record when authorized, otherwise render the message. */
    public PageReference checkAccess() {
        String idParam = ApexPages.currentPage().getParameters().get('id');
        if (String.isBlank(idParam)) {
            this.message = 'Invalid or missing Site Visit reference.';
            return null;
        }
        try {
            this.siteVisitId = (Id) idParam;
            if (this.siteVisitId.getSObjectType() != Site_Visit__c.SObjectType) {
                this.message = 'Invalid Site Visit reference.';
                return null;
            }
        } catch (Exception e) {
            this.message = 'Invalid Site Visit reference.';
            return null;
        }

        if (!isAuthorized(this.siteVisitId)) {
            this.message = 'Access to the record is prohibited.';
            return null;
        }

        PageReference ref = new PageReference('/' + this.siteVisitId);
        ref.setRedirect(true);
        return ref;
    }

    /**
     * Reusable authorization check: the current user must be the Site Visit owner,
     * the assigned GRE (Assisted_By__c) or a user with the GRE profile.
     */
    public static Boolean isAuthorized(Id svId) {
        List<Site_Visit__c> svs = [
            SELECT Id, OwnerId, Assisted_By__c
            FROM Site_Visit__c
            WHERE Id = :svId
            LIMIT 1
        ];
        if (svs.isEmpty()) {
            return false;
        }
        Site_Visit__c sv = svs[0];
        Id uid = UserInfo.getUserId();
        if (sv.OwnerId == uid || sv.Assisted_By__c == uid) {
            return true;
        }
        return isGreProfile();
    }

    private static Boolean isGreProfile() {
        List<User> users = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        return !users.isEmpty() && users[0].Profile.Name == 'GRE';
    }
}

