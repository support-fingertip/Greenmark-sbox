@isTest
private class AgreementReminderSchedulerTest {
    @testSetup
    static void setupTestData() {
        Project__c proj = new Project__c(
            Name = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c = true
        );
        insert proj;

        Plot__c plot = new Plot__c(
            Name = 'P1',
            Status__c = 'Available',
            Project__c = proj.Id
        );
        insert plot;

        // User for CRM Executive
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'CRM Executive' LIMIT 1];
        User crmUser = new User(
            FirstName = 'CRM',
            LastName = 'Executive',
            Email = 'crmexec@example.com',
            Username = 'crmexec' + String.valueOf(DateTime.now().getTime()) + '@example.com',
            Alias = 'crmexec',
            ProfileId = prof.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert crmUser;

        // Find OrgWideEmailAddress for templates/emails
        OrgWideEmailAddress owEmail = [SELECT Id, Address FROM OrgWideEmailAddress LIMIT 1];

        // Booking__c only writeable fields!
        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'Test Applicant',
            Email__c = 'customer@example.com',
            Agreement_Extension_Approved_Date__c = Date.today(),
            CRM_Executive__c = crmUser.Id,
            Plot__c = plot.Id,
            Time_Extension_Requested__c = true,
            Time_Extension_Approval_Status__c = 'Approved',
            Project1__c = proj.Id,
            Agreement_Status__c = 'Not Scheduled',
            Stage__c = 'Booked',
            CRM_Head__c = crmUser.Id,
            Sales_Head__c = crmUser.Id,
            COO__c = crmUser.Id,
            Disable_Automatic_Agreement_Reminders__c = false
        );
        insert booking;

        General_Settings__c template = new General_Settings__c(
            Template_Body__c = 'Dear ##APPLICANT_NAME##, Welcome to ##PROJECT_NAME##.',
            Subject__c = 'Agreement reminder for ##PROJECT_NAME##',
            Type__c = 'Agreement Remainder',
            Project_Name1__c = proj.Name
        );
        insert template;
    }

    @isTest
    static void testAgreementReminderSchedulerExecute() {
        Test.startTest();
        AgreementReminderScheduler scheduler = new AgreementReminderScheduler();
        scheduler.execute(null);
        Test.stopTest();
    }
}