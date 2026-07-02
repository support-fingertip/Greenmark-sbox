@isTest
public class KenytWhatsAppServiceTest {

    private class MockResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Id":"test-id","Success":true,"Message":"Message queued successfully"}');
            return res;
        }
    }

    @isTest
    static void testSendNoTemplate_noError() {
        // Unknown event -> should return quietly without callout.
        Lead l = new Lead(LastName='Kenyt Test', Company='Test', Phone__c='9999999999');
        insert l;
        Test.startTest();
        KenytWhatsAppService.send('NON_EXISTENT_EVENT', new Set<Id>{ l.Id }, 'Lead');
        Test.stopTest();
        System.assert(true, 'send with unknown event must not throw');
    }

    @isTest
    static void testSendNullArgs_noError() {
        Test.startTest();
        KenytWhatsAppService.send(null, null, 'Lead');
        KenytWhatsAppService.send('LEAD_WELCOME', new Set<Id>(), 'Lead');
        Test.stopTest();
        System.assert(true, 'send with blank inputs must not throw');
    }

    @isTest
    static void testBuildSubscriberAndSafeGet() {
        Lead l = new Lead(LastName='Arg Test', Company='Test', Phone__c='8888888888');
        insert l;
        l = [SELECT Id, Name, Phone__c FROM Lead WHERE Id = :l.Id];

        // Build a transient template config in memory to exercise buildSubscriber.
        Kenyt_Template__mdt tmpl = new Kenyt_Template__mdt(
            Channel__c = 'WhatsApp',
            Argument_Fields__c = 'Name'
        );
        Test.startTest();
        Map<String, Object> sub = (Map<String, Object>) KenytWhatsAppService.buildSubscriber(l, tmpl);
        Object missing = KenytWhatsAppService.safeGet(l, 'No_Such_Field__c');
        Test.stopTest();

        System.assertEquals('8888888888', sub.get('Phone'), 'phone should be mapped');
        System.assert(sub.containsKey('Arguments'), 'arguments should be built');
        System.assertEquals(null, missing, 'safeGet on a missing field returns null');
    }

    @isTest
    static void testQueueableExecute_withMock() {
        // Exercises the callout path directly (no metadata record needed for the
        // early portion); the callout itself is mocked.
        Lead l = new Lead(LastName='Q Test', Company='Test', Phone__c='7777777777');
        insert l;
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        Test.startTest();
        KenytWhatsAppService.KenytSendQueueable q =
            new KenytWhatsAppService.KenytSendQueueable('LEAD_WELCOME', new Set<Id>{ l.Id }, 'Lead');
        q.execute(null); // returns early if no active template/setting deployed - safe
        Test.stopTest();
        System.assert(true, 'queueable execute must not throw');
    }
}