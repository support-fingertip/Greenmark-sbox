({
    generateDocument: function(component, event, helper) {
        
        var bookingval = component.get('v.booking') || {};
        var currentMilestone = component.get('v.currentMilestone') || {};
        var selectedIndexId = component.get('v.selectedIndexId');
        var selectedMilestone = component.get('v.selectedMilestone') || '';
        var coApplicant = component.get('v.coApplicant') || {};
        var emailTemplateContent = component.get('v.emailTemplateContent') || {};
        
        var rawEmailContent = emailTemplateContent.Template_Body__c || '';
        
        component.set("v.milestoneId", selectedIndexId);
        
        if (!selectedIndexId) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                type: 'error',
                title: 'Error',
                message: 'Please select a milestone',
                duration: 5000
            });
            toastEvent.fire();
            return;
        }
        
        /* ================= Applicant Names ================= */
        var applicantNames = '';
        
        if (bookingval.S__c && bookingval.First_Applicant_Name__c) {
            applicantNames = bookingval.S__c + ' ' + bookingval.First_Applicant_Name__c;
        } else if (bookingval.First_Applicant_Name__c) {
            applicantNames = bookingval.First_Applicant_Name__c;
        }
        
        if (coApplicant.Name && coApplicant.Name.trim() !== '') {
            applicantNames += (applicantNames ? ' and ' : '') + coApplicant.Name.trim();
        }
        
        /* ================= Milestone ================= */
        var milestoneName =  selectedMilestone;
        
        /* ================= Project Name ================= */
        var projectName = '';
        if (bookingval.Project1__r && bookingval.Project1__r.Name) {
            projectName = bookingval.Project1__r.Name;
        }
        
        /* ================= Company Details ================= */
        var companyName =bookingval.Company_Name__c || '';  
        var crmPhone = bookingval.Owner_Phone__c || '';
        
        /* ================= Placeholder Replacement ================= */
        var finalEmailContent = rawEmailContent;
        
        finalEmailContent = finalEmailContent.replace(/##APPLICANT_NAME##/g, applicantNames);
        finalEmailContent = finalEmailContent.replace(/##COMPANY_NAME##/g, companyName);
        finalEmailContent = finalEmailContent.replace(/##MILESTONE_NAME##/g, milestoneName);
        finalEmailContent = finalEmailContent.replace(/##PROJECT_NAME##/g, projectName);
        finalEmailContent = finalEmailContent.replace(/##CRM_PHONE##/g, crmPhone);
        
        // 1. Decode HTML entities first
        var decoded = finalEmailContent
        .replace(/&lt;/g, "<")
        .replace(/&gt;/g, ">")
        .replace(/&amp;/g, "&");
        
        // 2. Remove extra span wrappers added by RTE
        decoded = decoded.replace(/<span[^>]*>/g, "");
        decoded = decoded.replace(/<\/span>/g, "");
        
        // 3. Remove empty paragraphs created by editor
        decoded = decoded.replace(/<p><br><\/p>/g, "");
        
        
        component.set("v.emailContent", decoded);
        component.set("v.filesLoading", true);
        var action = component.get("c.getScheduleFiles");
        action.setParams({
            paymentScheduleId: selectedIndexId
        });
        
        action.setCallback(this, function(response){
            if(response.getState() === "SUCCESS"){
                component.set("v.filesLoading", false);
                var fileIds = response.getReturnValue();
                component.set("v.exestingFilesIDS", fileIds);
                component.set("v.filesIDS", fileIds);
            }
        });
        $A.enqueueAction(action);
    }
})