import { LightningElement, api } from 'lwc';
import loggerResources from '@salesforce/resourceUrl/cf_logger';
export default class LogRecordTile extends LightningElement {
    @api logrecord;
	appResources = {
		bearSilhouette: loggerResources +'/img/standing-bear-silhouette.png',
	};
    handleOpenRecordClick() {
        const selectEvent = new CustomEvent('logrecordview', {
            bubbles: true,
            detail: this.logrecord.Id
        });
        this.dispatchEvent(selectEvent);
    }
}