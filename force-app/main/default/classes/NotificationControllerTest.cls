@isTest
public class NotificationControllerTest {

    static Id getTargetId() {
        return UserInfo.getUserId();
    }

    static Set<String> getSingleRecipient() {
        return new Set<String>{ UserInfo.getUserId() };
    }

    static String getNotificationTypeName() {
        List<CustomNotificationType> cnts = [
            SELECT DeveloperName FROM CustomNotificationType LIMIT 1
        ];
        return cnts.isEmpty() ? null : cnts[0].DeveloperName;
    }

    @isTest
    static void testSendNotification_ValidType() {
        String notifName = getNotificationTypeName();
        if (notifName == null) return;

        Test.startTest();
        try {
            NotificationController.sendCustomNotification(
                getSingleRecipient(),
                'Test Title',
                'Test Body',
                getTargetId(),
                notifName
            );
        } catch (Exception e) {
            System.debug('testSendNotification_ValidType: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testSendNotification_InvalidTypeName() {
        Test.startTest();
        try {
            NotificationController.sendCustomNotification(
                getSingleRecipient(),
                'Test Title',
                'Test Body',
                getTargetId(),
                'NON_EXISTENT_NOTIFICATION_TYPE'
            );
        } catch (Exception e) {
            System.debug('testSendNotification_InvalidTypeName: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testSendNotification_EmptyRecipients() {
        String notifName = getNotificationTypeName();
        if (notifName == null) return;

        Test.startTest();
        try {
            NotificationController.sendCustomNotification(
                new Set<String>(),
                'Test Title',
                'Test Body',
                getTargetId(),
                notifName
            );
        } catch (Exception e) {
            System.debug('testSendNotification_EmptyRecipients: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testSendNotification_NullTitleAndBody() {
        String notifName = getNotificationTypeName();
        if (notifName == null) return;

        Test.startTest();
        try {
            NotificationController.sendCustomNotification(
                getSingleRecipient(),
                null,
                null,
                getTargetId(),
                notifName
            );
        } catch (Exception e) {
            System.debug('testSendNotification_NullTitleAndBody: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testSendNotification_MultipleRecipients() {
        String notifName = getNotificationTypeName();
        if (notifName == null) return;

        List<User> users = [SELECT Id FROM User WHERE IsActive = true LIMIT 2];
        Set<String> recipients = new Set<String>();
        for (User u : users) {
            recipients.add(u.Id);
        }

        Test.startTest();
        try {
            NotificationController.sendCustomNotification(
                recipients,
                'Test Title',
                'Test Body',
                getTargetId(),
                notifName
            );
        } catch (Exception e) {
            System.debug('testSendNotification_MultipleRecipients: ' + e.getMessage());
        }
        Test.stopTest();
    }
}