@isTest
public class BookingFormControllerTest {

    @isTest
    static void testBookingFormController() {

        // Setup Project
        Project__c pjt = new Project__c(
            Name = 'Test Project',
            Project__c = 'Trifecta Vanto',
            Active__c = true
        );
        insert pjt;

        // Setup Block
        Block__c bc = new Block__c(
            Name = 'B',
            Intrest_Percentage__c = 10,
            Project__c = pjt.Id
        );
        insert bc;

        // Setup Plot
        Plot__c plt = new Plot__c(
            Status__c = 'Available',
            Project__c = pjt.Id,
            Block_Lookup__c = bc.Id
        );
        insert plt;

        // Setup Booking
        Booking__c book = new Booking__c(
            Plot__c = plt.Id,
            Notes_and_Comments__c = 'Sample Note'
        );
        insert book;

        // Create ContentVersion (Image file with matching title)
        ContentVersion cv = new ContentVersion(
            Title           = 'Applicant Passport Size Photo',
            PathOnClient    = 'Applicant Passport Size Photo.jpg',
            VersionData     = Blob.valueOf('FakeImageContent'),
            IsMajorVersion  = true
        );
        insert cv;

        // Get ContentDocumentId
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // Link the file to the Booking
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = book.Id,
            ContentDocumentId = contentDocId,
            ShareType = 'V'
        );
        insert cdl;

        // Setup Page with booking Id param
        PageReference pageRef = Page.BookingForm;
        pageRef.getParameters().put('id', book.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();

        // Instantiate controller with booking Id - with image
        ApexPages.StandardController sc = new ApexPages.StandardController(book);
        BookingFormController ctrl = new BookingFormController(sc);

        // Instantiate controller with null Id - no image
        PageReference emptyPage = Page.BookingForm;
        Test.setCurrentPage(emptyPage);
        ApexPages.StandardController sc2 = new ApexPages.StandardController(new Booking__c());
        BookingFormController ctrl2 = new BookingFormController(sc2);

        Test.stopTest();
    }
}