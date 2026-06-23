public class WelcomeCallReminderScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new WelcomeCallReminderBatch(), 50);
    }
}