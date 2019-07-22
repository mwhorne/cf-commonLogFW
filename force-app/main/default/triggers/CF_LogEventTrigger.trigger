trigger CF_LogEventTrigger on CF_LogEvent__e (after insert) 
{
    List<CF_LogRecord__c> logs = new List<CF_LogRecord__c>();

    for(CF_LogEvent__e event : Trigger.New)
    {
        CF_LogRecord__c log = new CF_LogRecord__c();

//        log.Name = event.Log_Name__c;
        log.Class_Name__c = event.Class_Name__c;
        log.Method_Name__c = event.Method_Name__c;
        log.Log_Time__c = event.Log_Time__c;
//        log.Error_Message__c = event.Error_Message__c;
//        log.Error_Line__c = event.Error_Line__c;       
        log.Stack_Trace__c = event.Stack_Trace__c;
//        log.Gov_Limits_in_Execution_Context__c = event.Gov_Limits_in_Execution_Context__c;

        log.Title__c = event.Title__c;
        log.Reason__c = event.Reason__c;
        log.Running_User__c = event.Running_User__c;

        log.DML__c = event.DML__c;
        log.SOQL__c = event.SOQL__c;	
        log.Data__c = event.Data__c;
        system.debug('** LogRecord object: ' + log);        
        logs.add(log);
    }
    Database.insert(logs);
}