public with sharing class CF_LogRecordController {
    @AuraEnabled(Cacheable=true)
    public static CF_LogRecord__c[] getAllLogRecs() {
        return [SELECT Id, Name, Title__c, Reason__c, Running_User__c
            FROM CF_LogRecord__c ORDER BY Name Desc LIMIT 16];
    }

    @AuraEnabled(Cacheable=true)
    public static CF_LogRecord__c[] searchLogRecs(String searchTerm) {
        // Return all log records when no search term
        searchTerm = searchTerm.trim();
        if (searchTerm == '') {
            return getAllLogRecs();
        }
        // Prepare query paramters
        searchTerm = '%'+ searchTerm +'%';
        // Execute search query
        return [SELECT Id, Name, Title__c, Reason__c, Running_User__c
            FROM CF_LogRecord__c WHERE Title__c LIKE :searchTerm ORDER BY Name DESC LIMIT 16];
    }    
}