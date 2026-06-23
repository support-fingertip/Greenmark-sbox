public class TicketTriggerHandler {

    public static void handleAfterUpdate(
        List<Ticket__c> newList,
        Map<Id, Ticket__c> oldMap
    ) {
        // ...existing handleAfterUpdate code...
        List<Id> ticketIdsToEmail = new List<Id>();

        for (Ticket__c ticket : newList) {
            Ticket__c oldTicket = oldMap.get(ticket.Id);

            Boolean statusChangedToCompleted =
                ticket.Status__c == 'Completed'
                && oldTicket.Status__c != 'Completed';

            Boolean emailNotYetSent =
                ticket.Closure_Email_Sent__c == false
                || ticket.Closure_Email_Sent__c == null;

            if (statusChangedToCompleted && emailNotYetSent) {
                ticketIdsToEmail.add(ticket.Id);
            }
        }

        if (!ticketIdsToEmail.isEmpty()) {
            TicketClosureEmailService.sendClosureEmails(ticketIdsToEmail);
        }
    }

    // --- ADD THIS NEW METHOD BELOW ---
    public static void beforeInsert(List<Ticket__c> newTickets) {
        Set<Id> bookingIds = new Set<Id>();
        for (Ticket__c ticket : newTickets) {
            if (ticket.Booking__c != null) {
                bookingIds.add(ticket.Booking__c);
            }
        }
        if (bookingIds.isEmpty()) return;

        // Query related Booking__c records
        Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c>(
            [SELECT Id, Block_Id__c, Project1__c, Plot__c FROM Booking__c WHERE Id IN :bookingIds]
        );

        Date today = System.today();
        for (Ticket__c ticket : newTickets) {
            Booking__c booking = bookingMap.get(ticket.Booking__c);
            if (booking != null) {
                ticket.Block__c       = booking.Block_Id__c;
                ticket.Project__c     = booking.Project1__c;
                ticket.Unit__c        = booking.Plot__c;
                ticket.Raised_date__c = today;
            }
        }
    }
}