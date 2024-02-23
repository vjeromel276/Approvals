import { createRecord, updateRecord } from 'lightning/uiRecordApi';
import { LightningElement, wire, api, track } from 'lwc';
import ASSET_OBJECT from '@salesforce/schema/Asset';
import ASSET_ACCT_ID from '@salesforce/schema/Asset.AccountId';
import ASSET_CONTACT_ID from '@salesforce/schema/Asset.ContactId';
import ASSET_NAME from '@salesforce/schema/Asset.Name';
import DIMENSION4 from '@salesforce/schema/Asset.Dimension_4_Market__c';
import REC_TYPE_ID from '@salesforce/schema/Asset.RecordTypeId';
import QUANTITY from '@salesforce/schema/Asset.Quantity';
import ORIGINAL_QUANTITY from '@salesforce/schema/Asset.SBQQ__BundledQuantity__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

export default class InventoryBulkAsset extends LightningElement {
    objectApiName = ASSET_OBJECT;
    @track _assetName;
    @track _acctId;
    @track _contactId;
    @track dimension4;
    @track _quantity;
    @track _originalQuantity;
    @track recTypeId = '0126g000000OuQ7AAK';
    @track dimension4Options;

    @wire( getPicklistValues, { recordTypeId: '0126g000000OuQ7AAK', fieldApiName: DIMENSION4 } )
    dim4listValues ( { error, data } ) {
        if ( data ) {
            console.table(  data.values );
            this.error = undefined;
            this.dimension4Options = data.values;
        } else if ( error ) {
            this.error = error;
            this.dimension4Options = undefined;
        }
    }

    get assetName () {
        return this._assetName;
    }

    set assetName ( value ) {
        this._assetName = value.trim();
    }

    get quantity () {
        return this._quantity;
    }

    get acctId () {
        return this._acctId;
    }

    set acctId ( value ) {
        this._acctId = value;
    }

    get contactId () {
        return this._contactId;
    }

    set contactId ( value ) {
        this._contactId = value;
    }

    set quantity ( value ) {
        this._quantity = value;
    }

    get originalQuantity () {
        return this._originalQuantity;
    }

    set originalQuantity ( value ) {
        this._originalQuantity = value;
    }

    // handleDim4Change ( event ) {
    //     console.log( event.target.name, event.target.value );
    //     this[event.target.name] = event.target.value;
    // }

    handleInput ( event ) {
        this[ event.target.name ] = event.target.value;
        // console.log( `this.${ event.target.name }`, this[ event.target.name ] );
    }

    async handleCreateBulkAsset () {
        const fields = {};
        fields[ ASSET_NAME.fieldApiName ] = this.assetName;
        fields[ DIMENSION4.fieldApiName ] = this.dimension4;
        fields[ REC_TYPE_ID.fieldApiName ] = this.recTypeId;
        fields[ QUANTITY.fieldApiName ] = this.quantity;
        fields[ ORIGINAL_QUANTITY.fieldApiName ] = this.originalQuantity;
        fields[ ASSET_ACCT_ID.fieldApiName ] = this.acctId;
        fields[ ASSET_CONTACT_ID.fieldApiName ] = this.contactId;

        const recordInput = { apiName: ASSET_OBJECT.objectApiName, fields };
        
        const result = await createRecord( recordInput );
        console.table( recordInput.fields)
        console.table(  result.fields );        
        try {
            if ( result ) {
                this.dispatchEvent(
                    new ShowToastEvent( {
                        title: 'Success',
                        message: `Asset ${ ASSET_NAME } created`,

                        variant: 'success'
                    } )
                );
            }
        } catch ( error ) {
            this.dispatchEvent(
                new ShowToastEvent( {
                    title: 'Error creating record',
                    message: error.body.message,
                    variant: 'error'
                } )
            );
        }
    }

}