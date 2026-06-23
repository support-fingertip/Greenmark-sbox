({
    addProductRecord: function(component,event,helper) {
        var shcdules = component.get("v.CustompaymentSchedules");
        var sno =  shcdules.length+ 1;
        shcdules.push({
            'sobjectType': 'Payment_schedule__c',
            'Name': '',
            'Payment_percent__c': '',
            'Payment_Due_Date__c':'',
            'Tentative_TimeLine__c':'',
            'Amount__c': '',
            'Completed_Date__c':'',
            'status__c':'',
            'Master_Payment_Schedule__c':'',
            'S_No__c':sno,
            'Received_Amount__c':'',
            'Recived_Per__c':'',
            'Type__c' : ''
        });
        component.set("v.CustompaymentSchedules", shcdules);
    },
    getmasterData: function(component, event,helper) {
        component.set("v.isLoading",true);
        component.set("v.showBlockLookup", false);
        component.set("v.showUnits", false);
        var action=component.get("c.getData");  
        action.setParams({'recId':  component.get('v.recordId') });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var returnData = response.getReturnValue();
                if(returnData.isProjectNameExisted)
                {
                    component.set("v.blocks",returnData.blockList);
                    component.set("v.showBlockLookup", true);
                    component.set("v.showReferalPercentage", returnData.showReferalPercentage);
                    component.set("v.discountLimit", returnData.discountLimit);
                    component.set("v.paymentTypePicklist", returnData.paymentTypeValues);
                    component.set("v.isLoading",false);
                }
                else
                {
                    helper.showToast(
                        'Error',
                        'Project Name Not Found',
                        'Please fill in the Project Name on the Lead to proceed with Quote creation.'
                    );

                    $A.get('e.force:closeQuickAction').fire();
                    $A.get('e.force:refreshView').fire();
                }
                
            }
        });
        $A.enqueueAction(action);
    },
    previewsave  : function(component, event, helper){
        component.set('v.isLoading',true);
        var schedules;
        var patType = component.get('v.paymentType');
        if(patType == 'Standard'){
            schedules = component.get('v.paymentSchedules');
        }
        else if(patType == 'Custom'){
            schedules = component.get('v.CustompaymentSchedules');
        }
        var isAutoApproval = false;
        let entereddiscount = component.get("v.oppPlot.Discount_Price__c");
        let discountLimit = component.get("v.discountLimit");
        if( entereddiscount == null || entereddiscount === '' || entereddiscount == undefined ||
           discountLimit == null || discountLimit === '' || discountLimit == undefined ||
           entereddiscount <= discountLimit ){
           isAutoApproval = true;
        }
        
        var action=component.get("c.saveOppPlot");  
        action.setParams({
            oppPlot:component.get("v.oppPlot"),
            payList:schedules,
            isAutoApproval:isAutoApproval
        });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var result = response.getReturnValue();
                component.set("v.quoteId", result.quoteId);
                component.set("v.recordTypeName", result.recordTypeName);
                if(result != 'notc'){
                    component.set('v.showPreview',true);
                    component.set('v.isLoading',false);
                }
                else{
                    component.set('v.isLoading',false);
                    var errors = response.getError();
                    var errormessage=errors[0].message;
                    if (errors) {
                        helper.showToast('Error','Unknown Error',errormessage);
                    }
                    else {
                        console.log("Unknown error");
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },
    showToast : function(type,title,message) {
        console.log(message)
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "title":title,
            "message":message
        });
        toastEvent.fire();
    },
    getmasterpaymentschedule: function(component, event,helper) {
        var oppPlot = component.get('v.oppPlot');
        var pymplan = component.get("v.paymentType");
        var project = component.get('v.projectName');
        var action = component.get("c.getPaymentSchedules");
        component.set("v.isLoading",true);
        action.setParams({'Pay':  pymplan,
                          'Project': project,
                          'blockId': component.get('v.blockId')
                         })
        action.setCallback(this,function(response){
            var state = response.getState();
            
            if(state == "SUCCESS" ){ 
                var payments = response.getReturnValue();
                if(payments !=null){
                    component.set('v.paymentSchedules', payments );
                    component.set('v.CustompaymentSchedules', payments );
                    component.set('v.showPayments', true);
                }
                else
                {
                    component.set('v.showPayments', false);
                }
                component.set("v.isLoading",false);
            }
        });
        $A.enqueueAction(action); 
    },
    
    /**Not in Use **/
    getFilteredLead: function(component, event,helper) {
        //alert('hh')
        var oppPlot = component.get('v.oppPlot');
        var pymplan = component.get('v.paymentType');
        var project = component.get('v.projectName');
        var totalCost = component.get("v.GrandTotal");
        var gstPer = component.get('v.oppPlot.GST1__c');
        gstPer = (typeof gstPer !== 'undefined') ? gstPer : 0;
        var totalWithgst = (parseFloat(totalCost) + (parseFloat(totalCost) * parseFloat(gstPer))/100);
        //alert(gstPer);
        //alert(totalCost);
        //alert(totalWithgst);
        component.set('v.FlatCost', totalCost);
        component.set('v.GrandTotalwithGST',totalWithgst);
        component.set("v.oppPlot.Grand_Total_Amount_With_Tax__c", totalWithgst);
        //alert(pymplan+'--'+project)
        var action = component.get("c.getPaymentSchedules");
        
        action.setParams({'Pay':  pymplan,
                          'Project': project
                         })
        action.setCallback(this,function(response){
            var state = response.getState();
            //alert(state);
            if(state == "SUCCESS" ){ 
                
                var db = response.getReturnValue();
                var shcdules = component.get("v.paymentSchedules");
                //alert(db);
                //alert(db.payList);
                //console.log(db.payList.length());
                for(var i=0;i<db.length; i++){
                    var amout = (parseFloat(db[i].Payment_Percent__c) * parseFloat(totalWithgst))/100
                    //alert('Id  '+db[i].Id);
                    shcdules.push({
                        'sobjectType': 'Payment_schedule__c',
                        'Name': db[i].Name,
                        'Payment_percent__c': db[i].Payment_Percent__c,
                        'Payment_Due_Date__c':'',
                        'Amount__c': amout,
                        'Include_Interest__c' : db[i].Include_Interest__c,
                        'Completed_Date__c':db[i].Completed_Date__c,
                        'status__c':db[i].Status__c,
                        'Master_Payment_Schedule__c':db[i].Id,
                        'S_No__c':db[i].S_No__c,
                        'Tentative_TimeLine__c':db[i].Tentative_TimeLine__c
                    });
                    
                } 
                if(db!=null){
                    console.log('if');
                    
                    component.set("v.paymentSchedules", shcdules);
                    //alert('calling the payment',db);
                    //alert(JSON.stringify(component.get('v.paymentSchedules')))
                }
                else{
                    
                    //  helper.addProductRecord(component,event,helper);
                    console.log('else');
                    
                }
                
            }
        });
        $A.enqueueAction(action); 
        
    },
})