/**
 * TATCalculationHelper
 * --------------------
 * Computes Turnaround Time (TAT) breaches for Leads as per BRD 4.1.10.
 *
 * TAT clock starts at Lead_Assigned_Time__c (stamped when the lead is assigned)
 * and is measured against the first call / first follow-up.
 *
 * The TAT threshold (in hours) is configured per Project on Project__c:
 *   - Pre_Sales_TAT_Hours__c       -> used for Pre Sales record type leads (first call)
 *   - Sales_TAT_Hours__c           -> used for Sales record type leads (first call)
 *   - Sales_Followup_TAT_Hours__c  -> used for first follow-up
 *
 * Lead.Allocated_Project__c is a TEXT field holding the project name, which maps
 * to Project__c.Project__c (also the project name). We resolve thresholds via that.
 */
public class TATCalculationHelper {

    private static final String PRE_SALES_RT = 'Pre Sales';

    /**
     * Loads Project TAT thresholds keyed by project name (Project__c.Project__c).
     */
    private static Map<String, Project__c> getProjectMap(Set<String> projectNames) {
        Map<String, Project__c> projectMap = new Map<String, Project__c>();
        if (projectNames.isEmpty()) {
            return projectMap;
        }
        for (Project__c p : [
            SELECT Project__c, Pre_Sales_TAT_Hours__c, Sales_TAT_Hours__c, Sales_Followup_TAT_Hours__c
            FROM Project__c
            WHERE Project__c IN :projectNames
        ]) {
            if (p.Project__c != null) {
                projectMap.put(p.Project__c, p);
            }
        }
        return projectMap;
    }

    /** Difference in hours between two datetimes (later - earlier). */
    private static Decimal hoursBetween(DateTime startTime, DateTime endTime) {
        Long ms = endTime.getTime() - startTime.getTime();
        return (Decimal.valueOf(ms) / (1000 * 60 * 60)).setScale(2);
    }

    /**
     * Evaluates the FIRST CALL TAT for the given leads.
     * @param leadIds       leads whose first call just happened
     * @param firstCallMap  leadId -> earliest call datetime
     * Returns the leads (with breach fields populated) ready for update.
     */
    public static List<Lead> evaluateCallTAT(Set<Id> leadIds, Map<Id, DateTime> firstCallMap) {
        List<Lead> result = new List<Lead>();
        if (leadIds == null || leadIds.isEmpty()) {
            return result;
        }

        List<Lead> leads = [
            SELECT Id, Allocated_Project__c, Lead_Assigned_Time__c, RecordType.Name,
                   Call_TAT_Breached__c, Actual_Call_TAT_Hours__c
            FROM Lead
            WHERE Id IN :leadIds
        ];

        Set<String> projectNames = new Set<String>();
        for (Lead ld : leads) {
            if (ld.Allocated_Project__c != null) {
                projectNames.add(ld.Allocated_Project__c);
            }
        }
        Map<String, Project__c> projectMap = getProjectMap(projectNames);

        for (Lead ld : leads) {
            DateTime firstCall = firstCallMap.get(ld.Id);
            if (firstCall == null || ld.Lead_Assigned_Time__c == null || ld.Allocated_Project__c == null) {
                continue;
            }
            Project__c proj = projectMap.get(ld.Allocated_Project__c);
            if (proj == null) {
                continue;
            }
            Decimal threshold = (ld.RecordType.Name == PRE_SALES_RT)
                ? proj.Pre_Sales_TAT_Hours__c
                : proj.Sales_TAT_Hours__c;
            if (threshold == null) {
                continue;
            }

            Decimal actualHours = hoursBetween(ld.Lead_Assigned_Time__c, firstCall);
            ld.Actual_Call_TAT_Hours__c = actualHours;
            ld.Call_TAT_Breached__c = (actualHours > threshold);
            result.add(ld);
        }
        return result;
    }

    /**
     * Evaluates the FIRST FOLLOW-UP TAT. Only leads that do not yet have a
     * First_Followup_Time__c are considered (so only the first follow-up counts).
     * @param leadIds          leads that just got a follow-up
     * @param followupTimeMap  leadId -> earliest follow-up datetime
     * Returns the leads (with first-followup + breach fields populated) ready for update.
     */
    public static List<Lead> evaluateFollowupTAT(Set<Id> leadIds, Map<Id, DateTime> followupTimeMap) {
        List<Lead> result = new List<Lead>();
        if (leadIds == null || leadIds.isEmpty()) {
            return result;
        }

        List<Lead> leads = [
            SELECT Id, Allocated_Project__c, Lead_Assigned_Time__c, RecordType.Name,
                   First_Followup_Time__c, Followup_TAT_Breached__c, Actual_Followup_TAT_Hours__c
            FROM Lead
            WHERE Id IN :leadIds AND First_Followup_Time__c = null
        ];

        Set<String> projectNames = new Set<String>();
        for (Lead ld : leads) {
            if (ld.Allocated_Project__c != null) {
                projectNames.add(ld.Allocated_Project__c);
            }
        }
        Map<String, Project__c> projectMap = getProjectMap(projectNames);

        for (Lead ld : leads) {
            DateTime firstFollowup = followupTimeMap.get(ld.Id);
            if (firstFollowup == null) {
                continue;
            }
            // Always record the first follow-up time once we have it.
            ld.First_Followup_Time__c = firstFollowup;

            if (ld.Lead_Assigned_Time__c == null || ld.Allocated_Project__c == null) {
                result.add(ld);
                continue;
            }
            Project__c proj = projectMap.get(ld.Allocated_Project__c);
            if (proj == null || proj.Sales_Followup_TAT_Hours__c == null) {
                result.add(ld);
                continue;
            }

            Decimal actualHours = hoursBetween(ld.Lead_Assigned_Time__c, firstFollowup);
            ld.Actual_Followup_TAT_Hours__c = actualHours;
            ld.Followup_TAT_Breached__c = (actualHours > proj.Sales_Followup_TAT_Hours__c);
            result.add(ld);
        }
        return result;
    }
}