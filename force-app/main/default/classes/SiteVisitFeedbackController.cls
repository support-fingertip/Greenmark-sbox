/**
 * Class Name  : SiteVisitFeedbackController
 * Company     : Fingertipplus
 * @description : Controller for the public SiteVisitFeedback Visualforce page. Loads the Site Visit
 *               referenced by the ?id= parameter and lets the customer enter a 1-5 Rating and
 *               Feedback. On Submit it saves them to Customer_Rating__c / Customer_Feedback__c.
 *
 *               Guest-safe by design: the page binds to plain controller properties (not
 *               apex:inputField), so no field-level security is required for the Site guest user,
 *               and the record update runs in Apex system context. Declared 'without sharing' so a
 *               guest user can update the record addressed by Id even though it is not shared to them.
 */
public without sharing class SiteVisitFeedbackController {

    public static final Integer MAX_FEEDBACK_LENGTH = 1000;

    public Id siteVisitId { get; private set; }
    public String siteVisitName { get; private set; }
    public Boolean recordFound { get; private set; }
    public Boolean submitted { get; private set; }

    // Bound to the page inputs (kept as String so the guest form posts back cleanly).
    public String ratingValue { get; set; }
    public String feedbackText { get; set; }

    public Integer maxFeedbackLength { get { return MAX_FEEDBACK_LENGTH; } }

    public SiteVisitFeedbackController() {
        this.recordFound = false;
        this.submitted = false;
        loadRecord();
    }

    private void loadRecord() {
        String idParam = ApexPages.currentPage().getParameters().get('id');
        if (String.isBlank(idParam)) {
            addError('Invalid or missing Site Visit reference.');
            return;
        }
        try {
            Id svId = (Id) idParam;
            if (svId.getSObjectType() != Site_Visit__c.SObjectType) {
                addError('Invalid Site Visit reference.');
                return;
            }
            List<Site_Visit__c> svs = [
                SELECT Id, Name
                FROM Site_Visit__c
                WHERE Id = :svId
                LIMIT 1
            ];
            if (svs.isEmpty()) {
                addError('Site Visit not found.');
                return;
            }
            this.siteVisitId = svs[0].Id;
            this.siteVisitName = svs[0].Name;
            this.recordFound = true;
        } catch (Exception e) {
            addError('Invalid Site Visit reference.');
        }
    }

    /** Saves the rating and feedback to the Site Visit record. */
    public PageReference submit() {
        if (!recordFound || siteVisitId == null) {
            addError('Unable to submit feedback: the Site Visit could not be found.');
            return null;
        }
        Integer rating = parseRating(ratingValue);
        if (rating == null || rating < 1 || rating > 5) {
            addError('Please select a rating between 1 and 5.');
            return null;
        }
        if (String.isBlank(feedbackText)) {
            addError('Please share your feedback before submitting.');
            return null;
        }
        String feedback = feedbackText.length() > MAX_FEEDBACK_LENGTH
            ? feedbackText.substring(0, MAX_FEEDBACK_LENGTH)
            : feedbackText;

        try {
            update new Site_Visit__c(
                Id = siteVisitId,
                Customer_Rating__c = rating,
                Customer_Feedback__c = feedback
            );
            this.submitted = true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'SiteVisitFeedbackController.submit failed: ' + e.getMessage());
            addError('We could not save your feedback. Please try again later.');
        }
        return null;
    }

    private Integer parseRating(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        try {
            return Integer.valueOf(value.trim());
        } catch (Exception e) {
            return null;
        }
    }

    private void addError(String message) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
    }
}
