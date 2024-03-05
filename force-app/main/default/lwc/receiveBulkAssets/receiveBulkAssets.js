import { LightningElement } from 'lwc';
import {createRecord} from 'lightning/uiRecordApi';

export default class ReceiveBulkAssets extends LightningElement {
    inputQuantity = 0;
    description = ''
    tagNumber = '';

    set quantity(e) {
        this.inputQuantity = e.target.value;
    }
    get quantity() {
        return this.inputQuantity;
    }

    set description(e) {
        this.description = e.target.value;
    }

    get description() {
        return this.description;
    }

    set tagNumber(e) {
        this.tagNumber = e.target.value;
    }

    get tagNumber() {
        return this.tagNumber;
    }

    updateQuantity(e) {
        e.preventDefault();
        console.log('quantity ' + e.target.value);
        this.quantity = e.target.value;
        console.log('quantity ' + this.quantity);
    }

    updateDescription(e) { 
        e.preventDefault();
        console.log('description ' + e.target.value);
        this.description = e.target.value;
        console.log('description ' + this.description);
    }

    updateTagNumber(e) {
        e.preventDefault();
        console.log('tagNumber ' + e.target.value);
        this.tagNumber = e.target.value;
        console.log('tagNumber ' + this.tagNumber);
    }

    submitForm(e) {
        e.preventDefault();
        console.log('submitting form');
        console.log('quantity ' + this.quantity);
        console.log('description ' + this.description);
        console.log('tagNumber ' + this.tagNumber);
        const fields = {'Name' : this.tagNumber, 'Quantity__c' : this.quantity, 'Description__c' : this.description};
        const recordInput = {apiName : 'Asset', fields};
        createRecord(recordInput).then(response => {
            console.log('response ' + response);
        }).catch(error => {
            console.log('error ' + error);
        });
    }

 

}