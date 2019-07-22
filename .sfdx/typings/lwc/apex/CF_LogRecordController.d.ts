declare module "@salesforce/apex/CF_LogRecordController.getAllLogRecs" {
  export default function getAllLogRecs(): Promise<any>;
}
declare module "@salesforce/apex/CF_LogRecordController.searchLogRecs" {
  export default function searchLogRecs(param: {searchTerm: any}): Promise<any>;
}
