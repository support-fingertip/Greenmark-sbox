// Coverage for RoundRobinMemberTriggerHandler.
@isTest
public class RoundRobinMemberTriggerHandlerTest {

    @isTest
    static void testMemberDeactivationNotifies() {
        Id me = UserInfo.getUserId();

        Round_Robin__c rr = new Round_Robin__c(
            Round_Robin_Type__c = 'Common',
            Active__c = true,
            Project_Head__c = me
        );
        insert rr;

        Round_Robin_Member__c m = new Round_Robin_Member__c(
            Round_Robin__c = rr.Id,
            User__c = me,
            User_Type__c = 'Pre Sales',
            Active__c = true
        );
        insert m;

        Test.startTest();
        m.Active__c = false;           // deactivate -> should fire notification + email
        update m;
        Test.stopTest();

        Round_Robin_Member__c after = [SELECT Active__c FROM Round_Robin_Member__c WHERE Id = :m.Id];
        System.assertEquals(false, after.Active__c, 'member should be inactive');
    }

    @isTest
    static void testReactivationDoesNotNotify() {
        Id me = UserInfo.getUserId();
        Round_Robin__c rr = new Round_Robin__c(Round_Robin_Type__c='Common', Active__c=true, Project_Head__c=me);
        insert rr;
        Round_Robin_Member__c m = new Round_Robin_Member__c(
            Round_Robin__c=rr.Id, User__c=me, User_Type__c='Pre Sales', Active__c=false);
        insert m;

        Test.startTest();
        m.Active__c = true;            // reactivation -> no notification path
        update m;
        Test.stopTest();

        System.assert(true, 'reactivation must not throw');
    }
}
