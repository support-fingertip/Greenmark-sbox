global class PaymentScheduleReminderScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new PendingPaymentReminderScheduler(), 1);
    }
}