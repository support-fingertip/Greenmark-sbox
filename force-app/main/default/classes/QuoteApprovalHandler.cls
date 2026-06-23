public class QuoteApprovalHandler {
    public static void beforeInsert(List<Quote__c> newQuoteList)
    {
        set<String> projectSet = new set<String>();
        for(Quote__c qt: newQuoteList)
        {
            if(qt.Project__c != null)
            {
                projectSet.add(qt.Project__c);
            }
        }
        
        list<Project__c> lstProjects = [select Id,Project_Sales_Head__c,Project__c,	Sales_Head__c from Project__c where Project__c In:projectSet
                                        AND Project__c!= null AND Project_Sales_Head__c != null];
        map<String,String> projectWithProjectSalesHead = new map<String,String>();
        map<String,String> projectWithSalesHead = new map<String,String>();
        for(Project__c pr: lstProjects)
        {
            if(pr.Project_Sales_Head__c != null)
            {
                projectWithProjectSalesHead.put(pr.Project__c,pr.Project_Sales_Head__c);
            }
            if(pr.Sales_Head__c != null)
            {
                projectWithSalesHead.put(pr.Project__c,pr.Sales_Head__c);
            }
          
        }
        
        for(Quote__c qt: newQuoteList)
        {
            if(qt.Project__c != null && projectWithProjectSalesHead.containsKey(qt.Project__c ))
            {
                qt.Project_Sales_Head__c = projectWithProjectSalesHead.get(qt.Project__c);
            }
            if(qt.Project__c != null && projectWithSalesHead.containsKey(qt.Project__c ))
            {
                qt.Sales_Head__c = projectWithSalesHead.get(qt.Project__c);
            }
        }

        
    }
    public static void processQuotes(List<Quote__c> quoteList) {
        try {
            if (quoteList.isEmpty()) return;

            // Collect User IDs and Project Names for bulk processing
            Set<Id> userIds = new Set<Id>();
            Set<String> projectNames = new Set<String>();

         /*   for (Quote__c q : quoteList) {
                if (q.OwnerId != null && q.Project__c != null) {
                    userIds.add(q.OwnerId);
                    projectNames.add(q.Project__c);
                }
            }

            if (userIds.isEmpty() || projectNames.isEmpty()) return;

            // Query Discount Limits in bulk
            Map<String, Decimal> discountLimitMap = new Map<String, Decimal>();
            for (Discount_Limit__c dl : [SELECT Executive__c, Project__c, Maximum_Discount__c  FROM Discount_Limit__c WHERE Executive__c IN :userIds AND Project__c IN :projectNames ]) {
                String key = dl.Executive__c + '-' + dl.Project__c;
                discountLimitMap.put(key, dl.Maximum_Discount__c);
            }
*/
            List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();

            for (Quote__c q : quoteList) {
                    // Submit for Approval
                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                    req.setObjectId(q.Id);
                    req.setSubmitterId(q.OwnerId);
                    req.setProcessDefinitionNameOrId('Quote_Approval'); // Ensure this process exists
                    req.setSkipEntryCriteria(false);
                    approvalRequests.add(req);
                
            }

            if (!approvalRequests.isEmpty()) {
                Approval.ProcessResult[] results = Approval.process(approvalRequests);
                
                // Error Handling - Log failed approval processes
                for (Approval.ProcessResult result : results) {
                    if (!result.isSuccess()) {
                        System.debug('Approval submission failed: ' + result.getErrors());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in QuoteApprovalHandler: ' + e.getMessage());
        }
    }
}