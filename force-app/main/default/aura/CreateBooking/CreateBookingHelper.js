({
    MAX_FILE_SIZE: 4500000, // Max file size 4.5 MB
    CHUNK_SIZE: 750000,      // Chunk Max size 750 KB
    
    addAppliacantRecord: function(component, event, helper) {
        var appList = component.get("v.applicantList");

        // Add new record if none exists
        appList.push({
            'sObjectType': 'Co_Applicant__c',
            'Salutation__c': "Mr.",
            'Name': '',
            'Age__c': '',
            'Son_Daughter_Wife_of__c': '',
            'PAN_Number__c': '',
            'Email__c': '',
            'Primary_Phone__c': '',
            'Occupation__c': '',
        });
        
        component.set("v.applicantList", appList);
    },

    uploadFile: function(component, event, fileInput, fileType) {
        var file = fileInput[0];
        var self = this;
        //alert('file'+JSON.stringify(file));
        if (file.size > self.MAX_FILE_SIZE) {
            component.set('v.fileName', 'Alert: File size cannot exceed ' + self.MAX_FILE_SIZE + ' bytes.\n' + 'Selected file size: ' + file.size);
            return;
        }
        
        var objFileReader = new FileReader();
        objFileReader.onload = $A.getCallback(function() {
            var fileContents = objFileReader.result;
            var base64 = 'base64,';
            var dataStart = fileContents.indexOf(base64) + base64.length;
            fileContents = fileContents.substring(dataStart);
            self.uploadProcess(component, file, fileContents, fileType);
        });
        
        objFileReader.readAsDataURL(file);
    },
    uploadProcess: function(component, file, fileContents, fileType) {
        var startPosition = 0;
        var endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
        this.uploadInChunk(component, file, fileContents, startPosition, endPosition, '', fileType);
    },
    uploadInChunk: function(component, file, fileContents, startPosition, endPosition, attachId, fileType) {
        var getchunk = fileContents.substring(startPosition, endPosition);
        var action = component.get('c.saveFile');
        action.setParams({
            parentId: component.get('v.bookingid'),
            fileName:  file.name,
            base64Data: encodeURIComponent(getchunk),
            contentType: file.type,
            fileType: fileType               
        });
        
        action.setCallback(this, function(response) {
            attachId = response.getReturnValue();
            var state = response.getState();
            if (state === 'SUCCESS') {
                startPosition = endPosition;
                endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
                if (startPosition < endPosition) {
                    this.uploadInChunk(component, file, fileContents, startPosition, endPosition, attachId);
                } else {
                    this.showToast('success', 'Success!', 'File has been uploaded successfully');
                }
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('Error message: ' + errors[0].message);
                    }
                } else {
                    console.log('Unknown error');
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    validateFields: function(component, event, helper) {
        var book = component.get("v.book");
        var applicantList = component.get("v.applicantList");
        
        var fieldLabels = {
            'Booking_Date__c': 'Booking Date',
            'Booking_Amount__c': 'Booking Amount',
            'Mode_Of_Payment__c': 'Mode of Payment',
            'Transaction_ID__c': 'Transaction No.',
            'Funding_Type__c': 'Funding Type',
            'Bank_Name__c': 'Bank Name',
            'Branch_Name__c': 'Branch Name',
            'Type_of_Aggrement__c': 'Type of Agreement',
            
            'First_Applicant_Name__c': 'First Applicant Name',
            'Age__c': 'Age',
            'Son_Daughter_Wife_of1__c': 'S/O',
            'Occupation__c': 'Occupation',
            'Mobile__c': 'Mobile',
            'Email__c': 'Email',
            
            'Address__c': 'Current Address',
            'Pincode__c': 'Current Address Pincode',
            'Permanent_Address1__c': 'Permanent Address',
            'Pincode1__c': 'Permanent Address Pincode'
        };
        
        var coappFieldLabels = {
            'Name': 'Co-Applicant Name',
            'Age__c': 'Age',
            'Son_Daughter_Wife_of__c': 'S/O',
            'Occupation__c': 'Occupation',
            'Primary_Phone__c': 'Primary Phone',
            'Email__c': 'Email'
        };
        
        var mandatoryFields = Object.keys(fieldLabels);
        var mandatoryCoFields = Object.keys(coappFieldLabels);
        
        var isValid = true;
        
        // Validate main applicant fields
        var missingFields = mandatoryFields.filter(function(field) {
            return !book[field];
        });
        
        if (missingFields.length > 0) {
            isValid = false;
            var missingFieldsList = missingFields.map(function(field) {
                return fieldLabels[field];
            }).join(', ');
            var message = "The following fields are missing: " + missingFieldsList;
            this.showToast('Error', 'Error!', message);
            return isValid;
        }
        
        // Loan-related validation
        if (book.Funding_Type__c === 'Loan') {
      
            if (!book.Loan_Percentage__c || book.Loan_Percentage__c ==0) {
                isValid = false;
                this.showToast('Error', 'Error!', "Loan Percentage is mandatory when Funding Type is 'Loan'.");
                return isValid;
            }
         
        }
        
        // Payment Mode validation
        /*if (book.Mode_Of_Payment__c === 'Credit Card' || book.Mode_Of_Payment__c === 'Debit Card') {
            if (!book.Credit_Debit_Card_Number__c) {
                isValid = false;
                this.showToast('Error', 'Error!', "Credit/Debit Card Number is mandatory when Mode of Payment is 'Credit Card' or 'Debit Card'.");
                return isValid;
            }
        }*/
        
        if (book.Mobile__c) {
            var numberPattern = /^[0-9]+$/;
            if (!numberPattern.test(book.Mobile__c) ||  book.Mobile__c.length != 10) {
                isValid = false;
                this.showToast('Error', 'Error!', "Please enter valid 10 digit customer primary phone number");
                return isValid;
            }
        }
        
        if (book.Pincode__c) {
            var numberPattern = /^[0-9]+$/;
            if (!numberPattern.test(book.Pincode__c) ||  book.Pincode__c.length != 6) {
                isValid = false;
                this.showToast('Error', 'Error!', "Please enter valid 6 digit Current Address Pincode");
                return isValid;
            }
        }
        
        
        if (book.Pincode1__c) {
            var numberPattern = /^[0-9]+$/;
            if (!numberPattern.test(book.Pincode1__c) ||  book.Pincode1__c.length != 6) {
                isValid = false;
                this.showToast('Error', 'Error!', "Please enter valid 6 digit Permanent Address Pincode");
                return isValid;
            }
        }
        
              

    
        
        if (applicantList && applicantList.length > 0)
        {
            for (let index = 0; index < applicantList.length; index++) {
                let applicant = applicantList[index];
                // Find which mandatory fields are missing
                let missingFields = mandatoryCoFields.filter(function(field) {
                    return !applicant[field];
                });
                // If any mandatory field is missing — show only for this row
                if (missingFields.length > 0) {
                    let missingFieldNames = missingFields
                    .map(function(field) {
                        return coappFieldLabels[field];
                    })
                    .join(', ');
                    
                    isValid = false;
                    this.showToast(
                        'Error',
                        'Error!',
                        'Please fill all mandatory fields for Co-Applicant ' + (index + 1) + ': ' + missingFieldNames
                    );
                    return isValid; // stop checking further rows
                }
            }
            //  Row-wise validations for each Co-Applicant
            for (let i = 0; i < applicantList.length; i++) {
                let applicant = applicantList[i];
                
                // Validate Mobile
                if (applicant.Primary_Phone__c) {
                    const phonePattern = /^[0-9]{10}$/;
                    if (!phonePattern.test(applicant.Primary_Phone__c)) {
                        isValid = false;
                        this.showToast(
                            'Error',
                            'Error!',
                            'Co-Applicant ' + (i + 1) + ': Please enter a valid 10-digit mobile number'
                        );
                        return isValid;
                    }
                }
                
        
                
                // Validate Age
             
                    if (!applicant.Age__c || applicant.Age__c < 18 || applicant.Age__c > 100) {
                        isValid = false;
                        this.showToast(
                            'Error',
                            'Error!',
                            'Co-Applicant ' + (i + 1) + ': Age must be between 18 and 100.'
                        );
                        return isValid;
                    }
                }
                
            }  
        else
        {
            isValid = false;
            this.showToast('Error', 'Error!', "Please add at least one co-applicant.");
            return isValid;
        }

        
            
        // File upload validation
       /* var first = component.get("v.fileName");
        var second = component.get("v.file2ndName");
        var third = component.get("v.file3rdName");
        var fourth = component.get("v.file4thName");
        
        if (first === 'Upload Government issued photo identity proof..') {
            this.showToast('Error', 'Error!', "Please upload Government issued photo identity proof.");
            isValid = false;
            return isValid;
        }
        if (second === 'Upload PAN Photo..') {
            this.showToast('Error', 'Error!', "Please upload PAN Photo.");
            isValid = false;
            return isValid;
        }
        if (third === 'Upload Applicant Photo..') {
            this.showToast('Error', 'Error!', "Please upload Applicant Photo.");
            isValid = false;
            return isValid;
        }
        if (fourth === 'Upload Proof of Address..') {
            this.showToast('Error', 'Error!', "Please upload Proof of Address.");
            isValid = false;
            return isValid;
        }*/
        
        return isValid;
    },

    saveRecord : function(component,event,helper) {
        component.set("v.isLoadingNew", true);
        var action = component.get("c.convertQuote");
        var book = component.get("v.book");
        action.setParams({ 
            recId: component.get("v.recordId"),
            book: component.get("v.book"),
            applicantList : component.get("v.applicantList")
        });
        action.setCallback(this, function(response) {
            var state=response.getState();
            console.log('Response : '+response.getReturnValue());            
            if(state==='SUCCESS'){
                var db = response.getReturnValue();
                if(db =='Unit not available'){
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type":'Error',
                        "title": 'Error!',
                        "message":'Unit not available',
                        "duration":10000
                    });
                    toastEvent.fire(); 
                }
                else{
                    if(db !='' && db !=null){
                     
                        console.log('entered--');
                        component.set('v.bookingid',db);
                        var first = component.get("v.fileName");
                        var second = component.get("v.file2ndName");
                        var third = component.get("v.file3rdName");
                        var fourth = component.get("v.file4thName");
                        
                        if(first!='Upload Government issued photo identity proof..'){
                            helper.uploadHelper(component, event,'Government Photo Identity');
                        }
                        if(second!='Upload PAN Photo..'){
                            helper.upload2Helper(component, event,'Pan Card'); 
                        }
                        if(third!='Upload Applicant Photo..'){  
                            helper.upload3Helper(component, event, 'Applicant Photo');
                        }
                        if(fourth !='Upload Proof of Address..'){
                            helper.upload3Helper(component, event,'Address Proof');
                        }
                        component.set("v.isLoadingNew", false);
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": db,
                            "slideDevName": "detail"
                        });
                        navEvt.fire();
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type":'Success',
                            "title": 'Success!',
                            "message":'Booking created successfully',
                            "duration":10000
                        });
                        toastEvent.fire();
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

    
    uploadHelper: function(component, event, fileType) {
        var fileInput = component.find('fuploader').get('v.files');
        this.uploadFile(component, event,fileInput,fileType);
    },
    upload2Helper: function(component, event, fileType) {
        var fileInput = component.find('fuploader2').get('v.files');
        this.uploadFile(component, event,fileInput,fileType);
    },
    upload3Helper: function(component, event, fileType) {
        var fileInput = component.find('fuploader3').get('v.files');
        this.uploadFile(component, event,fileInput,fileType);
    },
    upload4Helper: function(component, event, fileType) {
        var fileInput = component.find('fuploader4').get('v.files');
        this.uploadFile(component, event,fileInput,fileType);
    },
})