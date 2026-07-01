/**
 * KenytWhatsAppService
 * --------------------
 * Sends template-based WhatsApp/SMS/Email messages through the Kenyt.AI
 * Campaigns Messaging API (BRD 4.12.2 - up to 10 automated scenarios).
 *
 * Configuration is fully metadata-driven:
 *   - Kenyt_Setting__mdt 'Default'  -> connection (Base URL, Auth Token, Org Id, default Bot Id)
 *   - Kenyt_Template__mdt per Event -> template name, bot id, channel, argument field mapping
 *
 * Usage (from a trigger handler):
 *   KenytWhatsAppService.send('LEAD_WELCOME', leadIds, 'Lead');
 *
 * The actual HTTP callout runs asynchronously via Queueable so it can be
 * enqueued safely from a trigger context.
 */
public without sharing class KenytWhatsAppService {

    public class KenytException extends Exception {}

    /**
     * Entry point - enqueue a send for the given records and event.
     * @param eventKey   matches Kenyt_Template__mdt.Event__c
     * @param recordIds  ids of the source records (Lead, Site_Visit__c, Booking__c, ...)
     * @param objectName API name of the source object
     */
    public static void send(String eventKey, Set<Id> recordIds, String objectName) {
        if (String.isBlank(eventKey) || recordIds == null || recordIds.isEmpty()) {
            return;
        }
        Kenyt_Template__mdt tmpl = getTemplate(eventKey);
        if (tmpl == null || tmpl.Active__c != true) {
            System.debug('Kenyt: no active template for event ' + eventKey);
            return;
        }
        if (!System.isBatch() && !System.isFuture() && !System.isQueueable()) {
            System.enqueueJob(new KenytSendQueueable(eventKey, recordIds, objectName));
        } else {
            // already async - run inline
            new KenytSendQueueable(eventKey, recordIds, objectName).execute(null);
        }
    }

    /** Looks up the active template config for an event. */
    public static Kenyt_Template__mdt getTemplate(String eventKey) {
        for (Kenyt_Template__mdt t : Kenyt_Template__mdt.getAll().values()) {
            if (t.Event__c == eventKey) {
                return t;
            }
        }
        return null;
    }

    /** Loads the single connection settings record. */
    public static Kenyt_Setting__mdt getSetting() {
        Kenyt_Setting__mdt s = Kenyt_Setting__mdt.getInstance('Default');
        if (s == null) {
            throw new KenytException('Kenyt_Setting__mdt "Default" record is not configured.');
        }
        return s;
    }

    /** Builds the recipient + Arguments[] payload for one record. */
    @TestVisible
    private static Map<String, Object> buildSubscriber(SObject record, Kenyt_Template__mdt tmpl) {
        Map<String, Object> sub = new Map<String, Object>();

        // Recipient field by channel
        String channel = String.isBlank(tmpl.Channel__c) ? 'WhatsApp' : tmpl.Channel__c;
        if (channel == 'Email') {
            sub.put('Email', (String) safeGet(record, 'Email'));
        } else {
            // WhatsApp / SMS -> phone. Prefer Phone__c, fall back to standard Phone.
            Object phone = safeGet(record, 'Phone__c');
            if (phone == null) { phone = safeGet(record, 'Phone'); }
            sub.put('Phone', phone == null ? null : String.valueOf(phone));
        }
        Object nm = safeGet(record, 'Name');
        if (nm != null) { sub.put('Name', String.valueOf(nm)); }

        // Arguments from the configured ordered field list
        if (String.isNotBlank(tmpl.Argument_Fields__c)) {
            List<String> args = new List<String>();
            for (String f : tmpl.Argument_Fields__c.split(',')) {
                Object v = safeGet(record, f.trim());
                args.add(v == null ? '' : String.valueOf(v));
            }
            sub.put('Arguments', args);
        }
        return sub;
    }

    /** Null-safe field accessor that tolerates missing fields. */
    @TestVisible
    private static Object safeGet(SObject record, String fieldPath) {
        try {
            return record.get(fieldPath);
        } catch (Exception e) {
            return null;
        }
    }

    /** Queueable that performs the HTTP callout(s). */
    public class KenytSendQueueable implements Queueable, Database.AllowsCallouts {
        private String eventKey;
        private Set<Id> recordIds;
        private String objectName;

        public KenytSendQueueable(String eventKey, Set<Id> recordIds, String objectName) {
            this.eventKey = eventKey;
            this.recordIds = recordIds;
            this.objectName = objectName;
        }

        public void execute(QueueableContext ctx) {
            Kenyt_Template__mdt tmpl = getTemplate(eventKey);
            if (tmpl == null || tmpl.Active__c != true) { return; }
            Kenyt_Setting__mdt cfg = getSetting();
            if (String.isBlank(cfg.Base_URL__c) || String.isBlank(cfg.Auth_Token__c)) {
                System.debug('Kenyt: connection settings incomplete; skipping send.');
                return;
            }

            // Query the source records for the fields the template needs.
            List<SObject> records = queryRecords(tmpl);
            if (records.isEmpty()) { return; }

            String botId = String.isNotBlank(tmpl.Bot_Id__c) ? tmpl.Bot_Id__c : cfg.Default_Bot_Id__c;

            // Build subscribers
            List<Object> subscribers = new List<Object>();
            for (SObject rec : records) {
                subscribers.add(buildSubscriber(rec, tmpl));
            }

            Map<String, Object> payload = new Map<String, Object>{
                'TemplateName' => tmpl.Template_Name__c,
                'BotId' => botId
            };
            if (String.isNotBlank(tmpl.Attachment_Links__c)) {
                List<String> links = new List<String>();
                for (String l : tmpl.Attachment_Links__c.split(',')) { links.add(l.trim()); }
                payload.put('AttachmentLinks', links);
            }

            String endpoint;
            if (subscribers.size() == 1) {
                // /send-message - single recipient (flatten subscriber into payload)
                payload.putAll((Map<String, Object>) subscribers[0]);
                endpoint = '/dashboardApi/api/crm/send-message';
            } else {
                payload.put('Subscribers', subscribers);
                endpoint = '/dashboardApi/api/crm/send-bulk-message';
            }

            doCallout(cfg, endpoint, JSON.serialize(payload));
        }

        private List<SObject> queryRecords(Kenyt_Template__mdt tmpl) {
            Set<String> fields = new Set<String>{ 'Id', 'Name' };
            // recipient fields
            if (fieldExists(objectName, 'Phone__c')) { fields.add('Phone__c'); }
            if (fieldExists(objectName, 'Phone'))    { fields.add('Phone'); }
            if (fieldExists(objectName, 'Email'))    { fields.add('Email'); }
            if (String.isNotBlank(tmpl.Argument_Fields__c)) {
                for (String f : tmpl.Argument_Fields__c.split(',')) {
                    String fn = f.trim();
                    if (fieldExists(objectName, fn)) { fields.add(fn); }
                }
            }
            String soql = 'SELECT ' + String.join(new List<String>(fields), ',') +
                          ' FROM ' + objectName + ' WHERE Id IN :recordIds';
            return Database.query(soql);
        }

        private Boolean fieldExists(String objApi, String fieldApi) {
            SObjectType t = Schema.getGlobalDescribe().get(objApi);
            if (t == null) { return false; }
            return t.getDescribe().fields.getMap().containsKey(fieldApi.toLowerCase());
        }

        private void doCallout(Kenyt_Setting__mdt cfg, String endpoint, String body) {
            String url = cfg.Base_URL__c.removeEnd('/') + endpoint +
                         '?authToken=' + EncodingUtil.urlEncode(cfg.Auth_Token__c, 'UTF-8') +
                         '&organizationId=' + EncodingUtil.urlEncode(String.valueOf(cfg.Organization_Id__c), 'UTF-8');
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setBody(body);
            req.setTimeout(60000);
            try {
                HttpResponse res = new Http().send(req);
                System.debug('Kenyt response [' + res.getStatusCode() + ']: ' + res.getBody());
            } catch (Exception e) {
                System.debug('Kenyt callout failed: ' + e.getMessage());
            }
        }
    }
}