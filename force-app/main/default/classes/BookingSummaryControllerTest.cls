@isTest
public class BookingSummaryControllerTest {

    @isTest
    static void testBookingSummaryControllerMethods() {

        // Setup Project
        Project__c pjt = new Project__c(
            Name       = 'Test Project',
            Project__c = 'Trifecta Vanto',
            Active__c  = true
        );
        insert pjt;

        // Setup Block
        Block__c bc = new Block__c(
            Name                  = 'B',
            Intrest_Percentage__c = 10,
            Project__c            = pjt.Id
        );
        insert bc;

        // Setup Plot
        Plot__c plt = new Plot__c(
            Status__c       = 'Available',
            Project__c      = pjt.Id,
            Block_Lookup__c = bc.Id
        );
        insert plt;

        // Setup Booking
        Booking__c book = new Booking__c(
            Plot__c               = plt.Id,
            Notes_and_Comments__c = 'Sample Note'
        );
        insert book;

        String testNote1 = 'Note One';
        String testNote2 = 'Note Two';
        String testNote3 = 'Note Three';

        Test.startTest();

        // 1. updateLastNote - Booking_Summary__c is null (first note)
        BookingSummaryController.updateLastNote(book.Id, testNote1);

        // 2. updateLastNote - Booking_Summary__c already has content (second note)
        BookingSummaryController.updateLastNote(book.Id, testNote2);

        // 3. updateLastNote - third note to increment noteCount further
        BookingSummaryController.updateLastNote(book.Id, testNote3);

        // 4. fetchLeadLastNotes - booking has multiple notes
        BookingSummaryController.fetchLeadLastNotes(book.Id);

        // 5. fetchLeadLastNotes - booking with null summary
        Booking__c book2 = new Booking__c(
            Plot__c               = plt.Id,
            Notes_and_Comments__c = 'Sample Note 2'
        );
        insert book2;
        BookingSummaryController.fetchLeadLastNotes(book2.Id);

        Test.stopTest();
    }
}