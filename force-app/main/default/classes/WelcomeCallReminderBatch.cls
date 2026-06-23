public class WelcomeCallReminderBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
            SELECT Id, Name, Owner.Email,CRM_Head_Manager_Email__c,
                   Welcome_Call_Done__c, Passed_Hour_after_Booked_Stage__c
            FROM Booking__c
            WHERE Welcome_Call_Done__c = FALSE
              AND Passed_Hour_after_Booked_Stage__c >= 48
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Booking__c> scope) {

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Booking__c b : scope) {
            if (b.Owner.Email != null) {

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[] { b.Owner.Email,b.CRM_Head_Manager_Email__c });
                
                email.setSubject('Reminder: Welcome Call Pending for Booking ' + b.Name);
                
                email.setPlainTextBody(
                    'Hello,' + '\n\n' +
                    'This is a reminder that the welcome call has not been completed.' + '\n\n' +
                    'Booking Name: ' + b.Name + '\n' +
                    'Hours Passed Since Booked Stage: ' + b.Passed_Hour_after_Booked_Stage__c + '\n\n' +
                    'Please take necessary action.' + '\n\n' +
                    'Regards,' + '\n' +
                    'Salesforce System'
                );

                emails.add(email);
            }
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    public void finish(Database.BatchableContext bc) {}
}