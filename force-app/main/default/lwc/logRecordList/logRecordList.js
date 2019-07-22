import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';
import { loadStyle } from 'lightning/platformResourceLoader';
import loggerResources from '@salesforce/resourceUrl/cf_logger';
import { LightningElement, track, wire } from 'lwc';
/** LogRecordController.searchLogRecs(searchTerm) Apex method */
import searchLogRecs from '@salesforce/apex/CF_LogRecordController.searchLogRecs';
export default class LogRecordListNav extends NavigationMixin(LightningElement) {
	@track searchTerm = '';
	@track logRecords;
	@wire(CurrentPageReference) pageRef;
	@wire(searchLogRecs, {searchTerm: '$searchTerm'})
	loadLogRecords(result) {
		this.logRecords = result;
		if (result.data) {
			fireEvent(this.pageRef, 'logRecordListUpdate', result.data);
		}
	}
	connectedCallback() {
		loadStyle(this, loggerResources + '/style.css');
	}
	handleSearchTermChange(event) {
		// Debouncing this method: do not update the reactive property as
		// long as this function is being called within a delay of 300 ms.
		// This is to avoid a very large number of Apex method calls.
		window.clearTimeout(this.delayTimeout);
		const searchTerm = event.target.value;
		// eslint-disable-next-line @lwc/lwc/no-async-operation
		this.delayTimeout = setTimeout(() => {
			this.searchTerm = searchTerm;
		}, 300);
	}
	get hasResults() {
		return (this.logRecords.data.length > 0);
	}
	handleLogRecordView(event) {
		// Get logRecord record id from logrecordview event
		const logRecordId = event.detail;
		// Navigate to logRecord record page
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: logRecordId,
				objectApiName: 'CF_LogRecord__c',
				actionName: 'view',
			},
		});
	}
}