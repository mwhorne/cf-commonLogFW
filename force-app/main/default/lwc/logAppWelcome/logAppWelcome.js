import { LightningElement, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import EMAIL_FIELD from '@salesforce/schema/User.Email';

const fields = [NAME_FIELD, EMAIL_FIELD];

export default class LogAppWelcome extends LightningElement {
    @track greeting = 'CF Logger user';
    handleGreetingChange(event) {
        this.greeting = event.target.value;
    }

    userId = Id;
    
    @wire(getRecord, { recordId: '$userId', fields })
    user;
    userName;

    get name() {
        this.userName = getFieldValue(this.user.data, NAME_FIELD);
        return `Hello ${this.userName.toUpperCase()}!`;
        /*return getFieldValue(this.user.data, NAME_FIELD);*/
    }

    currentDate = new Date().toDateString();
    get capitalizedGreeting() {
        return `Hello ${this.greeting.toUpperCase()}!`;
    }
}