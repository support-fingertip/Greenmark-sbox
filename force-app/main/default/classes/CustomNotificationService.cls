public class CustomNotificationService {
    
    public static void notificationSend(String notifyTitle,id notifyId,string notificationBody,set<string> targetUserIds,string notificationId){
        
        if (targetUserIds == null || targetUserIds.isEmpty()) return;
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle(notifyTitle);
        notification.setNotificationTypeId(notificationId);
        notification.setTargetId(notifyId);
        notification.setBody(notificationBody);
        notification.send(targetUserIds);
        
    }
    
}