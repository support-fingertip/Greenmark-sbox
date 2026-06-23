@isTest
public class DialercontrollerTest {
 @isTest
    public static void testDialerController() {

      
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 2; i++) {
            leads.add(new Lead(
                LastName = 'TestLead' + i,
                Company  = 'TestCo',
                Source_Type__c = 'Google'
            ));
        }
        insert leads;


        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            massdialerIds__c = ''   // required custom field
        );
        insert u;


        System.runAs(u) {

            
            ApexPages.StandardSetController ssc =
                new ApexPages.StandardSetController(leads);

          
            ssc.setSelected(leads);

           
            Dialercontroller dc = new Dialercontroller(ssc);

         
            PageReference pRef = dc.direct();

            User updatedUser = [SELECT massdialerIds__c FROM User WHERE Id = :u.Id];

            System.assertNotEquals('', updatedUser.massdialerIds__c, 'Lead IDs should be stored');
            System.assert(pRef != null, 'PageReference should not be null');
            System.assert(
                pRef.getUrl().contains('/lightning/n/Dialer'),
                'Redirect URL should point to lightning Dialer page'
            );

        }
    }
}