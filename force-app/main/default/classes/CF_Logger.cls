public class CF_Logger
{
    private static LogScope current;
    private static LogScope root;    
    private static final Integer DML_IDX = 0;
    private static final Integer SOQL_IDX = 1;    
    private static final Map<Integer, String> LIMITS_BY_IDX = 
        new Map<Integer, String> { DML_IDX => 'DML', SOQL_IDX => 'SQL'};
    
    static 
    {
        reset();
    }

    Public static void error(Exception ex)
    {
        // Create log event and then populate using incoming object
        CF_LogEvent__e event = new CF_LogEvent__e();

        event.Running_User__c = UserInfo.getName();
        //event.Title__c = ex.getMessage();
        event.Reason__c = ex.getTypeName();
        //event.Error_Line__c = ex.getLineNumber();

        String stackTrace = ex.getStackTraceString();

        event.Stack_Trace__c = stackTrace;
        event.Class_Name__c = getClassName(stackTrace);
        event.Method_Name__c = getMethodName(stackTrace);
        event.Title__c = event.Class_Name__c + '.' + event.Method_Name__c;   
        ///*
        // creating data__c stuff
        LogScope newScope = new LogScope();
        newScope.scope = event.Title__c;
        newScope.limits = new List<Integer> { 
            Limits.getDMLStatements(), 
			Limits.getQueries() };
		newScope.parent = CF_Logger.current;
        CF_Logger.current.logEntries.add(newScope);
		CF_Logger.current = newScope;
        CF_Logger.current.logEntries.add('Running User....'+event.Running_User__c); 
        CF_Logger.current.logEntries.add('Exception Type..'+event.Reason__c); 
        CF_Logger.current.logEntries.add('Exception Line..'+ex.getLineNumber()); 
        CF_Logger.current.logEntries.add('Exception Msg...'+ex.getMessage()); 
        event.Data__c = flush();

        //*/ 
        // Publish event to the bus
        EventBus.publish(event);
    }
    /**
     * Determine required name from first stacktrace line: 'Class.Classname.methodname:....'
     **/    
    private static String getClassName(String line)
    {
        if (line.startsWith('Class.')) 
        { 
            line = line.substringAfter('Class.');
        }
        return line.substringBefore(':').substringBeforeLast('.');
    }    
    /**
     * Determine required name from first stacktrace line: 'Class.Classname.methodname:....'
     **/    
    private static String getMethodName(String line)
    {
        return line.substringBefore(':').substringAfterLast('.');
    }
    /**
     * Push this un-named scope onto the log stack after setting scope to Classname.methodname
     **/    
    public static void push() 
    {
        String scope = 'MyClass.methodAA';
        push(scope); 
        // ToDo: How do I call push(scope) instead of repeating code 
        /*      
		LogScope newScope = new LogScope();
        newScope.scope = scope;
        newScope.limits = new List<Integer> { 
            Limits.getDMLStatements(), 
			Limits.getQueries() };
		newScope.parent = CF_Logger.current;
        CF_Logger.current.logEntries.add(newScope);
		CF_Logger.current = newScope; 
        */
    }
    /**
     * Push this named scope onto the log stack
     **/    
    public static void push(String scope) 
    {
		LogScope newScope = new LogScope();
        newScope.scope = scope;
        newScope.limits = new List<Integer> { 
            Limits.getDMLStatements(), 
			Limits.getQueries() };
		newScope.parent = CF_Logger.current;
        CF_Logger.current.logEntries.add(newScope);
		CF_Logger.current = newScope;
		system.debug('**CF_Logger.current(after push): '+CF_Logger.current);        
		system.debug('**newScope.limits(after push): '+newScope.limits);        
    }
    
    /**
     * Add the given message to the scope last pushed
     **/
    public static void debug(String message) 
    {
		CF_Logger.current.logEntries.add(message);        
    }
    
    /**
     * Pop the current scope
     **/
    public static void pop() 
    {
        CF_Logger.current.limits = new List<Integer> { 
            Limits.getDMLStatements() - CF_Logger.current.limits[DML_IDX], 
			Limits.getQueries() - CF_Logger.current.limits[SOQL_IDX]};
     	CF_Logger.current = CF_Logger.current.parent;           
		system.debug('**CF_Logger.current(after pop): '+CF_Logger.current);        
		system.debug('**CF_Logger.current.limits(after push): '+CF_Logger.current.limits);        
    }

	/**
	 * Flush the log entries and serialize 
	 **/    
    public static String flush() 
    {
        List<String> logLines = new List<String>();
        logLines.add(CF_Logger.root.scope);
        CF_Logger.root.flush(logLines, 1);
        reset();
		return String.join(logLines, '/n');        
    }
    
    /**
     * Emits the current log state to the LogEvent__e platform event
     **/
    public static void emit() 
    {
        // Log title is primarly present to allow filtering
        String title = CF_Logger.root.scope;
        DateTime dt = DateTime.newInstance(1776, 07, 04, 12, 0, 0);
        Integer dml = -1;
        Integer soql = -1;
        if(CF_Logger.root.logEntries.size() > 0) 
        {
	        Object top = CF_Logger.root.logEntries[0];
            if(top instanceof LogScope) 
            {
				LogScope logScope = (LogScope) top;
                title = logScope.scope;
				dt = logScope.scopeDt;                
                dml = logScope.limits[DML_IDX];
                soql = logScope.limits[SOQL_IDX];
            } 
            else if (top instanceof String) 
            {
				title = (String) top;                
            }
        }
        
        // Create log event and then populate 
        CF_LogEvent__e event = new CF_LogEvent__e();

        event.Title__c = title;
        event.Log_Time__c = dt;
        event.Reason__c = 'Debug Statements';  // ToDo: make this a constant
        event.Running_User__c = UserInfo.getName();
        event.DML__c = dml;
        event.SOQL__c = soql;
        event.Data__c = flush();

        // Emit the log data via Platform Events (Publish event to bus)
        EventBus.publish(event);
      }    
    
    /**
     * Resets the log state
     **/
    private static void reset() {
        root = current = new LogScope();

        DateTime now = DateTime.now();	// Date and time snapshot in GMT
        // Set scope string using local time format
        // TODO: Allow format and region to be mdt setting 
		current.scope = now.format('yyyy-MM-dd hh:mm:ss', 'America/New_York')+'.'+now.millisecond();
        current.scopeDt = now;
        system.debug('** scope: '+current.scope+'  scope Dt: '+current.scopeDt);
    }
    
    /**
     * Nested log scopes
     **/
    private class LogScope 
    {
        public LogScope parent;
        public String scope;
        public DateTime scopeDt;
        public List<Integer> limits;
        public List<Object> logEntries = new List<Object>();
        
        public void flush(List<String> logLines, Integer indent) 
        {
            for(Object logEntry : logEntries) 
            {
                if(logEntry instanceof LogScope) 
                {
					LogScope logScope = (LogScope) logEntry;
                    List<String> limitDiffs = new List<String>();
                    for(Integer limitIdx : LIMITS_BY_IDX.keySet()) 
                    {
                        Integer limitVariance = logScope.limits[limitIdx];
                        if(limitVariance > 0) 
                        {
							limitDiffs.add(LIMITS_BY_IDX.get(limitIdx)+' ' + limitVariance);
                        }
                    }
                    String limits = limitDiffs.size() > 0 ? '(' + String.join(limitDiffs, ',') + ')' : '';
                    
                    system.debug('** indent: '+indent+' limits: '+limits);
                    system.debug('** logScope.scope: '+logScope.scope);
                    
                    logLines.add(indent+':'+logScope.scope+' '+limits);
					logScope.flush(logLines, indent+1);
                } 
                else 
                {
					logLines.add(indent+':'+logEntry);                    
                }
            }
        }
    }    
}