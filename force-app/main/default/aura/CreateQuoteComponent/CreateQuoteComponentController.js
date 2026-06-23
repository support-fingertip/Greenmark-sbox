({
    doInit: function(component, event, helper) {
        // Project Value
        var proj=component.get("c.getPicklistValues");
        proj.setParams({'objectName':  'Lead' ,
                        'fieldName': 'Allocated_Project__c'});
        proj.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var prval = response.getReturnValue();
                component.set("v.projectlist",prval);
                component.set('v.showBlocks',true);
                
            }
        });
        $A.enqueueAction(proj);
        
        helper.addProductRecord(component, event,helper);
        
        var action1 = component.get("c.getPaymentTypePicklistValues");
        action1.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var paymentTypePicklist = response.getReturnValue();
                component.set("v.paymentTypePicklist", paymentTypePicklist);
            }
        });
        $A.enqueueAction(action1);
        
        
        
        
    },
     calculatePaymentPercent: function(component, event, helper) {
        var paymentlist = component.get("v.CustompaymentSchedules");
         var paymentpercentage = 0;
         paymentlist.forEach(function(item){
             paymentpercentage += item.Payment_percent__c;
         });
         if(paymentpercentage > 100)
         {
               helper.showToast("Error","Payment Percentage should not exceed more then 100.","Error");
         }
    },
    handleInputChange: function(component, event, helper) {
        helper.handleCalculations(component, event, helper);
    },
    
    handleProjectChange: function(component, event, helper) {
        
        var selectedValue = component.find("projectSelect").get("v.value");
          component.set('v.projectName', selectedValue);
                  
        //alert(selectedValue)
        //
        // Get the Project Detail
        var action = component.get("c.getProjectType");
        action.setParams({ project: selectedValue });
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var project = response.getReturnValue();
                  component.set('v.projecttype', project);
                  
                if(project=='Villas'){
                    component.set('v.showBlockLookup',false);
                     component.set('v.showUnits',true);
                      var action=component.get("c.getvillasPlots");
                     action.setParams({'project':  selectedValue });
                    action.setCallback(this,function(response){
                        if(response.getState()=="SUCCESS"){ 
                             var result = response.getReturnValue();
                             component.set("v.plots",result);
                           component.set("v.showUnits",true);
                        }
                        else{
                            
                        }
                    });
        $A.enqueueAction(action);
       
                   
                }
                else{
                    var action=component.get("c.getblocks");  
                    
                    action.setParams({'project':selectedValue});
                    action.setCallback(this,function(response){
                        
                        if(response.getState()=="SUCCESS"){ 
                            var blocks = response.getReturnValue();
                            component.set('v.blocks',blocks);
                            component.set('v.showBlockLookup',true);
                            component.set("v.searchText2", ""); // Clearing the Block search text
                            component.set("v.matchblocks", []); // Clearing the Block matches
                            component.set("v.searchText1", ""); // Clearing the Unit search text
                            component.set("v.matchplots", []); // Clearing the Unit matches
                            
                            var oppPlot = component.get('v.oppPlot');
                            oppPlot.Unit__c = '';
                            component.set('v.oppPlot',oppPlot);
                            
                            // getting Payment Plan
                            
                        }
                    });
                    $A.enqueueAction(action);
                    
                }
            }
            else{
                
            }
        });
        $A.enqueueAction(action);
        
        
    },
    searchText1 : function(component, event, helper) {
        //alert('Enetr 1');
        var plot= component.get('v.plots');
        //alert(plot);
        component.set('v.showCostSheet',false);
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
        }
    },
    searchText2 : function(component, event, helper){
        
        var block= component.get('v.blocks');
        component.set('v.showCostSheet',false);
        var searchText1= component.get('v.searchText2');
        console.log(searchText1.length)
        if(searchText1.length < 1){
            console.log(searchText1)
        }
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
            component.set('v.matchblocks',[]);
        }
    },
    update2 : function(component, event, helper){
        var edi =  event.currentTarget.dataset.id;
        var plt= component.get('v.matchblocks');
        var selPlot= component.get('v.blocks');
        var oppPlot = component.get('v.oppPlot');
        
        var selectedValue = component.find("projectSelect").get("v.value");
      //  alert(selectedValue)
        for(var i=0;i<plt.length; i++){  
            if(plt[i].Id ===  edi ){
                if(plt[i].Name!=null)
                {
                    component.set('v.searchText2', plt[i].Name);
                    var block = component.get('v.searchText2');
                    var action=component.get("c.getPlots");  
                    action.setParams({'block':  block,
                                     'project':  selectedValue });
                    action.setCallback(this,function(response){
                        if(response.getState()=="SUCCESS"){ 
                            
                            var result = response.getReturnValue();
                            component.set("v.plots",result);
                            component.set("v.showNextCmp", false);
                            component.set('v.showUnits',true);
                            component.set('v.isNotApartment',true);
                            component.set('v.blockId',edi);
                            component.set('v.matchblocks',[]);
                        }
                    });
                    $A.enqueueAction(action);
                }
                oppPlot.Block1__c = plt[i].Id;
                selPlot = plt[i];
               // component.set('v.blocks', selPlot);
                component.set('v.oppPlot',oppPlot);
            }
        }
        
    },
    
    update1: function(component, event, helper) {
        component.set('v.Showfields', false);
        var edi =  event.currentTarget.dataset.id;
        var plt= component.get('v.matchplots');
        var selPlot= component.get('v.plots');
        var oppPlot = component.get('v.oppPlot');
        var opp = component.get("v.OppRecord");
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        for(var i=0;i<plt.length; i++){  
            if(plt[i].Id ===  edi ){
                if(plt[i].Name!=null)
                {
                    component.set('v.Showfields', true);
                    component.set('v.searchText1', plt[i].Name);
                    component.set('v.projectName', plt[i].Project__r.Name);
                    component.set('v.flatNumber', plt[i].Name);
                    //alert(plt[i].Block1__c);
                    component.set('v.blockName', plt[i].Block1__c);
                }
                selPlot = plt[i];
               // alert(plt[i].Project__r.Project_Type__c)
                if(plt[i].Project__r.Project_Type__c=='Villas'){
                    oppPlot.RecordTypeId='012H3000000rcxMIAQ';
                oppPlot.Villa_No__c = plt[i].Name;
                    oppPlot.Booking_Amount__c = 2500000;
                      component.set('v.flatVilla', 'Villa');
                  
                }else{
                    oppPlot.RecordTypeId='012H3000000rcoNIAQ';
                oppPlot.Flat_No__c = plt[i].Name;
                      component.set('v.flatVilla', 'Flat');
                  
                    
                }
                oppPlot.SLead__c=component.get('v.recordId');
                oppPlot.Unit__c = plt[i].Id;
                oppPlot.Block_Lookup__c = plt[i].Block1__c;
                oppPlot.Project__c = plt[i].Project__r.Name;
                oppPlot.Plot_Type__c = plt[i].Project__r.Plot_Type__c;
                //oppPlot.Plot_Number__c = plt[i].Plot_Number__c;
                oppPlot.Plot_Size__c = plt[i].Plot_Size__c;
                oppPlot.Unit_Facing_Direction__c = plt[i].Unit_Facing_Direction__c;
                oppPlot.BHK_Type__c = plt[i].BHK_Type__c;
                oppPlot.Basic_Price__c = plt[i].Basic_Price__c;
                // oppPlot.Tower__c = plt[i].Tower__c;
                oppPlot.East_North_Charges__c = plt[i].East_North_Charges__c;
                oppPlot.Corner_Charges__c = plt[i].Corner_Charges__c;
                oppPlot.Piped_Gas__c = plt[i].Piped_Gas__c;
                oppPlot.Mutation__c = plt[i].Mutation__c;
                oppPlot.Stamps_Duty__c = plt[i].Stamps_Duty__c;
                oppPlot.Floor_Rise_Charges_Rate__c = plt[i].Floor_Rise__c;
                
                
                oppPlot.BESCOM_Deposit_Rs__c = plt[i].BESCOM_Deposit_Rs__c;
                //oppPlot.East_Facing__c = plt[i].East_Facing__c;
                oppPlot.Sale_Area__c = plt[i].Sale_Area__c;
                if(plt[i].Sale_Area__c<1400){
                    component.set('v.singlecarparking', true);
                    component.set('v.waterconnectiondoublebed', true);
                    oppPlot.Single_Car_Parking__c = plt[i].Single_Car_Parking__c;
                    oppPlot.Water_Connection_Charges_for_Double_Bed__c = plt[i].Water_Connection_Charges_for_Double_Bed__c;
                    
                }
                //oppPlot.Car_Parking_Charge__c = plt[i].Car_Parking_Charge__c;
                //oppPlot.Infrastructure_Charges_per_sqft__c = plt[i].Infrastructure_Charges_per_sqft__c;
                oppPlot.Built_up_area__c = plt[i].Built_up_area__c;
                oppPlot.Carpet_Area__c = plt[i].Carpet_Area__c;
                //oppPlot.Balcony_Area__c = plt[i].Terrace_Area__c;
                oppPlot.GST1__c = plt[i].GST1__c;
                //oppPlot.Block__c = plt[i].Block__c;
                oppPlot.Development_Charge__c = plt[i].Development_Charge__c;
                oppPlot.Maintenance_Charge__c = plt[i].Maintenance_Charge__c;
                oppPlot.Premium_Charge__c = plt[i].Premium_Charge__c;
                oppPlot.Plot_Land_Area__c = plt[i].Plot_Land_Area__c;
                oppPlot.Clubhouse_Charges__c = plt[i].Clubhouse_Charges__c;
                oppPlot.Legal_Documentation_Charges__c = plt[i].Legal_Charges__c;
                oppPlot.Corpus_Fund__c = plt[i].Corpus_Fund__c;
                oppPlot.Maintenance_Deposite__c = plt[i].Maintenance_Deposite__c;
                oppPlot.Apartment_No__c = plt[i].Apartment_No__c;
                oppPlot.Fixed_Land_Sqft__c = plt[i].Fixed_Land__c;
                oppPlot.Extra_Land_Sqft__c = plt[i].Extra_Land__c;
                oppPlot.Fixed_Land_Charges__c = plt[i].Fixed_Land_Charges__c;
                oppPlot.Amenities_Charges_For_Villa__c = plt[i].amenities_charges__c;
                oppPlot.Project_Type__c = plt[i].Project__r.Project_Type__c;
                oppPlot.Floor__c = plt[i].Floor__c;
                oppPlot.Corpus_Fund_for_Villas__c = plt[i].Corpus_Fund_for_Villas__c;
                oppPlot.Park_Facing__c = plt[i].Park_Facing__c;
                oppPlot.Corner_charges_for_Villa__c = plt[i].Corner_charges_for_Villa__c;
                oppPlot.East_north_Charges_for_Villa__c = plt[i].East_north_Charges_for_Villa__c;
                oppPlot.Maintenance_Charge_For_Villa__c = plt[i].Maintenance_Charge_For_Villa__c;
                oppPlot.Park_Facing__c = plt[i].Park_Facing__c;
                
                oppPlot.Quote_date__c = today;
                
                
                component.set('v.today', today);
                component.set('v.RecTypeId',plt[i].Name);
                helper.handleCalculations(component, event, helper);    
                break;
            } 
        } 
        component.set('v.showCostSheet',true);
       // component.set('v.plots', selPlot);
        //alert('Update 3');
        component.set('v.oppPlot',oppPlot);
        component.set('v.matchplots',[]);
        
    },
    
    
    navigateToPaymentSchedule: function (component, event, helper) {
        //alert('paymentType 1 :'+  component.get("v.oppPlot.Payment_Type__c"));
        //alert('calling the payment');
        //alert(component.get("v.GrandTotal"));
        var payType = component.get("v.oppPlot.Payment_Type__c");
        if(payType != 'None'){
            //helper.getFilteredLead(component,event,helper);
            helper.getmasterpaymentschedule(component,event,helper);
            
            //  helper.handleCalculations(component,event,helper);
            component.set("v.showNextCmp", true);
        }
        else{
            helper.showToast('Error','Mandate Error','Please Select The Payment Type');
        }
        
        
        
    },
    doSave: function(component,event,helper) {
        
        
        if (helper.validate(component, event)) {
            helper.save(component,event,helper);
        }
    },
    
    handleChange: function (component, event, helper) {
        
        var selectedOptionValue = component.find("select").get('v.value');  
        component.set('v.paymentType',selectedOptionValue);
        //alert(selectedOptionValue);
        if(selectedOptionValue=='None')
        {
            helper.showToast('Error','Mandate Error','Please Select The Payment Type');
            $A.get("e.force:closeQuickAction").fire();
        } 
        
        var paymentType = component.find("select").get("v.value");
        if (paymentType === "Custom") {
            component.set("v.showNextCmp", false);
        }
        else if (paymentType === "Standard") {
            component.set("v.showNextCmp", false);
        }
    },
    closeModel: function(component, event, helper) {
        
        
        //   var homeEvt = $A.get("e.force:navigateToObjectHome");
        //  homeEvt.setParams({
        //      "scope": "Lead"
        //  });
        // homeEvt.fire();
        $A.get('e.force:closeQuickAction').fire();
        $A.get('e.force:refreshView').fire();
        
        
    },
    
    handlePrevious: function (component, event, helper) {
        component.set("v.showNextCmp", false);
        component.set('v.paymentSchedules',[]);
    },
    addRow: function(component, event, helper) {
        //alert('hello ocean');
        helper.addProductRecord(component, event,helper);
    },
    
    removeRow: function(component, event, helper) {
        //alert('hello remove');
        //var quoteList = component.get("v.QuoteItemList");
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
    fillDueDate : function(component, event, helper) {
        //alert('changedDueDate');
        var paymentSchedules = component.get("v.paymentSchedules");
        //alert('paymentSchedules');
        var changedDueDate = event.getSource().get("v.value");
        //alert(changedDueDate);
        // Iterate through the paymentSchedules and update due dates for completed items
        paymentSchedules.forEach(function(item) {
            if (item.status__c === 'Completed') {
                item.Payment_Due_Date__c = changedDueDate;
            }
        });
        
        // Update the attribute to reflect the changes
        component.set("v.paymentSchedules", paymentSchedules);
    },
    
    handlesinglecarCheckboxChange : function(component, event, helper) {
        var singlecar = component.find("checkbox").get("v.checked");
        if(singlecar){
            
            var selPlot= component.get('v.plots');
            var sg = selPlot[0].Single_Car_Parking__c;
            var oppPlot = component.get('v.oppPlot');
            oppPlot.Single_Car_Parking__c=sg;
            component.set('v.oppPlot',oppPlot);
        }
        
        //alert(JSON.Stringify(oppPlot))
        
    },
    handletwocarbbCheckboxChange : function(component, event, helper) {
        var twocarbb = component.find("twocarcheckbox").get("v.checked");
        //  alert(checkboxValue);
        if(twocarbb){
            
            var selPlot= component.get('v.plots');
            var sg = selPlot[0].Two_Car_Parking_Back_to_Back__c;
            var oppPlot = component.get('v.oppPlot');
            oppPlot.Two_Car_Parking_Back_to_Back__c=sg;
            component.set('v.oppPlot',oppPlot);
        }
        
        
    },
    handletwocarssCheckboxChange : function(component, event, helper) {
        var twocarss = component.find("twocarsscheckbox").get("v.checked");
        if(twocarss){
            var selPlot= component.get('v.plots');
            var sg = selPlot[0].Two_Car_Parking_Side_by_Side__c;
            var oppPlot = component.get('v.oppPlot');
            oppPlot.Two_Car_Parking_Side_by_Side__c=sg;
            component.set('v.oppPlot',oppPlot);
            
        }
        
        
    },
    handledoulebedChange : function(component, event, helper) {
        var doublebed = component.find("doublecheckbox").get("v.checked");
        if(doublebed){
            var selPlot= component.get('v.plots');
            var oppPlot = component.get('v.oppPlot');
            oppPlot.Water_Connection_Charges_for_Double_Bed__c=selPlot[0].Water_Connection_Charges_for_Double_Bed__c;
            component.set('v.oppPlot',oppPlot);
            
        }
        
        
    },
    handletriplebedChange : function(component, event, helper) {
        var tripple = component.find("triplecheckbox").get("v.checked");
        if(tripple){
            var selPlot= component.get('v.plots');
            var oppPlot = component.get('v.oppPlot');
            oppPlot.Water_Connection_Charges_for_Trippe_Bed__c=selPlot[0].Water_Connection_Charges_for_Trippe_Bed__c;
            component.set('v.oppPlot',oppPlot);
            
        }
        
        
    },
    
    handleParkingOptionChange : function(component, event, helper) {
        component.set('v.isSingleCheckboxChecked', false);
        component.set('v.isTwoCarBBCheckboxChecked', false);
        component.set('v.isTwoCarSSCheckboxChecked', false);
        
        var selPlot= component.get('v.plots');
        var oppPlot = component.get('v.oppPlot');
        
        var selectedValue = component.find("parkingSelect").get("v.value");
        component.set("v.selectedOption", selectedValue);
        
        if (selectedValue === "Single Car Parking Required") {
            
            component.set('v.isSingleCheckboxChecked', true);
            oppPlot.Single_Car_Parking__c=selPlot[0].Single_Car_Parking__c;
            
        } else if (selectedValue === "Two Car Parking (Back to Back) Required") {
            
            component.set('v.isTwoCarBBCheckboxChecked', true);
            oppPlot.Two_Car_Parking_Back_to_Back__c=selPlot[0].Two_Car_Parking_Back_to_Back__c;
            
        } else if (selectedValue === "Two Car Parking (Side by Side)") {
            
            component.set('v.isTwoCarSSCheckboxChecked', true);
            oppPlot.Two_Car_Parking_Side_by_Side__c=selPlot[0].Two_Car_Parking_Side_by_Side__c;
            
        } else {
        }
        component.set('v.oppPlot',oppPlot);
        
    }
    ,
    handleWaterConnectionOptionChange : function(component, event, helper) {
        component.set('v.isdoulebedCheckboxChecked', false);
        component.set('v.istrippleBedCheckboxChecked', false);
        
        var selPlot= component.get('v.plots');
        var oppPlot = component.get('v.oppPlot');
        
        var selectedValue = component.find("waterConnectionSelect").get("v.value");
        //  component.set("v.selectedOption", selectedValue);
        
        if (selectedValue === "Water Connection Charges for Double Bed") {
            
            component.set('v.isdoulebedCheckboxChecked', true);
            oppPlot.Water_Connection_Charges_for_Double_Bed__c=selPlot[0].Water_Connection_Charges_for_Double_Bed__c;
            
        } else if (selectedValue === "Water Connection Charges for Triple Bed") {
            
            component.set('v.istrippleBedCheckboxChecked', true);
            oppPlot.Water_Connection_Charges_for_Trippe_Bed__c=selPlot[0].Water_Connection_Charges_for_Trippe_Bed__c;
            
        } 
            else {
            }
        component.set('v.oppPlot',oppPlot);
        
    }
    
})