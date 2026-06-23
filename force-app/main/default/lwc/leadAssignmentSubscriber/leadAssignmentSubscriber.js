import { LightningElement,wire } from 'lwc';
import { subscribe, MessageContext } from 'lightning/empApi';
import USER_ID from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class LeadAssignmentSubscriber extends LightningElement {
     channelName = '/event/Lead_Assigned__e';
    subscription = {};
    
    @wire(MessageContext)
    messageContext;
 connectedCallback() {
        subscribe(this.channelName, -1, message => {
            const assignedTo = message.data.payload.UserId__c;
            if (assignedTo === USER_ID) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'New Lead!',
                        message: 'Lead is assigned to you.',
                        variant: 'info'
                    })
                );
            }
        });
    }

}