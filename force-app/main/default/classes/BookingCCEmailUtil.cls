public class BookingCCEmailUtil {
    /**
     * Returns the set of CC email addresses for a Booking:
     * the CRM Head, CRM Manager, Project Sales Head and Sales Head user emails,
     * the Booking Owner email, plus any emails configured in Custom Label CCEmailIds.
     * Blank values are filtered out, the result is de-duplicated and never null.
     *
     * The supplied Booking must be queried with these fields:
     *   CRM_Head__c, CRM_Head__r.Email, CRM_Manager__c, CRM_Manager__r.Email,
     *   Project_Sales_Head__c, Project_Sales_Head__r.Email,
     *   Sales_Head__c, Sales_Head__r.Email, OwnerId, Owner.Email
     */
    public static Set<String> getCCEmails(Booking__c bk) {
        Set<String> ccs = new Set<String>();
        if (bk == null) {
            return ccs;
        }
        if (bk.CRM_Head__c != null && String.isNotBlank(bk.CRM_Head__r.Email)) {
            ccs.add(bk.CRM_Head__r.Email);
        }
        if (bk.CRM_Manager__c != null && String.isNotBlank(bk.CRM_Manager__r.Email)) {
            ccs.add(bk.CRM_Manager__r.Email);
        }
        if (bk.Project_Sales_Head__c != null && String.isNotBlank(bk.Project_Sales_Head__r.Email)) {
            ccs.add(bk.Project_Sales_Head__r.Email);
        }
        if (bk.Sales_Head__c != null && String.isNotBlank(bk.Sales_Head__r.Email)) {
            ccs.add(bk.Sales_Head__r.Email);
        }
        if (bk.OwnerId != null && String.isNotBlank(bk.Owner.Email)) {
            ccs.add(bk.Owner.Email);
        }

        // Getting the CC Emails from Custom Label
        String ccEmailLabel = Label.CCEmailIds;
        if (String.isNotBlank(ccEmailLabel)) {
            for (String email : ccEmailLabel.split(',')) {
                if (String.isNotBlank(email)) {
                    ccs.add(email.trim());
                }
            }
        }
        return ccs;
    }
}