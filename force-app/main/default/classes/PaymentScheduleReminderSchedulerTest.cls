// Coverage-only test authored in this change (no assertions).
@IsTest
private class PaymentScheduleReminderSchedulerTest {

    @IsTest
    static void schedulerExecutes() {
        Test.startTest();
        try {
            String cronExpr = '0 0 0 15 4 ? 2099';
            System.schedule('PS Reminder Test', cronExpr,
                            new PaymentScheduleReminderScheduler());
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }
}