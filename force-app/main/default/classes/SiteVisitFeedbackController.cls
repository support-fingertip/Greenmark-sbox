/**
 * Class Name  : SiteVisitFeedbackController
 * Company     : Fingertipplus
 * @description : Controller for the public SiteVisitFeedback Visualforce page. Loads the Site Visit
 *               referenced by the ?id= parameter, lets the customer enter a Rating (1-5) and Feedback,
 *               and on Submit saves them to Customer_Rating__c / Customer_Feedback__c on the record.
 *               Declared 'without sharing' so a Site guest user (wired by the admin) can read/update
 *               the target record addressed by Id.
 */
public without sharing class SiteVisitFeedbackController {

    public Site_Visit__c siteVisit { get; private set; }
    public Boolean recordFound { get; private set; }
    public Boolean submitted { get; private set; }

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
                SELECT Id, Name, Customer_Rating__c, Customer_Feedback__c
                FROM Site_Visit__c
                WHERE Id = :svId
                LIMIT 1
            ];
            if (svs.isEmpty()) {
                addError('Site Visit not found.');
                return;
            }
            this.siteVisit = svs[0];
            this.recordFound = true;
        } catch (Exception e) {
            addError('Invalid Site Visit reference.');
        }
    }

    /** Saves the rating and feedback to the Site Visit record. */
    public PageReference submit() {
        if (!recordFound || siteVisit == null) {
            addError('Unable to submit feedback: the Site Visit could not be found.');
            return null;
        }
        Decimal rating = siteVisit.Customer_Rating__c;
        if (rating == null || rating < 1 || rating > 5) {
            addError('Please provide a rating between 1 and 5.');
            return null;
        }
        try {
            update siteVisit;
            this.submitted = true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'SiteVisitFeedbackController.submit failed: ' + e.getMessage());
            addError('We could not save your feedback. Please try again later.');
        }
        return null;
    }

    private void addError(String message) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
    }
}

