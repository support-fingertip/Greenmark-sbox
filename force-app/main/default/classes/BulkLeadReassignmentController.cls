public with sharing class BulkLeadReassignmentController {

    // ─── Wrapper for init data ───
    public class InitWrapper {
        @AuraEnabled public Map<String, String> projectValues { get; set; }
        @AuraEnabled public Map<String, String> leadStatusValues { get; set; }
        @AuraEnabled public Map<String, String> leadSourceValues { get; set; }
        @AuraEnabled public List<User> allUserList { get; set; }
        @AuraEnabled public List<User> activeUserList { get; set; }
    }

    // ─── Profiles to exclude from user lists ───
    private static final Set<String> EXCLUDED_PROFILES = new Set<String>{
        'LeadInsert Profile',
        'Sales Insights Integration User',
        'SalesforceIQ Integration User',
        'Minimum Access - API Only Integrations',
        'Standard User',
        'Call Profile',
        'Pulse Profile',
        'Integration with WA Profile'
    };

    // ─── 1. Get all init values (picklists + users) ───
    @AuraEnabled(cacheable=true)
    public static InitWrapper getDoInitValues() {
        InitWrapper wrapper = new InitWrapper();

        // Picklist values
        wrapper.projectValues = getPicklistMap(Lead.Allocated_Project__c);
        wrapper.leadStatusValues = getPicklistMap(Lead.Lead_Status__c);
        wrapper.leadSourceValues = getPicklistMap(Lead.Source_Type__c);

        // All users (including inactive) excluding system profiles
        wrapper.allUserList = [
            SELECT Id, Name, Profile.Name, IsActive
            FROM User
            WHERE Profile.Name NOT IN :EXCLUDED_PROFILES
            ORDER BY Name
        ];

        // Active users only
        wrapper.activeUserList = [
            SELECT Id, Name, Profile.Name, IsActive
            FROM User
            WHERE IsActive = TRUE
            AND Profile.Name NOT IN :EXCLUDED_PROFILES
            ORDER BY Name
        ];

        return wrapper;
    }

    // ─── 2. Get filtered leads ───
    @AuraEnabled
    public static List<Lead> getFilteredLeads(
        String currentUserId,
        String projectId,
        String leadStatus,
        String leadSource,
        Date fromCreatedDate,
        Date toCreatedDate,
        String batchcode,
        String subSource,
        Date fromAllocationDate,
        Date toAllocationDate,
        Date fromSiteVisitDate,
        Date toSiteVisitDate,
        Date fromFollowUpDate,
        Date toFollowUpDate,
        String phoneNumber,
        String followupSubject
    ) {
        String fields = 'Id, Name, Allocated_Project__c, Created_Date__c, Lead_Record_Type__c, '
                       + 'Phone__c, Lead_source__c, Lead_Status__c, CreatedDate, '
                       + 'Lead_ID__c, OwnerId, Lead_Owner_Full_Name__c, Campaign__c, Pushed_On__c, Sub_Source__c, Source_Type__c';

        List<String> conditions = new List<String>();

        // ── Owner filter ──
        if (String.isNotBlank(currentUserId)) {
            conditions.add('OwnerId = :currentUserId');
        }

        // ── Project filter ──
        if (String.isNotBlank(projectId)) {
            conditions.add('Allocated_Project__c = :projectId');
        }

        // ── Created date range ──
        if (fromCreatedDate != null) {
            conditions.add('Created_Date__c >= :fromCreatedDate');
        }
        if (toCreatedDate != null) {
            conditions.add('Created_Date__c <= :toCreatedDate');
        }

        // ── Lead status ──
        if (String.isNotBlank(leadStatus)) {
            conditions.add('Lead_Status__c = :leadStatus');
        }

        // ── Lead source ──
        if (String.isNotBlank(leadSource)) {
            conditions.add('Source_Type__c = :leadSource');
        }

        // ── Batch code ──
        if (String.isNotBlank(batchcode)) {
            conditions.add('Campaign__c = :batchcode');
        }

        // ── Allocation date range ──
        if (fromAllocationDate != null) {
            conditions.add('Pushed_On__c >= :fromAllocationDate');
        }
        if (toAllocationDate != null) {
            conditions.add('Pushed_On__c <= :toAllocationDate');
        }

        // ── Sub source ──
        if (String.isNotBlank(subSource)) {
            conditions.add('Sub_Source__c = :subSource');
        }

        // ── Phone number (searches 2 phone fields) ──
        String likePhone = '';
        if (String.isNotBlank(phoneNumber)) {
            likePhone = '%' + phoneNumber + '%';
            conditions.add('(Phone__c LIKE :likePhone OR Secondary_Phone__c LIKE :likePhone)');
        }

        // ── Followup subject ──
        List<String> followupSubjectList = new List<String>();
        if (String.isNotBlank(followupSubject)) {
            for (String s : followupSubject.split(',')) {
                String trimmed = s.trim();
                if (String.isNotBlank(trimmed)) {
                    followupSubjectList.add(trimmed);
                }
            }
        }
        if (!followupSubjectList.isEmpty()) {
            conditions.add('Followup_Subject__c IN :followupSubjectList');
        }

        // ── Site visit date range (sub-query on Site_Visit__c) ──
        Set<Id> siteVisitLeadIds = new Set<Id>();
        DateTime startDateTime;
        DateTime endDateTime;

        if (fromSiteVisitDate != null) {
            startDateTime = DateTime.newInstance(fromSiteVisitDate, Time.newInstance(0, 0, 0, 0));
        }
        if (toSiteVisitDate != null) {
            endDateTime = DateTime.newInstance(toSiteVisitDate, Time.newInstance(23, 59, 59, 999));
        }

        if (fromSiteVisitDate != null || toSiteVisitDate != null) {
            String svQuery = 'SELECT SLead__c FROM Site_Visit__c WHERE SLead__c != NULL AND Status__c = \'Completed\'';
            if (fromSiteVisitDate != null) {
                svQuery += ' AND Check_In__c >= :startDateTime';
            }
            if (toSiteVisitDate != null) {
                svQuery += ' AND Check_In__c <= :endDateTime';
            }
            for (Site_Visit__c sv : Database.query(svQuery)) {
                siteVisitLeadIds.add(sv.SLead__c);
            }
        }

        // ── Follow-up date range (sub-query on Follow_Up__c) ──
        Set<Id> followUpLeadIds = new Set<Id>();
        if (fromFollowUpDate != null || toFollowUpDate != null) {
            String fuQuery = 'SELECT SLead__c FROM Follow_Up__c WHERE SLead__c != NULL AND Status__c = \'Scheduled\'';
            if (fromFollowUpDate != null) {
                fuQuery += ' AND Scheduled_Date__c >= :fromFollowUpDate';
            }
            if (toFollowUpDate != null) {
                fuQuery += ' AND Scheduled_Date__c <= :toFollowUpDate';
            }
            for (Follow_Up__c fu : Database.query(fuQuery)) {
                followUpLeadIds.add(fu.SLead__c);
            }
        }

        // ── Merge site visit + follow-up lead IDs ──
        Set<Id> finalLeadIds = new Set<Id>();
        finalLeadIds.addAll(siteVisitLeadIds);
        finalLeadIds.addAll(followUpLeadIds);
        if (!finalLeadIds.isEmpty()) {
            conditions.add('Id IN :finalLeadIds');
        }

        // ── Build final query ──
        String query = 'SELECT ' + fields + ' FROM Lead';
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        query += ' LIMIT 5000';

        System.debug('Query: ' + query);
        return Database.query(query);
    }

    // ─── 3. Update lead owner with business logic ───
    @AuraEnabled
    public static List<Lead> updateLeadOwner(List<Lead> leads, String currentUserId, String assignToId) {
        if (leads == null || leads.isEmpty() || String.isBlank(currentUserId) || String.isBlank(assignToId)) {
            return new List<Lead>();
        }

        // Build input map for SV logic
        Map<Id, Lead> leadInputMap = new Map<Id, Lead>();
        for (Lead l : leads) {
            if (l != null && l.Id != null) leadInputMap.put(l.Id, l);
        }

        List<Lead> leadsToUpdate = new List<Lead>();
        Map<Id, Set<String>> leadScenarioMap = new Map<Id, Set<String>>();

        // Record Type IDs
        Id preSalesRTId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
        Id salesRTId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();

        // Query users
        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Profile.Name, UserRole.Name
            FROM User
            WHERE Id IN :new Set<Id>{ currentUserId, assignToId }
        ]);

        User currentUser = userMap.get(currentUserId);
        User targetUser = userMap.get(assignToId);
        String currentType = getUserType(currentUser);
        String targetType = getUserType(targetUser);

        // ── Build lead updates based on transfer scenario ──
        for (Lead con : leads) {
            if (con == null || con.OwnerId == null) continue;

            Lead up = new Lead(Id = con.Id);
            up.OwnerId = assignToId;
            up.Lead_Assigned__c = true;
            up.Re_assigned_date__c = System.now();
            up.Reassigned_By__c = UserInfo.getUserId();

            String curStatus = String.isBlank(con.Lead_Status__c) ? '' : con.Lead_Status__c;

            // CASE 1: Sales → Pre-Sales
            if (currentType == 'Sales' && targetType == 'Pre Sales') {up.RecordTypeId = preSalesRTId;
                up.Pre_Sales_User__c = assignToId;
                up.Sales_User__c = null;
                up.Lead_Status__c = curStatus.equalsIgnoreCase('Closed Lost') ? 'New' : 'inValid';
                leadScenarioMap.put(up.Id, new Set<String>{ 'Normal' });
            }
            // CASE 2: Pre-Sales → Sales
            else if (currentType == 'Pre Sales' && targetType == 'Sales') {up.RecordTypeId = salesRTId;
                up.Pre_Sales_User__c = null;
                up.Sales_User__c = assignToId;
                up.Lead_Status__c = curStatus.equalsIgnoreCase('RNR') ? 'RNR' : 'New sales enquiry';
                leadScenarioMap.put(up.Id, new Set<String>{ 'Normal' });
            }
            // CASE 3: Sales → Sales
            else if (currentType == 'Sales' && targetType == 'Sales') {up.RecordTypeId = salesRTId;
                up.Sales_User__c = assignToId;
                if (curStatus.equalsIgnoreCase('Closed Lost') || curStatus.equalsIgnoreCase('Site Visit Schedule')) {up.Lead_Status__c = 'New sales enquiry';
                }
                leadScenarioMap.put(up.Id, new Set<String>{ 'PreSaleCheck' });
            }
            // CASE 4: Pre-Sales → Pre-Sales
            else if (currentType == 'Pre Sales' && targetType == 'Pre Sales') {up.RecordTypeId = preSalesRTId;
                up.Pre_Sales_User__c = assignToId;
                if (curStatus.equalsIgnoreCase('Unqualified')) {up.Lead_Status__c = 'New'; } 
                else if (curStatus.equalsIgnoreCase('Site Visit Schedule')) { up.Lead_Status__c = 'Potential Site Visit';}
                leadScenarioMap.put(up.Id, new Set<String>{ 'Normal' });
            }

            leadsToUpdate.add(up);
        }

        // ── Bulk update leads ──
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }

        // ── Process Site Visits + Follow-ups ──
        if (!leadScenarioMap.isEmpty()) {
            // Cancel site visits
            List<Site_Visit__c> svToUpdate = new List<Site_Visit__c>();
            for (Site_Visit__c sv : [ SELECT Id, SLead__c, CreatedById, CreatedBy.Profile.Name, Status__c, Canceled_Reason__c FROM Site_Visit__c WHERE SLead__c IN :leadScenarioMap.keySet()  ]) {
                Set<String> flags = leadScenarioMap.get(sv.SLead__c);
                if (flags != null && flags.contains('PreSaleCheck') && sv.CreatedBy.Profile.Name == 'Pre-Sales Executive') { continue;}
                sv.Status__c = 'Cancelled';
                sv.Canceled_Reason__c = 'Cancelled by system due to lead Re-Assignment.';
                svToUpdate.add(sv);
            }

            // Mark follow-ups as missed
            List<Follow_Up__c> fuToUpdate = new List<Follow_Up__c>();
            for (Follow_Up__c fu : [ SELECT Id, SLead__c, Status__c, Description__c FROM Follow_Up__c WHERE SLead__c IN :leadScenarioMap.keySet()AND Status__c = 'Scheduled'
            ]) {
                fu.Status__c = 'Missed';
                fu.Description__c = 'Missed by system due to lead Re-Assignment.';
                fuToUpdate.add(fu);
            }

            if (!svToUpdate.isEmpty()) update svToUpdate;
            if (!fuToUpdate.isEmpty()) update fuToUpdate;
        }

        // Return refreshed list
        return getFilteredLeads(currentUserId, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null);
    }

    // ─── Helper: Detect user type by profile ───
    private static String getUserType(User u) {
        if (u == null) return '';
        String profile = (u.Profile != null && u.Profile.Name != null) ? u.Profile.Name.toLowerCase() : '';
        if (profile.contains('pre-sales') || profile.contains('pre sales')) return 'Pre Sales';
        if (profile.contains('stm')) return 'Sales';
        return 'Other';
    }

    // ─── Helper: Get picklist values as map ───
    private static Map<String, String> getPicklistMap(Schema.SObjectField field) {
        Map<String, String> options = new Map<String, String>();
        for (Schema.PicklistEntry p : field.getDescribe().getPicklistValues()) {
            options.put(p.getValue(), p.getLabel());
        }
        return options;
    }
}