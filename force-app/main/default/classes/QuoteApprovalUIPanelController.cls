public class QuoteApprovalUIPanelController {

    // ======================= WRAPPERS =======================

    public class QuoteInfo {
        @AuraEnabled public Id quoteId;
        @AuraEnabled public String quoteName;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String ratePerSqFt;
        @AuraEnabled public String discountPrice;
        @AuraEnabled public String discountedRate;
        @AuraEnabled public String approvalCriteria;
    }

    public class ApprovalHistoryEntry {
        @AuraEnabled public String actorName;
        @AuraEnabled public String action;
        @AuraEnabled public String comments;
        @AuraEnabled public Datetime actionDate;
    }

    public class ApprovalWrapper {
        @AuraEnabled public String processName;
        @AuraEnabled public String status;
        @AuraEnabled public String submitterName;
        @AuraEnabled public Datetime submittedDate;
        @AuraEnabled public String actualApproverName;
        @AuraEnabled public String assignedToName;
        @AuraEnabled public Boolean canAct;
        @AuraEnabled public QuoteInfo quote;
        @AuraEnabled public List<ApprovalHistoryEntry> history;
    }


    // ======================= MAIN UI METHOD =======================

    @AuraEnabled
    public static ApprovalWrapper getApprovalData(Id recordId) {

        ApprovalWrapper wrap = new ApprovalWrapper();
        wrap.history = new List<ApprovalHistoryEntry>();

        // ---------- QUOTE FIELDS ----------
        Quote__c q = [
            SELECT Id, Name, Owner.Name,
                   Rate_per_SqFt__c,
                   Discount_Price__c,
                   Rate_sq_Ft_Discount__c,
                   Approval_Criteria__c
            FROM Quote__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        QuoteInfo qi = new QuoteInfo();
        qi.quoteId          = q.Id;
        qi.quoteName        = q.Name;
        qi.ownerName        = q.Owner.Name;
        qi.ratePerSqFt      = q.Rate_per_SqFt__c != null ? String.valueOf(q.Rate_per_SqFt__c) : '';
        qi.discountPrice    = q.Discount_Price__c != null ? String.valueOf(q.Discount_Price__c) : '';
        qi.discountedRate   = q.Rate_sq_Ft_Discount__c != null ? String.valueOf(q.Rate_sq_Ft_Discount__c) : '';
        qi.approvalCriteria = q.Approval_Criteria__c;
        wrap.quote          = qi;


        // ---------- FETCH LATEST PROCESS INSTANCE ----------
        List<ProcessInstance> piList = [
            SELECT Id, Status, CreatedDate, SubmittedBy.Name,
                   ProcessDefinition.DeveloperName,
                   ProcessDefinition.Name
            FROM ProcessInstance
            WHERE TargetObjectId = :recordId
            AND ProcessDefinition.DeveloperName = 'Quote_Approval_Latest_1'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (piList.isEmpty()) {
            wrap.status = 'No Approval Found';
            return wrap;
        }

        ProcessInstance pi = piList[0];

        wrap.processName   = pi.ProcessDefinition.Name;
        wrap.status        = pi.Status;
        wrap.submittedDate = pi.CreatedDate;
        wrap.submitterName = pi.SubmittedBy != null ? pi.SubmittedBy.Name : '';


        // ---------- CURRENT PENDING APPROVER ----------
        List<ProcessInstanceWorkitem> wiList = [
            SELECT Id, ActorId, Actor.Name, OriginalActorId, OriginalActor.Name
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstanceId = :pi.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (!wiList.isEmpty()) {
            ProcessInstanceWorkitem wi = wiList[0];

            wrap.actualApproverName = wi.OriginalActorId != null ? wi.OriginalActor.Name : wi.Actor.Name;
            wrap.assignedToName     = wi.Actor.Name;

            // canAct = is current user the assigned approver + process pending
            wrap.canAct = (UserInfo.getUserId() == wi.ActorId && pi.Status == 'Pending');
        } else {
            wrap.canAct = false;
        }


        // ======================= FULL APPROVAL HISTORY FIXED =======================

       List<ProcessInstanceStep> stepList = [
    SELECT Actor.Name, Comments, StepStatus, CreatedDate
    FROM ProcessInstanceStep
    WHERE ProcessInstanceId = :pi.Id
    ORDER BY CreatedDate ASC
];

for (ProcessInstanceStep step : stepList) {

    ApprovalHistoryEntry h = new ApprovalHistoryEntry();
    h.actorName  = step.Actor != null ? step.Actor.Name : '';
    h.comments   = step.Comments;
    h.actionDate = step.CreatedDate;

    // Map StepStatus to user-friendly text
    if (step.StepStatus == 'Started')        h.action = 'Submitted';
    else if (step.StepStatus == 'Pending')   h.action = 'Pending';
    else if (step.StepStatus == 'Approved')  h.action = 'Approved';
    else if (step.StepStatus == 'Rejected')  h.action = 'Rejected';
    else                                     h.action = step.StepStatus;

    wrap.history.add(h);
}

        return wrap;
    }


    // ======================= APPROVE =======================

    @AuraEnabled
    public static void approve(Id recordId, String comments) {

        List<ProcessInstanceWorkitem> items = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :recordId
            LIMIT 1
        ];

        if (items.isEmpty()) {
            throw new AuraHandledException('No pending approval found.');
        }

        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setWorkitemId(items[0].Id);
        req.setComments(comments);
        req.setAction('Approve');

        Approval.process(req);
    }


    // ======================= REJECT =======================

    @AuraEnabled
    public static void reject(Id recordId, String comments) {

        List<ProcessInstanceWorkitem> items = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :recordId
            LIMIT 1
        ];

        if (items.isEmpty()) {
            throw new AuraHandledException('No pending approval found.');
        }

        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setWorkitemId(items[0].Id);
        req.setComments(comments);
        req.setAction('Reject');

        Approval.process(req);
    }
}