@isTest
public class RoundRobinUsersViewTest {

    @isTest
    Public static void testRoundRobinMethods() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Pre Sales' LIMIT 1];
         

        User u = new User(
            ProfileId = p.Id,
            LastName = 'RH23',
            Email = 'RH@gm1ail.com',
            Username = 'RH@1gmail.com' + System.currentTimeMillis(),
            CompanyName = 'RH1',
            Title = 'titletitl1e',
            Alias = 'lokma1n',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Availability__c = true,
            IsActive = true,
            is_working__c = true
        );
        insert u;

 User u1 = new User(
            ProfileId = p.Id,
            LastName = 'RH23',
            Email = 'RH@gm2ail.com',
            Username = 'RH2@1gmail.com' + System.currentTimeMillis(),
            CompanyName = 'RH1',
            Title = 'titletitl1e',
            Alias = 'lokma2n',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Availability__c = false,
            
            IsActive = true,
            is_working__c = true
        );
        insert u1;

        
        Round_Robin__c r = new Round_Robin__c(
         Active__c = true,
                Project_Assigned__c = 'Trifecta Vanto',
                Lead_Source_Type__c = 'Digital Marketing',
                Project_Head__c = u.Id
        );
        insert r;
        
        List<Round_Robin_Member__c> testMembers = new List<Round_Robin_Member__c>();
        Round_Robin_member__c rrm = new Round_Robin_member__c(
                Round_Robin__c = r.Id,
                Active__c = true,
                User__c = u.Id,
                User_Type__c = 'Pre Sales'
            );
            insert rrm;
        testMembers.add(rrm);

            Round_Robin_member__c rrm1 = new Round_Robin_member__c(
                Round_Robin__c = r.Id,
                Active__c = true,
                User__c = u1.Id,
                User_Type__c = 'Sales'
            );
            insert rrm1;
           testMembers.add(rrm1);

        
        List<Round_Robin_Member__c> result1 = RoundRobinUsersView.fetchRoundRobinMembers(r.Id);
        
        for(Round_Robin_Member__c member : result1) {
            System.assertEquals(true, member.Active__c, 'Round Robin Member should be active');
        }
        
        Round_Robin_Member__c testMember = testMembers[0];
        List<Round_Robin_Member__c> updatedMembers;
        
        updatedMembers = RoundRobinUsersView.toggleMemberStatus(testMember.Id, r.Id);
        Round_Robin_Member__c updatedMember = updatedMembers[0];
        
        updatedMembers = RoundRobinUsersView.toggleMemberStatus(testMember.Id, r.Id);
        updatedMember = updatedMembers[0];
    }
}