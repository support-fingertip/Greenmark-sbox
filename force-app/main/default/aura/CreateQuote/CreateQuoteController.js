({
    doInit: function(component, event, helper) {
        component.set("v.isLoading",true);
        helper.addProductRecord(component, event,helper);
        helper.getmasterData(component, event,helper);
    },
    searchBlocks : function(component, event, helper){
        var block= component.get('v.blocks');
        component.set('v.showCostSheet',false);
        var searchText1= component.get('v.searchText2');
        var matchblocks=[];
        if(searchText1 !=''){
            for(var i=0;i<block.length; i++){ 
                if(block[i].Name.toLowerCase().indexOf(searchText1.toLowerCase())  != -1  ){
                    if(matchblocks.length <70){
                        matchblocks.push( block[i] );
                    }else{
                        break;
                    }
                } 
            } 
            if(matchblocks.length >0){
                component.set('v.matchblocks',matchblocks);
            }
        }else{
            component.set('v.showUnits',false);
            component.set('v.matchblocks',[]);
            component.set('v.Showfields',false);
            component.set('v.searchText1','');
        }
    },
    updateBlock : function(component, event, helper){
        var edi =  event.currentTarget.dataset.id;
        var plt= component.get('v.matchblocks');
        var selPlot= component.get('v.blocks');
        var oppPlot = component.get('v.oppPlot');
        component.set("v.isLoading",true);
        for(var i=0;i<plt.length; i++){  
            if(plt[i].Id ===  edi ){
                if(plt[i].Name!=null)
                {
                    component.set('v.searchText2', plt[i].Name);
                    var block = component.get('v.searchText2');
                    var action=component.get("c.getPlots");  
                    action.setParams({'recId':  edi});
                    action.setCallback(this,function(response){
                        if(response.getState()=="SUCCESS"){ 
                            var result = response.getReturnValue();
                            component.set("v.isLoading",false);
                            component.set("v.plots",result);
                            component.set("v.showNextCmp", false);
                            component.set('v.showUnits',true);
                            component.set('v.blockId',edi);
                            component.set('v.matchblocks',[]);
                        }
                    });
                    $A.enqueueAction(action);
                }
                oppPlot.Block_Lookup__c = edi;
                selPlot = plt[i];
                // component.set('v.blocks', selPlot);
                component.set('v.oppPlot',oppPlot);
            }
        }
        
    },
    searchUnits : function(component, event, helper) {
        var plot= component.get('v.plots');
        component.set('v.+',false);
        var searchText1= component.get('v.searchText1');
        console.log(searchText1.length)
        if(searchText1.length < 1){
            console.log(searchText1)
        }
        var matchplots=[];
        if(searchText1 !=''){
            for(var i=0;i<plot.length; i++){ 
                if(plot[i].Name.toLowerCase().indexOf(searchText1.toLowerCase())  != -1  ){
                    
                    if(matchplots.length <50){
                        matchplots.push( plot[i] );
                        
                    }else{
                        break;
                    }
                } 
            } 
            if(matchplots.length >0){
                component.set('v.matchplots',matchplots);
            }
        }else{
            component.set('v.matchplots',[]);
            component.set('v.Showfields',false);
            component.set('v.searchText1','');
            component.set('v.selectedUnit','');
            
        }
    },
    updateUnit: function(component, event, helper) {
        component.set("v.isLoading",true);
        component.set('v.Showfields', false);
        var edi =  event.currentTarget.dataset.id;
        var plt= component.get('v.matchplots');
        var selPlot= component.get('v.plots');
        var selPlot= component.get('v.plots');
        var oppPlot = component.get('v.oppPlot');
        var opp = component.get("v.OppRecord");
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        for(var i=0;i<plt.length; i++){ 
            if(plt[i].Id ===  edi ){
                if(plt[i].Name!=null)
                {
                    component.set('v.Showfields', true);
                    component.set('v.selectedUnit', edi);
                    component.set('v.searchText1', plt[i].Name);
                    component.set('v.projectName', plt[i].Project__r.Name);
                    component.set('v.flatNumber', plt[i].Name);
                    component.set('v.blockName', plt[i].Block1__c);
                }
                
                selPlot = plt[i];
                oppPlot.SLead__c=component.get('v.recordId');
                oppPlot.Unit__c = plt[i].Id;
                //oppPlot.Block_Lookup__c = plt[i].Block_Lookup__c;
                oppPlot.Project__c = plt[i].Project__r.Project__c;
                oppPlot.Floor__c = plt[i].Floor__c;
                oppPlot.BHK_Type__c = plt[i].BHK_Type__c;
                oppPlot.Unit_Facing_Direction__c = plt[i].Unit_Facing_Direction__c;
                oppPlot.Super_Built_UpArea__c = plt[i].Super_Built_up_Area__c;
                oppPlot.Rate_per_sqft__c = plt[i].Rate_per_sqft__c;
                oppPlot.Bescom__c  = plt[i].Bescom__c;
                oppPlot.Generator_Charges__c  = plt[i].Generator_Charges__c;
                oppPlot.GST__c  = plt[i].GST1__c;
                oppPlot.PLC__c = plt[i].PLC__c;
                var unitType = 'Apartment';
                if( plt[i].Unit_Type__c == 'Apartment')
                {
                    unitType = 'Apartments';
                    oppPlot.Carpet_Area__c = plt[i].Carpet_Area__c;
                    oppPlot.Balcony_Area_Sq_ft__c = plt[i].Balcony_Area_Sq_ft__c;
                    oppPlot.UDS_in_Sqyards__c = plt[i].UDS_in_Sqyards__c;
                    oppPlot.Floor_Rise_Charges_Rate__c = plt[i].Floor_Rise_Charge__c;
                    oppPlot.Utility_in_SFT__c = plt[i].Utility_in_SFT__c;
                    oppPlot.Car_Parking__c  = plt[i].Car_Parking__c;
                    oppPlot.Legal_Documentation_Charges__c  = plt[i].Legal_Documentation_Charges__c;
                    oppPlot.Maintenance_Charge__c=plt[i].Project__r.Maintenance_Charge_Rate__c;
                    oppPlot.amenities_charges__c=plt[i].amenities_charges__c;
                }
                if( plt[i].Unit_Type__c == 'Villa')
                {
                    unitType = 'Villas';
                    oppPlot.Plot_Land_Area__c = plt[i].Plot_Land_Area__c;
                    oppPlot.Land_Rate_Per_Sqft__c = plt[i].Land_Rate_Per_Sqft__c;
                }
                if( plt[i].Unit_Type__c == 'Row House')
                {
                    unitType = 'Row House';
                    oppPlot.Carpet_Area__c = plt[i].Carpet_Area__c;
                    oppPlot.Legal_Documentation_Charges__c  = plt[i].Legal_Documentation_Charges__c;
                }
                if( plt[i].Unit_Type__c  == 'Plot')
                {
                    unitType = 'Plots';
                    oppPlot.SLead__c=component.get('v.recordId');
                    oppPlot.Unit__c = plt[i].Id;
                    oppPlot.Plot_Type__c = plt[i].Plot_Type__c;
                    oppPlot.Block_Lookup__c = plt[i].Block_Lookup__c;
                    oppPlot.Project__c = plt[i].Project__r.Project__c;
                    oppPlot.Block__c = plt[i].Block__c;
                    oppPlot.Wing__c = plt[i].Wing__c;
                    oppPlot.BHK_Type__c = plt[i].BHK_Type__c;
                    oppPlot.Super_Built_UpArea__c = plt[i].Super_Built_up_Area__c;
                    oppPlot.Rate_per_sqft__c = plt[i].Rate_per_sqft__c;
                    oppPlot.Unit_Facing_Direction__c = plt[i].Unit_Facing_Direction__c;
                    oppPlot.Infrastructure_Charges_per_sqft__c = plt[i].Infrastructure_Charges_per_sqft__c;
                    oppPlot.Maintenance_Charge__c=plt[i].Project__r.Maintenance_Charge_Rate__c;
                    oppPlot.Clubhouse_Charges__c=plt[i].Project__r.Clubhouse_Charges__c;
                }
                
                component.set('v.projectType',unitType);
                oppPlot.Property_Type__c = unitType;
                oppPlot.Quote_date__c = today;
                component.set('v.today', today);
                component.set('v.RecTypeId',plt[i].Name);
                
                break;
            } 
        } 
        component.set('v.showCostSheet',true);
        component.set('v.oppPlot',oppPlot);
        component.set('v.matchplots',[]);
        component.set("v.isLoading",false);
        
    },
    handleCarParkingChange: function (component, event, helper) {
        var selected = event.getSource().get("v.value");
        if(selected == "Yes")
        {
            component.set("v.showAdditionalCarParking",true);
            
        }
        else
        {
            component.set("v.showAdditionalCarParking",false);
            component.set("v.oppPlot.Extra_car_parking_charges__c",0);
        }
    },
    navigateToPaymentSchedule: function (component, event, helper) {
        var selectedUnit = component.get("v.selectedUnit");
        var numberPattern = /^[0-9]+$/;
        var numberPattern2 = /^\d+(\.\d+)?$/;
        var primaryPhone = component.get("v.oppPlot.Referred_Contact_Number__c");
        var Booking_Referral_Percentage__c = component.get("v.oppPlot.Booking_Referral_Percentage__c");
        var Rate_per_sqft = component.get("v.oppPlot.Rate_per_sqft__c");
        var amenities_charges = component.get("v.oppPlot.amenities_charges__c");
        var Extra_car_parking_charges = component.get("v.oppPlot.Extra_car_parking_charges");
        var Discount_Price = component.get("v.oppPlot.Discount_Price__c");
         
        if(!selectedUnit)
        {
            helper.showToast('Error','Error','Please Select The Unit');
            return;
        }
        if (primaryPhone && (!numberPattern.test(primaryPhone) || primaryPhone.length != 10)) {
            helper.showToast('Error', 'Error', 'Please enter a valid 10-digit referred contact number');
            return;
        }
        if (Booking_Referral_Percentage__c && !numberPattern2.test(Booking_Referral_Percentage__c.toString())) {
            helper.showToast('Error', 'Error', 'Please enter a valid booking referral percentage');
            return;
        }
        if (Rate_per_sqft && !numberPattern.test(Rate_per_sqft.toString())) {
            helper.showToast('Error', 'Error', 'Please enter a valid Rate per sqft');
            return;
        }
        if (Discount_Price && !numberPattern2.test(Discount_Price.toString())) {
            helper.showToast('Error', 'Error', 'Please enter a valid Discount Price');
            return;
        }
        if (amenities_charges && !numberPattern2.test(amenities_charges.toString())) {
            helper.showToast('Error', 'Error', 'Please enter a valid Amenities Charges');
            return;
        }
        if (Extra_car_parking_charges && !numberPattern2.test(Extra_car_parking_charges.toString())) {
            helper.showToast('Error', 'Error', 'Please enter a valid Additional Car Parking Charges');
            return;
        }

        var payType = component.get("v.oppPlot.Payment_Type__c");
        if(payType != 'None'){
            helper.getmasterpaymentschedule(component,event,helper);
            component.set("v.showNextCmp", true);
        }
        else{
            helper.showToast('Error','Mandate Error','Please Select The Payment Type');
        }
        
    },
    
    /**Send For Approval**/
    redirectToQuote: function(component,event,helper) {
        let entereddiscount = component.get("v.oppPlot.Discount_Price__c");
        let discountLimit = component.get("v.discountLimit");
        console.log('discountLimit'+discountLimit);
        console.log('entereddiscount'+entereddiscount);
        if(entereddiscount > discountLimit){
            var action=component.get("c.callQuoteApproval");  
            action.setParams({'recId':  component.get('v.quoteId') });
            action.setCallback(this,function(response){
                if(response.getState()=="SUCCESS"){ 
                    helper.showToast('Success','Approval',"Quote Created and Submitted for Approval");
                    
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": component.get('v.quoteId'),
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                    component.set('v.quoteId','');
                }
            });
            $A.enqueueAction(action);
        }
        else
        {
            
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": component.get('v.quoteId'),
                "slideDevName": "detail"
            });
            navEvt.fire();
            component.set('v.quoteId','');
        }

    },
    doPreview: function(component, event, helper) {
        let schedules = [];
        let paymentPercentage = 0;
        let landPaymentPercentage = 0;
        let constructionPercentage = 0;
        
        const patType = component.get('v.paymentType');
        const projectType = component.get('v.projectType');
        
        // Get correct list
        if (patType === 'Standard') {
            schedules = component.get('v.paymentSchedules') || [];
        } else if (patType === 'Custom') {
            schedules = component.get('v.CustompaymentSchedules') || [];
        }
        
        if (patType === "Custom") {
            let missingFields = [];
            for (let index = 0; index < schedules.length; index++) {
                let item = schedules[index];
                let missing = [];
                
                if (!item.Name || item.Name.trim() === "") missing.push("Name");
                if (!item.Payment_percent__c) missing.push("Percent");
      
                
                if (projectType === "Villas" && (!item.Type__c || item.Type__c.trim() === "")) {
                    missing.push("Type");
                }
        
                
                if (missing.length > 0) {
                    helper.showToast(
                        "Error",
                        "Error",
                        "Please fill all mandatory fields in Sl.No " + (index + 1) + ": " + missing.join(", ")
                    );
                    return; 
                }
                
                // future Due Date validation
                if (item.status__c === "Scheduled" || item.status__c === "Demanded") {
                    const dueDate = new Date(item.Payment_Due_Date__c);
                    const today = new Date();
                    today.setHours(0, 0, 0, 0);
                    if (dueDate <= today) {
                        helper.showToast(
                            "Error",
                            "Error",
                            " Sl.No " + (index + 1) + ": Due Date should be a future date"
                        );
                        return;
                    }
                }
            }
        }
        

        // Calculate totals
        schedules.forEach(function(item, index) {
            const percent = parseFloat(item.Payment_percent__c) || 0;
            paymentPercentage += percent;
            
            if (projectType === 'Villas') {
                if (item.Type__c === 'Land' || item.Is_Land__c) {
                    landPaymentPercentage += percent;
                } else if (item.Type__c === 'Construction' || item.Is_Construction__c) {
                    constructionPercentage += percent;
                }
            }
        });
        
        
        // Validation for Villas
        if (projectType === 'Villas') {
            if (landPaymentPercentage !== 100 && constructionPercentage !== 100) {
                helper.showToast(
                    "Error",
                    "Both Land and Construction percentages must total 100%.",
                    "error"
                );
                return;
            } 
            else if (landPaymentPercentage !== 100) {
                helper.showToast(
                    "Error",
                    "Land Payment Percentage must be exactly 100%. (Current: " + landPaymentPercentage + "%)",
                    "error"
                );
                return;
            } 
            else if (constructionPercentage !== 100) {
                helper.showToast(
                    "Error",
                    "Construction Payment Percentage must be exactly 100%. (Current: " + constructionPercentage + "%)",
                    "error"
                );
                return;
            }
        }
        // Validation for Plots / Apartments
        else if (
            (projectType === 'Plots' || projectType === 'Apartments' || projectType === 'Row House') &&
            paymentPercentage !== 100
        ) {
            helper.showToast(
                "Error",
                "Total Payment Percentage must be exactly 100%. (Current: " + paymentPercentage + "%)",
                "error"
            );
            return;
        }
        
     
        helper.previewsave(component, event, helper);
    },

    handleChange: function (component, event, helper) {
        var selectedOptionValue = event.getSource().get("v.value");
        component.set("v.paymentType", selectedOptionValue);
        //component.set("v.showNextCmp", selectedOptionValue !== "Custom" && selectedOptionValue !== "Standard");
    },
    closeModel: function(component, event, helper) {
        $A.get('e.force:closeQuickAction').fire();
        $A.get('e.force:refreshView').fire();
    },
    handlePrevious: function (component, event, helper) {
        component.set("v.showNextCmp", false);
        component.set('v.paymentSchedules',[]);
    },
    handlePreviewPrevious: function (component, event, helper) {
        component.set("v.showNextCmp", false);
        component.set("v.showPreview", false);
        component.set('v.paymentSchedules',[]);
        
        var action=component.get("c.deleteQuote");  
        action.setParams({'recId':  component.get('v.quoteId') });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                
                component.set('v.quoteId','');
            }
        });
        $A.enqueueAction(action);
        
    },
    
    /**Paymemt Scdules**/
    addRow: function(component, event, helper) {
        helper.addProductRecord(component, event,helper);
    },
    removeRow: function(component, event, helper) {
        
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        console.log(index);
        var oitems= component.get('v.CustompaymentSchedules');
        console.log(oitems);
        console.log(oitems[index].Id);
        if(oitems[index].Id !='undefined' && oitems[index].Id !='' && oitems[index].Id !=undefined){
            console.log('in');
            
            if( oitems[index].Payment_percent__c !='' && oitems[index].Payment_percent__c !=undefined){
                var grandtotal = (component.get('v.GrandTotal')-oitems[index].Amount__c);
                var recivedamount = (component.get('v.RecivedAmountTotal')-oitems[index].Received_Amount__c);
                var perct = (component.get('v.totalPercent')-oitems[index].Payment_percent__c);
                component.set('v.GrandTotal',grandtotal.toFixed(2));
                component.set('v.RecivedAmountTotal',recivedamount.toFixed(2));
                component.set('v.totalPercent',perct);
            }
            oitems.splice(index, 1);
            for (var i = 0; i < oitems.length; i++) {
                oitems[i].S_No__c = i+1;
            }        
            component.set("v.CustompaymentSchedules", oitems);
            
            if(oitems.length < 1){
                helper.addProductRecord(component, event,helper);
            }
            
        }else{
            console.log(oitems[index].Payment_percent__c);
            if( oitems[index].Payment_percent__c !='' && oitems[index].Payment_percent__c !=undefined){
                var grandtotal = (component.get('v.GrandTotal')-oitems[index].Amount__c);
                var recivedamount = (component.get('v.RecivedAmountTotal')-oitems[index].Received_Amount__c);
                console.log(grandtotal);
                var perct = (component.get('v.totalPercent')-oitems[index].Payment_percent__c);
                console.log(perct);
                component.set('v.GrandTotal',grandtotal.toFixed(2));
                component.set('v.RecivedAmountTotal',recivedamount.toFixed(2));
                component.set('v.totalPercent',perct);
                console.log('d');
            }
            oitems.splice(index, 1);
            for (var i = 0; i < oitems.length; i++) {
                oitems[i].S_No__c = i+1;
            }  
            console.log('s');
            component.set("v.CustompaymentSchedules", oitems);
            
            if(oitems.length < 1){
                helper.addProductRecord(component, event);
            } 
            
        }
    },

 

    /**Not in Use **/
    handleGSTAggrementOptionChange : function(component, event, helper) {
        var selPlot= component.get('v.plots');
        var oppPlot = component.get('v.oppPlot');
        var selectedValue = component.find("gstAggremSelect").get("v.value");
        if (selectedValue === "Yes") {
            component.set('v.isGSTChecked', true);
            oppPlot.GST_for_Aggrement_Value__c=selPlot[0].Project__r.GST_on_Aggrement__c;
        }
        else {
            oppPlot.GST_for_Aggrement_Value__c=0;
        }
        component.set('v.oppPlot',oppPlot);
    },
    handleGSTOtherOptionChange : function(component, event, helper) {
        var selPlot= component.get('v.plots');
        var oppPlot = component.get('v.oppPlot');
        var selectedValue = component.find("gstOthSelect").get("v.value");
        if (selectedValue === "Yes") {
            component.set('v.isgstonOtherChecked', true);
            oppPlot.GST_For_Other_Charges__c=selPlot[0].Project__r.GST_on_Other__c;
        }
        else {
            oppPlot.GST_For_Other_Charges__c=0;
        }
        component.set('v.oppPlot',oppPlot);
    },
    handleDiscountChange : function(component, event, helper) {
        let discount = component.get("v.oppPlot.Discount_Price__c");
        
        if(discount > 200){
            // Show error message
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Validation Error",
                "message": "Discount cannot be greater than 200.",
                "type": "error"
            });
            toastEvent.fire();
            
            // Reset field value
            component.set("v.oppPlot.Discount_Price__c", null);
            return;
        }
    },
    fillDueDate : function(component, event, helper) {
        var paymentSchedules = component.get("v.paymentSchedules");
        var changedDueDate = event.getSource().get("v.value");
        // Iterate through the paymentSchedules and update due dates for completed items
        paymentSchedules.forEach(function(item) {
            if (item.status__c === 'Completed') {
                item.Payment_Due_Date__c = changedDueDate;
            }
        });
        
        // Update the attribute to reflect the changes
        component.set("v.paymentSchedules", paymentSchedules);
    },
})