({
    addProductRecord: function(component, event) {
        var productList = component.get("v.recptItemList") || [];
        // Solo-row guard: TDS Challan Entry / TDS Refund / Interest must each be the only line item
        var SOLO_TYPES = ['TDS Challan Entry', 'TDS Refund', 'Interest Amount'];
        var hasSolo = productList.some(function(r) {
            return SOLO_TYPES.indexOf(r.Payment_Type__c) !== -1;
        });
        if (hasSolo) {
            return;
        }
        if (productList.length >= 3) {
            return;
        }
        productList.push({
            'sobjectType': 'Receipt_Line_Item__c',
            'Payment_schedule__c': '',
            'Mode_of_Payment__c': '',
            'Name': '',
            'Payment_Type__c':'',
            'Cheque_no_Transaction_Number__c':'',
            'Received_Amount__c': '',
            'Payment_From__c':'',
            'Bank_Name__c':'',
            'Cheque_Date__c':'',
            'Branch__c':'',
            'Drwan_On__c':'',
            'GRAND_TOTAL__c':'',
            'Pending_Amount__c': '',
            'Additional_Charges__c':''
        });
        component.set("v.recptItemList", productList);
    },
    getData : function(component,event,helper){
        var action=component.get("c.getData");
        action.setParams({
            'recId':  component.get('v.recordId'),
            'receiptType': component.get('v.selectedReceiptType') || ''
        })
        action.setCallback(this,function(response){
            if(response.getState() == "SUCCESS"){ 
                var data = response.getReturnValue();
                component.set('v.additionlCharges',  data.additionalCharges);
                component.set('v.paymentschdl',  data.paymentSchdules);
                component.set("v.paymentTypePicklist",data.paymentTypePicklist);
                component.set("v.tdsStatusPicklist", data.tdsStatusPicklist);
                component.set("v.bankNamePicklist", data.bankNamePicklist || []);
                component.set("v.pendingTdsRefunds", data.pendingTdsRefunds || []);
                component.set("v.pendingTdsRefundAmount", data.pendingTdsRefundAmount || 0);
                component.set("v.totalPendingTds", data.tdsAmount);
                component.set("v.projectName", data.bookingRecord.Project__c);
                component.set("v.flatNumber", data.bookingRecord.Unit_Number__c);
                component.set("v.FlatCost", data.bookingRecord.Total_Amount__c);
                component.set("v.flatOrVillaPendingAmount",data.flatOrVillaPendingAmount);
                component.set("v.interestPending",data.iterestAmount);
                component.set("v.bookingPendingAmount",data.bookingRecord.Pending_Amount__c);
                component.set("v.bookingPendingAmount1",data.bookingRecord.Pending_Amount__c);
                component.set("v.totalPending", data.bookingRecord.Pending_Amount__c);
                component.set("v.bookingType",data.bookingRecord.Project_Type__c);
                component.set("v.interestAmount",data.iterestAmount);
            }
        });
        $A.enqueueAction(action); 
    },
    showToast : function(message,type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "message":  message
        });
        toastEvent.fire();
    },
    
    validateCumulativeAmount: function(component, event, helper, index) {
        
        var recptItemList = component.get("v.recptItemList");
        
        var totalPrincipalPending = component.get("v.bookingPendingAmount1");   // principal pending
        var totalInterestPending  = component.get("v.interestAmount");  // interest pending
        
        var principalReceived = 0;
        var interestReceived  = 0;
        
        // ===== ROW LEVEL VALIDATION =====
        for (var i = 0; i < recptItemList.length; i++) {
            
            let type     = recptItemList[i].Payment_Type__c;
            let received = parseFloat(recptItemList[i].Received_Amount__c) || 0;
            let pending  = parseFloat(recptItemList[i].Pending_Amount__c) || 0;
            
            // Prevent exceeding row pending
            if (received > pending) {
                helper.showToast(
                    "Received amount cannot exceed pending " + type,
                    "error"
                );
                
                recptItemList[i].Received_Amount__c = null;
                received = 0;
            }
            
            // ===== BUCKET SEPARATION =====
            
            // PRINCIPAL TYPES (TDS variants intentionally excluded; they
            // are tracked separately and capped per-row by Pending_Amount__c)
            if (
                type === 'Flat Amount' ||
                type === 'Plot Amount' ||
                type === 'Villa Amount' ||
                type === 'Row House Amount' ||
                type === 'GST Amount'
            ) {
                principalReceived += received;
            }

            // INTEREST TYPE
            else if (type === 'Interest Amount') {
                interestReceived += received;
            }
        }
        
        
        // ===== OVERALL PRINCIPAL VALIDATION =====
        if (principalReceived > totalPrincipalPending) {
            
            helper.showToast(
                "Total principal received cannot exceed total pending principal",
                "error"
            );
            
            recptItemList[index].Received_Amount__c = null;
            principalReceived = 0;
            
            for (var j = 0; j < recptItemList.length; j++) {

                let type = recptItemList[j].Payment_Type__c;

                if (
                    type === 'Flat Amount' ||
                    type === 'Plot Amount' ||
                    type === 'Villa Amount' ||
                    type === 'Row House Amount' ||
                    type === 'GST Amount'
                ) {
                    principalReceived +=
                        parseFloat(recptItemList[j].Received_Amount__c) || 0;
                }
            }
        }
        
        
        // ===== OVERALL INTEREST VALIDATION =====
        if (interestReceived > totalInterestPending) {
            
            helper.showToast(
                "Total interest received cannot exceed pending interest",
                "error"
            );
            
            recptItemList[index].Received_Amount__c = null;
            interestReceived = 0;
            
            for (var k = 0; k < recptItemList.length; k++) {
                
                if (recptItemList[k].Payment_Type__c === 'Interest Amount') {
                    
                    interestReceived +=
                        parseFloat(recptItemList[k].Received_Amount__c) || 0;
                }
            }
        }
        
        
        // ===== SET COMPONENT VALUES =====
        
        component.set("v.totalrcvdAmount", principalReceived);
        component.set(
            "v.totalPending",
            parseFloat((totalPrincipalPending - principalReceived).toFixed(2))
        );
        
        component.set("v.interestReceived", interestReceived);
        component.set(
            "v.interestPending",
            parseFloat((totalInterestPending - interestReceived).toFixed(2))
        );
        
        component.set("v.recptItemList", recptItemList);
    },
    
    getTotalAmount: function(component, event, helper) {
        var totalPendingAmount = component.get("v.bookingPendingAmount1");
        var recptItemList = component.get("v.recptItemList");
        // Recalculate total again after resetting the current field
        var cumulativeReceivedAmount = 0;
        for (var j = 0; j < recptItemList.length; j++) {
            if (
                recptItemList[j].Payment_Type__c === 'Flat Amount' ||
                recptItemList[j].Payment_Type__c === 'Plot Amount' ||
                recptItemList[j].Payment_Type__c === 'GST Amount' ||
                recptItemList[j].Payment_Type__c === 'Villa Amount' ||
                recptItemList[j].Payment_Type__c === 'Row House Amount'
            ) {
                cumulativeReceivedAmount += parseFloat(recptItemList[j].Received_Amount__c) || 0;
            }
        }
        
        component.set("v.totalrcvdAmount", cumulativeReceivedAmount);
        component.set("v.totalPending", parseFloat((totalPendingAmount - cumulativeReceivedAmount).toFixed(2)));
        component.set("v.recptItemList", recptItemList);
    },
    
})