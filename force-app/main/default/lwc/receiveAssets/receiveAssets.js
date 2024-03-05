/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable @lwc/lwc/no-leading-uppercase-api-name */
import { LightningElement, wire, api, track } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getPOStuff from "@salesforce/apex/InventoryGlobalController.POLinesRecId";
import createAssetRec from "@salesforce/apex/InventoryGlobalController.createAssetRec";
import systemSNCount from "@salesforce/apex/InventoryGlobalController.systemSNCount";
import AddToBulkAsset from "@salesforce/apex/InventoryGlobalController.AddToBulkAsset";
import { getBarcodeScanner } from "lightning/mobileCapabilities";
import FORM_FACTOR from "@salesforce/client/formFactor"; //screen size
import { CurrentPageReference } from "lightning/navigation";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import LightningConfirm from "lightning/confirm";

import PO_FIELD from "@salesforce/schema/Receiving__c.Purchase_Order__c";

export default class ReceiveAssets extends LightningElement {
	isFalse = false;
	/******************************************************
	 * --------------------| APIS |-------------------------
	 ******************************************************/
	@api recordId;
	/*--------------------------------------------------------*/

	/******************************************************
	 * -------------------| vars |------------------------
	 ******************************************************/
	isMobile = FORM_FACTOR == "Large" ? false : true;
	polines = [];

	ChosenPoLine = "";
	ChosenPoName = "";
	ChosenPoDesc = "";
	ChosenPoQuant = "";

	@track errors = [];
	@track showErrors = false;

	@track duplicateSerials = [];
	@track duplicateSerialsCount;

	inputVal = "";
	currentScannedTag = "";
	@track currentRecID = "";

	serialInputVal = "";

	myScanner;
	scanButtonDisabled = false;
	scannedBarcode = "";

	@track vendorValue = "";
	@track quantityVal = 1;

	@track minStockQty;

	@track generalModalLoader = true;

	//@track buttonURL;

	@track serialAssetScanOnly = false;
	@track showScanSerial = false;
	@track showScanAsset = true;

	@track ScanSerialAndEVTag = true;

	@track AssetsRecieved = [];

	@track showDescriptionBox = false;
	@track DescriptionBoxVal = "";

	purchaseOrderId = "";

	@track showScanBulkAsset = false;
	@track BulkAssetScanOnly = false;
	@track bulkInputVal = "";

	// @api DescriptionBoxVal;

	@track continueScanning = false;

	/******************************************************
	 * -------------------| wires |------------------------
	 ******************************************************/

	//wire loads before onload
	@wire( CurrentPageReference )
	getStateParameters ( currentPageReference ) {
		//console.log('--------------------------------- | wire CurrentPageReference')
		if ( currentPageReference ) {
			if ( currentPageReference.state.c__recordId ) {
				//is mobile/page
				//console.log('is a page')
				this.currentRecID = currentPageReference.state.c__recordId;
			} else {
				//is quick action
				//console.log('is a quick action')
				this.currentRecID = currentPageReference.state.recordId;
			}

			//is mobile/page
			if (
				currentPageReference.state.c__poid &&
				currentPageReference.state.c__recordId
			) {
				console.log( "poid set to" + currentPageReference.state.c__poid );
				this.purchaseOrderId = currentPageReference.state.c__poid;

				getPOStuff( { RecId: this.currentRecID } )
					.then( ( data ) => {
						this.polines = data;
						console.log( data );

						if ( data.length ) {
							this.showDescriptionBox = false;
						} else {
							this.showDescriptionBox = true;
						}
					} )
					.catch( ( error ) => {
						console.log( "there was an error" );
						console.log( error );
					} );
			}
		}
	}

	@wire( getRecord, { recordId: "$recordId", fields: [ PO_FIELD ] } )
	getPurchaseOrderRecord ( { data, error } ) {
		//console.log('--------------------------------- | wire getRecord')
		//console.log('accountRecord => ', data, error);
		if ( !this.isMobile ) {
			if ( data ) {
				this.purchaseOrder = data.fields.Purchase_Order__c.value;
				if ( data.fields.Purchase_Order__c.value != null ) {
					this.showDescriptionBox = false;
					//console.log('HAS PURCHASE ORDER')
					getPOStuff( { RecId: this.currentRecID } )
						.then( ( data ) => {
							this.polines = data;
						} )
						.catch( ( error ) => {
							console.log( "there was an error" );
							console.log( error );
						} );
				} else {
					//console.log('NO PURCHASE ORDER')
					this.showDescriptionBox = true;
				}
			} else if ( error ) {
				console.log( "error => ", error );
			}
		}
	}

	/******************************************************
	 * ------------| on load section |---------------------
	 ******************************************************/
	connectedCallback () {
		//console.log('--------------------------------- | on load: ')

		this.myScanner = getBarcodeScanner();
		if ( this.myScanner == null || !this.myScanner.isAvailable() ) {
			this.scanButtonDisabled = true;
		}

		this.generalModalLoader = false;

		setTimeout( () => {
			const textareaElement = this.template.querySelector( ".scanTagInputTest" );
			if ( textareaElement ) {
				textareaElement.focus();
			}
		}, 0 );
	}

	/**
	 * quantityChange()
	 *
	 * sets value on input change
	 */
	@api async quantityChange ( e ) {
		this.quantityVal = e.target.value;
	}

	/**
	 * descChange()
	 *
	 * sets value on input change
	 */
	@api async descChange ( e ) {
		this.DescriptionBoxVal = e.target.value;
	}

	/**
	 * hideModalLoader()
	 *
	 * helper function called by fron end when lightning-record-edit-form  completes loading
	 */
	hideModalLoader () {
		this.generalModalLoader = false;
	}

	/**
	 * selectPoLine()
	 *
	 * @param {*} e
	 */
	@api async selectPoLine ( e ) {
		var rID = e.currentTarget.dataset.recordId;
		var rName = e.currentTarget.dataset.recordName;
		var rDesc = e.currentTarget.dataset.recordDescription;
		var rQ = "1";
		this.ChosenPoLine = rID;
		this.ChosenPoName = rName;
		this.ChosenPoDesc = rDesc;
		this.ChosenPoQuant = rQ;

		// this.setFocusOnElement("lightning-input.scanTagInput");
	}

	/**
	 *
	 * @param {*} e
	 */
	inputValChange = ( e ) => {
		this.inputVal = e.target.value;
	};

	serialInputValChange = ( e ) => {
		this.serialInputVal = e.target.value;
	};

	BulkInputValChange = ( e ) => {
		this.bulkInputVal = e.target.value;
	};

	/**
	 *
	 */
	handleVendorChange = ( e ) => {
		this.vendorValue = e.target.value;
	};

	handleMINQuantityChage = ( e ) => {
		this.minStockQty = e.target.value;
	};

	serialAssetToggleChange = ( e ) => {
		this.serialAssetScanOnly = !this.serialAssetScanOnly;

		if ( this.serialAssetScanOnly == true ) {
			this.showScanAsset = false;
			this.showScanSerial = true;
			this.showScanBulkAsset = false;

			this.ScanSerialAndEVTag = false;
		} else {
			this.showScanAsset = true;
			this.showScanSerial = false;
			this.showScanBulkAsset = false;

			this.ScanSerialAndEVTag = true;
		}
	};

	BulkAssetToggleChange = ( e ) => {
		this.BulkAssetScanOnly = !this.BulkAssetScanOnly;

		if ( this.BulkAssetScanOnly == true ) {
			this.showScanAsset = false;
			this.showScanSerial = false;
			this.showScanBulkAsset = true;
		} else {
			this.showScanAsset = true;
			this.showScanSerial = false;
			this.showScanBulkAsset = false;
		}
	};

	handleResetTag () {
		console.log( this.continueScanning );

		this.currentScannedTag = "";
		this.inputVal = "";
		this.showScanSerial = false;
		this.serialAssetScanOnly = false;
		this.showScanAsset = true;

		if ( this.continueScanning == false ) {
			this.ChosenPoLine = "";
			this.ChosenPoName = "";
			this.ChosenPoDesc = "";
			this.ChosenPoQuant = "";
		} else {
			this.continueScanning = false;
		}

		this.currentScannedTag = "";
		this.BulkAssetScanOnly = false;
		this.showScanBulkAsset = false;
		this.bulkInputVal = "";
		console.log( "*****************************reset" );
		this.quantityVal = 1;

		this.ScanSerialAndEVTag = true;

		setTimeout( () => {
			const textareaElement = this.template.querySelector( ".scanTagInputTest" );
			if ( textareaElement ) {
				textareaElement.focus();
				console.log( "*****************************focus" );
			}
		}, 0 );
	}

	/**
	 *
	 * @param {*} event
	 */
	handleEnter ( event ) {
		if ( event.keyCode === 13 ) {
			this.currentScannedTag = event.target.value;
			this.inputVal = event.target.value;

			if ( event.target.value.length ) {
				let isAssetTag = event.target.value.toLowerCase().includes( "ev-" );
				console.log( "isAssetTag" + isAssetTag );

				if ( !isAssetTag ) {
					if (
						confirm(
							"You scanned an serial # in the asset field, Do you want to scan in a serial Number?"
						) == true
					) {
						this.showScanSerial = true;

						setTimeout( () => {
							const textareaElement = this.template.querySelector(
								".scanTagInputSerial"
							);
							if ( textareaElement ) {
								textareaElement.focus();
							}
						}, 0 );

						this.serialAssetScanOnly = true;
					}
				}

				if ( isAssetTag === true ) {
					if ( event.target.value.length ) {
						this.showScanSerial = true;

						setTimeout( () => {
							const textareaElement = this.template.querySelector(
								".scanTagInputSerial"
							);
							if ( textareaElement ) {
								textareaElement.focus();
							}
						}, 0 );
					} else {
						this.showScanSerial = false;
						this.serialAssetScanOnly = false;
						this.ScanSerialAndEVTag = true;
					}
				}
			}
		}
	}

	handleSerialEnter ( event ) {
		
		if ( event.charCode === 13 ) {
			console.log( "submit serial" );
			// if ( this.serialInputVal.length ) {
				this.submitScannedItem();
			// }
		}
	}

	showModal = false;
	openModal () {
		this.generalModalLoader = false;
		this.showModal = true;
	}

	closeModal () {
		this.showModal = false;
	}

	handleCancel () {
		// Handle Cancel button click
		console.log( "cancelled" );

		this.closeModal();
	}

	handleOK () {
		// Handle OK button click
		// Perform your desired actions here
		console.log( "confirmed" );
		this.sendRecieveAssets();
		this.closeModal();
	}

	/**
	 *
	 * @param {*} e
	 */
	submitScannedItem (  ) {
	
		console.log( " submit scanned item prolly a serial number" );
		//clear errors
		this.showErrors = false;
		this.errors = [];
		this.generalModalLoader = true;

		let isAssetTag = this.serialInputVal.toLowerCase().includes( "ev-" );

		if ( isAssetTag ) {
			console.log( "scanned ev- in a serial " );

			if (
				confirm(
					"You scanned an EV- # in the Serial Number field field, Do you want to scan in a EV Number?"
				) == true
			) {
				this.showScanSerial = false;
				this.serialAssetScanOnly = false;
				this.inputVal = "";
				this.serialInputVal = "";
				this.bulkInputVal = "";
				this.generalModalLoader = false;
				this.showScanAsset = true;

				setTimeout( () => {
					const textareaElement =
						this.template.querySelector( ".scanTagInputTest" );
					if ( textareaElement ) {
						textareaElement.focus();
					}
				}, 0 );
			}
		} else {
			if ( this.serialInputVal.length ) {
				//check for duplicate Serial Number sytem wide
				systemSNCount( { serialNo: this.serialInputVal } )
					.then( ( result ) => {
						console.log( JSON.stringify( result ) );
						if ( result ) {
							//this.duplicateSerialsCount = Number(result);
							//this.generalModalLoader = false;
							if ( Number( result ) > 1 ) {
								this.openModal();
							} else {
								console.log( "No duplicate Serial Number found recieve assets" );
								this.sendRecieveAssets();
							}

							// 0 will return and 0 is not a result so must have this BS
						} else {
							if ( Number( result ) == 0 ) {
								console.log( "No duplicate Serial Number found recieve assets" );
								this.sendRecieveAssets();
							}
						}
					} )
					.catch( ( error ) => {
						this.generalModalLoader = false;
						console.log( "there was an error" );
						console.log( error );
						this.dispatchEvent(
							new ShowToastEvent( {
								title: "An Error Occured",
								message: error.body.pageErrors[ 0 ].message,
								variant: "error"
							} )
						);
					} );
			} else {
				console.log( "no serial input" );
				this.sendRecieveAssets();
			}
		}
	}

	sendRecieveAssets () {
		console.log( "================quantity: " + this.quantityVal );
		createAssetRec( {
			RecId: this.currentRecID,
			AssetTagNum: this.inputVal,
			ChosenPoLineId: this.ChosenPoLine,
			vendor: this.vendorValue,
			quantity: this.quantityVal,
			minStockQuantity: this.minStockQty,
			serialNumber: this.serialInputVal,
			manualDesc: this.DescriptionBoxVal,
			skipError: false
		} )
			.then( ( result ) => {
				console.log( JSON.stringify( result ) );
				this.inputVal = "";
				this.serialInputVal = "";
				this.bulkInputVal = "";

				if ( result.name ) {
					let t = [];
					t.push( result );
					let updatedRecords = [ ...this.AssetsRecieved, ...t ];
					console.log( JSON.stringify( updatedRecords ) );

					this.AssetsRecieved = updatedRecords;

					this.generalModalLoader = false;

					this.dispatchEvent(
						new ShowToastEvent( {
							title: "Successful Created Asset",
							message: "Successful Created Asset",
							variant: "success"
						} )
					);

					if ( !this.serialAssetScanOnly ) {
						this.continueScanning = true;
						this.handleResetTag();
					}

					if ( this.ScanSerialAndEVTag ) {
						setTimeout( () => {
							const textareaElement =
								this.template.querySelector( ".scanTagInputTest" );
							if ( textareaElement ) {
								textareaElement.focus();
							}
						}, 0 );
					}
				}

				//single error from insert update
				if ( result.error ) {
					this.generalModalLoader = false;

					this.dispatchEvent(
						new ShowToastEvent( {
							title: "Error",
							message: "" + result.error + "",
							variant: "error"
						} )
					);
					this.handleResetTag();
				}

				//handle user errors
				if ( result.errors ) {
					this.generalModalLoader = false;

					this.showErrors = true;
					this.errors = result.errors;
				}
			} )
			.catch( ( error ) => {
				this.generalModalLoader = false;
				console.log( "there was an error" );
				console.log( error );
				this.dispatchEvent(
					new ShowToastEvent( {
						title: "An Error Occured",
						message: error.body.pageErrors[ 0 ].message,
						variant: "error"
					} )
				);
			} );
	}

	handleBulkEnter ( event ) {		
		if ( event.charCode === 13 ) {
			console.log( "submit bulk" );	
			// if ( this.bulkInputVal.length ) {
				this.submitScanToBulkItem();
			// }
		}
	}

	submitScanToBulkItem (  ) {
		
		console.log( " submit scanned item" );
		//clear errors
		this.showErrors = false;
		this.errors = [];
		this.generalModalLoader = true;

		AddToBulkAsset( {
			AssetTagNum: this.bulkInputVal,
			quantity: this.quantityVal,
			recId: this.recordId
		} )
			.then( ( result ) => {
				console.log( JSON.stringify( result ) );
				this.inputVal = "";
				this.serialInputVal = "";
				this.bulkInputVal = "";

				this.handleResetTag();

				if ( result.name ) {
					let t = [];
					t.push( result );
					let updatedRecords = [ ...this.AssetsRecieved, ...t ];
					console.log( JSON.stringify( updatedRecords ) );

					this.AssetsRecieved = updatedRecords;

					this.generalModalLoader = false;

					this.dispatchEvent(
						new ShowToastEvent( {
							title: "Successful Created Asset",
							message: "Successful Created Asset",
							variant: "success"
						} )
					);
				}

				//single error from insert update
				if ( result.error ) {
					this.generalModalLoader = false;

					this.dispatchEvent(
						new ShowToastEvent( {
							title: "Error",
							message: "" + result.error + "",
							variant: "error"
						} )
					);
					this.handleResetTag();
				}

				//handle user errors
				if ( result.errors ) {
					this.generalModalLoader = false;

					this.showErrors = true;
					this.errors = result.errors;
				}
			} )
			.catch( ( error ) => {
				this.generalModalLoader = false;
				console.log( "there was an error" );
				console.log( error );
				this.dispatchEvent(
					new ShowToastEvent( {
						title: "An Error Occured",
						message: error.body.pageErrors[ 0 ].message,
						variant: "error"
					} )
				);
			} );
	}

	handleBeginScanClick ( event ) {
		// Reset scannedBarcode to empty string before starting new scan
		this.scannedBarcode = "";

		// Make sure BarcodeScanner is available before trying to use it
		// Note: We _also_ disable the Scan button if there's no BarcodeScanner
		if ( this.myScanner != null && this.myScanner.isAvailable() ) {
			const scanningOptions = {
				barcodeTypes: [
					this.myScanner.barcodeTypes.QR,
					this.myScanner.barcodeTypes.PDF_417
				],
				instructionText: "Scan a QR Code",
				successText: "Scanning complete."
			};
			this.myScanner
				.beginCapture( scanningOptions )
				.then( ( result ) => {
					console.log( result );

					if ( result.value.length ) {
						this.currentScannedTag = result.value;
						this.inputVal = result.value;
						//this.submitScannedItem();

						this.scannedBarcode = result.value;

						let isAssetTag = result.value.toLowerCase().includes( "ev-" );
						console.log( "isAssetTag" + isAssetTag );

						if ( !isAssetTag ) {
							if (
								confirm(
									"You scanned an serial # in the asset field, Do you want to scan in a serial Number?"
								) == true
							) {
								this.showScanSerial = true;
								this.serialAssetScanOnly = true;

								setTimeout( () => {
									const textareaElement = this.template.querySelector(
										".scanTagInputSerial"
									);
									if ( textareaElement ) {
										textareaElement.focus();
									}
								}, 0 );
							}
						}

						if ( isAssetTag == true ) {
							if ( result.value.length ) {
								this.showScanSerial = true;

								setTimeout( () => {
									const textareaElement =
										this.template.querySelector( ".scanTagInputTest" );
									if ( textareaElement ) {
										textareaElement.focus();
									}
								}, 0 );
							} else {
								this.showScanSerial = false;
								this.serialAssetScanOnly = false;
								this.ScanSerialAndEVTag = true;
							}
						}
					}

					this.dispatchEvent(
						new ShowToastEvent( {
							title: "Successful Scan",
							message: "Barcode scanned successfully.",
							variant: "success"
						} )
					);
				} )
				.catch( ( error ) => {
					// Handle cancellation and unexpected errors here
					console.error( error );

					if ( error.code == "userDismissedScanner" ) {
						// User clicked Cancel
						this.dispatchEvent(
							new ShowToastEvent( {
								title: "Scanning Cancelled",
								message: "You cancelled the scanning session.",
								mode: "sticky"
							} )
						);
					} else {
						// Inform the user we ran into something unexpected
						this.dispatchEvent(
							new ShowToastEvent( {
								title: "Barcode Scanner Error",
								message:
									"There was a problem scanning the barcode: " + error.message,
								variant: "error",
								mode: "sticky"
							} )
						);
					}
				} )
				.finally( () => {
					console.log( "#finally" );

					// Clean up by ending capture,
					// whether we completed successfully or had an error
					this.myScanner.endCapture();
				} );
		} else {
			// BarcodeScanner is not available
			// Not running on hardware with a camera, or some other context issue
			console.log( "Scan Barcode button should be disabled and unclickable." );
			console.log( "Somehow it got clicked: " );
			console.log( event );

			// Let user know they need to use a mobile phone with a camera
			this.dispatchEvent(
				new ShowToastEvent( {
					title: "Barcode Scanner Is Not Available",
					message: "Try again from the Salesforce app on a mobile device.",
					variant: "error"
				} )
			);
		}
	}
}