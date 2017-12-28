public class ScanApexClassCtrl {

    public String DisplayResult { get; set;}
    public Map<string,Map<string,set<string>>> methodSObjectsMap {get;set;}
    public Map<string,Map<string,set<string>>> methodNameSObjectDisplay {get;set;}  
    public list<string> methodNames {get;set;}    
    public static final String endPoint = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v36.0/tooling/sobjects';    
    public Id asyncRequestId { get; set;}
    public String apexClassName { get; set;}
    public Map<string,Map<string,set<string>>> methodNameSObjectFinal;
    public Map<String, MethodProperties> mapMethodNameProperties;
    public Static Map<string,Map<string,List<string>>> mapExternalClassMethodNamesFinal = new Map<string,Map<string,List<string>>>();
    public Map<string,string> mapMethodNameBody;

    Public scanApexClassCtrl() {
        //asyncRequestId = ApexPages.CurrentPage().getParameters().get('asyncRequestId');
        //apexClassName = ApexPages.CurrentPage().getParameters().get('apexClassName');
        methodNameSObjectFinal = new Map<string,Map<string,set<string>>>();
    }  

    Public scanApexClassCtrl(Id asyncRequestId,string apexClassName) {
        this.asyncRequestId = asyncRequestId;
        this.apexClassName = apexClassName;
        this.methodNameSObjectFinal = new Map<string,Map<string,set<string>>>();
        scanApexClassContent1();
        system.debug('Anydatatype_msg');
    }      
    

    public string createTestClass(){
        string url = '';
        try {
            system.debug('Checking-->>'+methodNameSObjectFinal);
            createTestClass.testClassResWrapper result = createTestClass.testClassCreation(apexClassName,methodNameSObjectFinal);            
            //CreateTestClass.TestClassResWrapper result = CreateTestClass.testClassCreation1(apexClassName,mapMethodNameProperties);
            if(result.isSuccess) {
                url = '/'+result.testClassId;   
                return url;             
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,result.message));
            }
        } catch(exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,ex.getMessage()));
        }     
        return null;  
    }

    // Invoked from Button
    public pageReference createTestClassBtn(){
        pageReference pgRef;
        string url = createTestClass();
        if(url != null){
            pgRef = new pageReference(url);
        }
        return pgRef;
    } 
    
    public void scanApexClassContent() {
        Map<String, List<string>> retrieveMethodNameMap = new Map<String, List<string>>();        
        methodNameSObjectDisplay = new Map<string,Map<string,set<string>>>();
        Map<string,Map<string,set<string>>> methodNameSObject = new Map<string,Map<string,set<string>>>();
        List<ApexClass> apexClassList = new List<ApexClass>();
        methodNames = new List<string>();
        string queryApex = '';
        string expectedTestClass = '';
        List<string> targetContentList = new List<string>{'methods'};              
                
        if(apexClassName != null && apexClassName != ''){
            expectedTestClass = apexClassName;
            queryApex = queryApex + 'select Id, ApiVersion, Name, NamespacePrefix, Body from ApexClass where name LIKE: expectedTestClass';
            apexClassList = Database.query(queryApex);
        }
        if(!apexClassList.isEmpty() && asyncRequestId != null){
            DisplayResult = apexClassList[0].Body;              
            retrieveMethodNameMap = getClassDetails(asyncRequestId,targetContentList);                
            methodNames = retrieveMethodNameMap.get('methods');
            system.debug('retrieveMethodNameMap ' + retrieveMethodNameMap);
            system.debug('methodNames--->>'+methodNames);
            Map<string,string> methodNameBodyMap = new Map<string,string>();
            for(string methodNamRef : methodNames){                
               Map<string,string> tempMethodNameBodyMap = fetchApexClassSymbolTable.fetchMethodContent(apexClassList[0].Body,methodNamRef);                  
               methodNameBodyMap.putAll(tempMethodNameBodyMap);
            }
            mapMethodNameBody = methodNameBodyMap;
            for(string methodNamRef : methodNameBodyMap.KeySet()){
                Map<string,Map<string,set<string>>> methodNameSObjectTemp = ParseApexClassSObject(methodNamRef,methodNameBodyMap.get(methodNamRef));
                system.debug('methodNameSObjectTemp--->>'+methodNameSObjectTemp);      
                methodNameSObject.putAll(methodNameSObjectTemp);
            }
            methodNameSObjectFinal.putALL(methodNameSObject);
            methodNameSObjectDisplay.putALL(methodNameSObject);
            
            system.debug('methodNameSObjectDisplay--->>'+methodNameSObjectDisplay);
        }
    
    }
    
    public void scanApexClassContent1() {
        List<ApexClass> listApexClass = [Select Id, ApiVersion, Name, NamespacePrefix, Body from ApexClass Where Name =: apexClassName];
        if (listApexClass.isEmpty() || asyncRequestId == null) {
            return;
        }
        getMethodDetails(getSymbolTable(asyncRequestId), listApexClass[0].Body);
    }
    
    public ToolingApi.SymbolTable getSymbolTable(Id asyncRequestId) {
        if (asyncRequestId == null) {
            return null;
        }
        ToolingApi toolingAPI = new ToolingApi();
        String query1 = 'Select  SymbolTable From ApexClassMember where MetadataContainerId='+'\''+asyncRequestId+'\' order by createdDate Desc limit 1';  
        List<ToolingAPI.ApexClassMember> apexClasseMems = (List<ToolingAPI.ApexClassMember>)toolingAPI.query(query1).records;
        System.debug('@Id@@'+apexClasseMems[0].symbolTable);  
        return apexClasseMems[0].symbolTable;
    }
    
    public void getMethodDetails(ToolingApi.SymbolTable st, String classBody) {
        mapMethodNameProperties = new Map<String, MethodProperties>();
        for(ToolingApi.Method method : st.methods) {
            MethodProperties mp = new MethodProperties();
            mp.name = method.Name;
            mp.method = method;
            String ptrn = '(?:.*' + method.Name + '\\s*(\\([^\\)]*\\))\\s*\\{)';
            Pattern p = Pattern.compile(ptrn);
            Matcher m = p.matcher(classBody);
            String params = '';
            while(m.find()) {
                params = m.group(1);
            }
            params = params.replaceAll('\\s*[,\\(\\)]\\s*', ',');
            System.debug('method all param details: ' + mp.name + ';' + params);
            String lastParamName = '';
            for (ToolingAPI.Parameter pr : method.parameters) {
                if (pr.type == 'Map' || pr.type == 'List' || pr.type == 'Set') {
                    ptrn = '(?i)(?:' + lastParamName + ',(' + pr.type + '.*)' + pr.name + ',)';
                    p = Pattern.compile(ptrn);
                    m = p.matcher(params);
                    while(m.find()) {
                        pr.type = m.group(1);
                        pr.type = pr.type.replaceAll('\\s*<\\s*','<').replaceAll('\\s*>\\s*','>');
                        System.debug('param details: ' + pr);
                    }
                }
                lastParamName = pr.name;
            }
            Map<String, String> tempMethodNameBodyMap = fetchApexClassSymbolTable.fetchMethodContent(classBody, mp.name);
            Map<String, Map<String, Set<String>>> methodNameSObjectTemp = parseApexClassSObject(mp.name, tempMethodNameBodyMap.get(mp.name));
            mp.mapObjFields = methodNameSObjectTemp.get(mp.name);
            mapMethodNameProperties.put(mp.name, mp);
        }
    }
    
    public static Map<string,Map<string,List<string>>> getExternalClassDetails(string className, Id apexClassMemberId , string externalRefType){ 
        Map<string,List<string>> mapExternalClassMethodNames = new Map<string,List<string>>();  
        //Map<string,Map<string,List<string>>> mapExternalClassMethodNamesFinal = new Map<string,Map<string,List<string>>>();
        
        ToolingApi toolingAPI = new ToolingApi();
        if(apexClassMemberId != null){
            String query1 = 'Select SymbolTable From ApexClassMember where Id='+'\''+apexClassMemberId+'\' order by createdDate Desc limit 1';
            System.debug('query1-->>'+query1);          
            List<ToolingAPI.ApexClassMember> apexClasseMems = (List<ToolingAPI.ApexClassMember>)toolingAPI.query(query1).records;
            System.debug('apexClasseMems--->>'+apexClasseMems);
            ToolingApi.SymbolTable symbolTable = apexClasseMems[0].symbolTable;
            System.debug('@Id@@'+apexClasseMems[0].symbolTable);    
                 
            if('externalReferences'.equalsIgnoreCase(externalRefType)){
                 for(ToolingApi.ExternalReference refernce: symbolTable.externalReferences){                    
                    for(ToolingApi.ExternalMethod em: refernce.methods){                    
                        if(!mapExternalClassMethodNames.isEmpty() && mapExternalClassMethodNames.containsKey(refernce.name)){
                            mapExternalClassMethodNames.get(refernce.name).add(em.Name);
                        }else{
                            List<String> listExternalMethodNames = new List<String>();
                            listExternalMethodNames.add(em.Name);
                            mapExternalClassMethodNames.put(refernce.name, listExternalMethodNames);
                        }
                    }                          
                }           
            }   
        }
        if(className != null && mapExternalClassMethodNames != null && !mapExternalClassMethodNames.isempty()){
            mapExternalClassMethodNamesFinal.put(className,mapExternalClassMethodNames);
        }       
        return mapExternalClassMethodNamesFinal;
    }
    
    public static Map<String, List<String>> getClassDetails(Id asyncRequestId , List<String> types){        
        Map<String,List<String>> mapOfTypes = new Map<String,List<String>>();     
        ToolingApi toolingAPI = new ToolingApi();
        if(asyncRequestId != null){
            String query1 = 'Select  SymbolTable From ApexClassMember where MetadataContainerId='+'\''+asyncRequestId+'\' order by createdDate Desc limit 1';  
            List<ToolingAPI.ApexClassMember> apexClasseMems = (List<ToolingAPI.ApexClassMember>)toolingAPI.query(query1).records;
            ToolingApi.SymbolTable symbolTable = apexClasseMems[0].symbolTable;
            System.debug('@Id@@'+apexClasseMems[0].symbolTable);  
            
            for(String type: types){            
                if('methods'.equalsIgnoreCase(type)){
                     List<String> listOfMethods = new List<String>();
                     for(ToolingApi.Method method : symbolTable.methods){
                         listOfMethods.add(method.Name);            
                     }
                     mapOfTypes.put(type, listOfMethods);            
                }   
                if('constructors'.equalsIgnoreCase(type)){
                     List<String> listOfConstructors= new List<String>();
                     for(ToolingApi.Symbol symbol: symbolTable.constructors){
                         listOfConstructors.add(symbol.Name);            
                     }
                     mapOfTypes.put(type, listOfConstructors);            
                }
                if('externalReferences'.equalsIgnoreCase(type)){
                     List<String> listOfReferences = new List<String>();
                     for(ToolingApi.ExternalReference refernce: symbolTable.externalReferences){                        
                        listOfReferences.add(refernce.name);
                        /* for(ExternalMethod em: refernce.methods){
                            listOfReferences.add(em.Name); 
                         }
                        */         
                     }
                     mapOfTypes.put(type, listOfReferences);            
                } 
                if('innerClasses'.equalsIgnoreCase(type)){
                     List<String> listOfInnerClasses= new List<String>();
                     for(ToolingApi.SymbolTable symbol: symbolTable.innerClasses){
                         listOfInnerClasses.add(symbol.name);            
                     }
                     mapOfTypes.put(type, listOfInnerClasses);            
                } 
                 if('interfaces'.equalsIgnoreCase(type)){
                     List<String> listOfInterfaces = new List<String>();
                     for(String intf: symbolTable.interfaces){
                         listOfInterfaces.add(intf);            
                     }
                     mapOfTypes.put(type, listOfInterfaces);            
                }
                if('parentClass'.equalsIgnoreCase(type)){
                 /*  List<String> listOfParentClasses = new List<String>();
                     for(String pClass: symbolTable.parentClass){
                         listOfParentClasses.add(symbolTable.parentClass);            
                     }
                    mapOfTypes.put(type, listOfParentClasses);     
                    */       
                }                
            }
            System.debug('Symbol Table-->>'+mapOfTypes);
        }        
        return mapOfTypes;       
    }

    private Map<string,Map<string,set<string>>> ParseApexClassSObject(string methodName, string methodBody){
        Map<string,set<string>> sObjectsResult = new Map<string,set<string>>();
        Map<string,Map<string,set<string>>> methodSObjectsMap = new Map<string,Map<string,set<string>>>();
        //string methodBody = '/*Account acc1 = new Account();*/ /account acc2 = new account();//opp = new List<Opportunity>();';
        string ApexClassRemoveComments, ApexClassRemoveLineComments, ApexClassWithoutLineComments; 
        Pattern identifyComments = Pattern.compile('(\\/\\*)');     
        Pattern identifyLineComments = Pattern.compile('(\\/\\/)');
        Pattern findSObject = Pattern.compile('(new)');
        Pattern getSOQLFields = Pattern.compile('(?i)(SELECT\\s+?[^\\s]+?\\s+?.*FROM\\s+?[^\\s]+?(\\s|\'|]))');
        // Need to Replace REGX for Where Condition
        Pattern getSOQLWhereCondition = Pattern.compile('(?i)(\\s+From\\s+?[^\\s]+\\s+WHERE\\s+.*(\\s|\'|]|;))');

        ApexClassRemoveComments = methodBody;    
        matcher findComments = identifyComments.matcher(methodBody);
        while (findComments.find()) {
            string commentedCode,findCommentedCode;
            system.debug('BEFORE-->'+ApexClassRemoveComments);
            commentedCode = methodBody.substring(findComments.start());
            findCommentedCode = methodBody.substring(findComments.start(),findComments.start()+commentedCode.indexOf('*/')+2);
            ApexClassRemoveComments = ApexClassRemoveComments.remove(findCommentedCode);
            system.debug('AFTER-->'+ApexClassRemoveComments);   
        }   

        ApexClassRemoveLineComments = ApexClassRemoveComments;  
        matcher findLineComments = identifyLineComments.matcher(methodBody);
        while (findLineComments.find()) {
            string commentedLine,findCommentedLine;
            system.debug('BEFORE-->'+ApexClassRemoveLineComments);
            commentedLine = methodBody.substring(findLineComments.start());
            findCommentedLine = methodBody.substring(findLineComments.start(),findLineComments.start()+commentedLine.indexOf(';')+1);
            ApexClassRemoveLineComments = ApexClassRemoveLineComments.remove(findCommentedLine);
            system.debug('AFTER-->'+ApexClassRemoveLineComments);
        }
        
        ApexClassWithoutLineComments = ApexClassRemoveLineComments;     
        Matcher sObjectFind = findSObject.matcher(ApexClassWithoutLineComments);
        
        while (sObjectFind.find()) { 
            system.debug('**********************');
            set<string> tempSObjectvariables = new set<string>();
            set<string> ObjectFields = new set<string>();
            string newSObjectRef,sObjectRefFormat,sObjectVariableFormat, sObjectRef, sObjectVariableRef;     
            newSObjectRef = ApexClassWithoutLineComments.substring(sObjectFind.start());
            sObjectRefFormat = ApexClassWithoutLineComments.substring(sObjectFind.start()+4,(sObjectFind.start()+newSObjectRef.indexOf('(')));
            sObjectRef = sObjectRefFormat.trim();
                        
            sObjectVariableFormat = ApexClassWithoutLineComments.substring(ApexClassWithoutLineComments.lastIndexOf(';',sObjectFind.start())+1,sObjectFind.start()-2).trim();
            if(sObjectVariableFormat.lastIndexOf('{') != -1){
                sObjectVariableFormat = sObjectVariableFormat.substring(sObjectVariableFormat.lastIndexOf('{')+1).trim();
            }else if(sObjectVariableFormat.lastIndexOf('}') != -1){
                sObjectVariableFormat = sObjectVariableFormat.substring(sObjectVariableFormat.lastIndexOf('}')+1).trim();
            }
            sObjectVariableRef = sObjectVariableFormat.removeStart(sObjectRefFormat);
            
            ObjectFields = findSObjectFields(sObjectVariableRef,ApexClassWithoutLineComments);

            // To match the case sensitive in Map key (Sobject Name)
            //String[] types = new String[]{sObjectRef};
            
            //Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
            //sObjectRef = results[0].getName(); 
            
            List<Schema.SObjectType> globalDescribeObj = Schema.getGlobalDescribe().Values();     
            set<string> sObjectNames = new set<string>();
            
            for(Schema.SObjectType sObjType : globalDescribeObj){
               sObjectNames.add(sObjType.getDescribe().getName());
            }
            system.debug('sObjectRef-->>'+sObjectRef);
            system.debug('sObjectNames--->>'+sObjectNames); 
            
            if(sObjectNames!= null && !sObjectNames.isEmpty() && sObjectNames.contains(sObjectRef)){
                if(!sObjectsResult.isEmpty() && sObjectsResult.containsKey(sObjectRef)){
                    tempSObjectvariables = sObjectsResult.get(sObjectRef);
                    tempSObjectvariables.addALL(ObjectFields);               
                }else{              
                    tempSObjectvariables.addAll(ObjectFields);
                    //sObjectRef = sObjectRef.toLowerCase();
                    sObjectsResult.put(sObjectRef,tempSObjectvariables);
                }
            }            
            /*
            if(!sObjectsResult.isEmpty() && sObjectsResult.containsKey(sObjectRef)){
                tempSObjectvariables = sObjectsResult.get(sObjectRef);
                tempSObjectvariables.add(sObjectVariableRef);               
            }else{              
                tempSObjectvariables.add(sObjectVariableRef);
                sObjectsResult.put(sObjectRef,tempSObjectvariables);
            }
            */      
            
            //sObjectsResult.add(sObjectRefFormat);
        }

        ApexClassRemoveLineComments = ApexClassRemoveComments;  
        matcher getSOQLquery = getSOQLFields.matcher(ApexClassRemoveComments);
        system.debug('0000ApexClassWithoutLineComments####-->'+ApexClassWithoutLineComments);
        system.debug('00000ApexClassRemoveComments#####-->'+ApexClassRemoveComments);
        while (getSOQLquery.find()) {        
            Pattern nestedQryPtrn = Pattern.compile('(?i)\\((SELECT\\s+?[^\\s]+?\\s+?.*FROM\\s+?[^\\s]+?(\\)))');
            matcher nestQryMtchr = nestedQryPtrn.matcher(getSOQLquery.group(1));
            map<string,set<string>> objFieldmap;
            while(nestQryMtchr.find()){
                objFieldmap = getSOQLSObjectFields(nestQryMtchr.group(1),true,getSOQLquery.group(1));
                list<string> keys = new list<string>();
                keys.addAll(objFieldmap.keyset());
                if(sObjectsResult.containsKey(keys[keys.size()-1])){
                    sObjectsResult.get(keys[keys.size()-1]).addall(objFieldmap.get(keys[keys.size()-1]));
                }else{
                    sObjectsResult.putAll(objFieldmap);
                }
            }
            objFieldmap = getSOQLSObjectFields(getSOQLquery.group(1),false,'');
            list<string> keys = new list<string>();
            keys.addAll(objFieldmap.keyset());            
            if(sObjectsResult.containsKey(keys[keys.size()-1])){
                sObjectsResult.get(keys[keys.size()-1]).addall(objFieldmap.get(keys[keys.size()-1]));
            }else{
                sObjectsResult.putAll(objFieldmap);
            }                                        
            //sObjectsResult.putAll(getSOQLSObjectFields(getSOQLquery.group(1)));
        }

        matcher getSOQLWhere = getSOQLWhereCondition.matcher(ApexClassRemoveComments);
        system.debug('0000ApexClassWithoutLineComments####-->'+ApexClassWithoutLineComments);
        system.debug('00000ApexClassRemoveComments#####-->'+ApexClassRemoveComments);
        while (getSOQLWhere.find()) {     
            system.debug('***********'+getSOQLWhere.group(1));
            map<string,set<string>> objFieldmap;
            objFieldmap = getSOQLWhereConditionSObjectFields(getSOQLWhere.group(1));
            list<string> keys = new list<string>();
            keys.addAll(objFieldmap.keyset());
            if(sObjectsResult.containsKey(keys[keys.size()-1])){
                sObjectsResult.get(keys[keys.size()-1]).addall(objFieldmap.get(keys[keys.size()-1]));
            }else{
                sObjectsResult.putAll(objFieldmap);
            }            
        }

        system.debug('FINAL-->'+sObjectsResult);
        //if(!sObjectsResult.isEmpty()){
            methodSObjectsMap.put(methodName,sObjectsResult);
        //}   
        return methodSObjectsMap;
    }
    
    public Set<String> findSObjectFields(string sObjectVariableRef, string ApexClassWithoutLineComments){
        system.debug('Check------>>>'+ApexClassWithoutLineComments);
        Set<String> setOfFields= new Set<String>();
        string fieldReferences = sObjectVariableRef + '\\.';      
        Pattern findSObjectFields = Pattern.compile(fieldReferences);       
        Matcher sObjectFieldsFind = findSObjectFields.matcher(ApexClassWithoutLineComments);

        while (sObjectFieldsFind.find()) {
            system.debug('sObjectFieldsFind---->>>'+sObjectFieldsFind.end());
            string temp1 = ApexClassWithoutLineComments.substring(sObjectFieldsFind.end());
            system.debug('temp1indexOf---->>>'+temp1.indexOf('='));
            if(temp1.indexOf('=') != -1) {
                string temp2 = temp1.substring(0,temp1.indexOf('=')).trim();
                system.debug('temp2---->>>'+temp2);//ApexClassWithoutLineComments.indexOf('=')
                setOfFields.add(temp2);
            }
        }
        system.debug('setOfFields---->>>'+setOfFields);
        return setOfFields;   
    }
    
    /**************************************************************************************
        
        Description: This method is used to Process the Query and 
        Get the Fields and Objects that are used in 
        the Query
        paramaeters: 
            @ queryString -- Query to get the Data
            @ hasNestedQuery -- If the Query is Nested Query
            @ parentQuery -- If the Query is Nested Query pass the Main Query to get the Parent Object
    **************************************************************************************/    
    public map<String,set<string>> getSOQLSObjectFields(string queryString, boolean hasNestedQuery,string parentQuery){
        system.debug('Check--Query string'+queryString);
        Set<String> setOfFields= new Set<String>();
        map<string,set<string>> objFieldsmap = new map<string,set<string>>();        
        string sObjectName = queryString.split(' ')[queryString.split(' ').size()-1];
        sObjectName = sObjectName.replace(']','');
        sObjectName = sObjectName.replace('\'','');
        sObjectName = sObjectName.replace(')','');
        
        system.debug('Check--sObjectName-- '+sObjectName);

        integer fromIndex = queryString.lastIndexOfIgnoreCase('from');
        string quryFields = queryString.substring(queryString.indexOf(' '),fromIndex);
        quryFields = quryFields.replaceAll('(?i)\\((SELECT\\s+?[^\\s]+?\\s+?.*FROM\\s+?[^\\s]+?(\\)))','');

        list<string> fieldsList = quryFields.split(',');

        if(hasNestedQuery){
           string parentObjt = parentQuery.split(' ')[parentQuery.split(' ').size()-1];
           String[] types = new String[]{parentObjt};
           Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types); 
           Schema.ChildRelationship[] chilRelList = results[0].getChildRelationships();
           for(Schema.ChildRelationship cRel: chilRelList){
                if(cRel.getRelationshipName() == sObjectName){
                    sObjectName = string.valueOf(cRel.getChildSObject());    
                }
           }
        }
        sObjectName = sObjectName.toLowerCase();
        system.debug('Check--setOfFields-- '+quryFields);
        system.debug('Check--fieldsList-- '+fieldsList);
        // To match the case sensitive in Map key (Sobject Name)
        String[] types = new String[]{sObjectName};
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        sObjectName = results[0].getName();        
        for(string fields: fieldsList){
            fields = fields.trim();
            if(fields != '' && objFieldsmap.containskey(sObjectName)){
                objFieldsmap.get(sObjectName).add(fields);
            }else if(fields != ''){
                objFieldsmap.put(sObjectName,new set<string>()); 
                objFieldsmap.get(sObjectName).add(fields);   
            }
            system.debug('&&&&&&&&&&&&&---'+fields);
        }

        return objFieldsmap;   
    }

    /**************************************************************************************        
        Description: This method is used to Process the Where Condition of the Queury and 
        Get the Fields and Objects that are used in the Query
        paramaeters: 
            @ whereConditionString -- Where Condition String of the Query
    **************************************************************************************/    
    public map<String,set<string>> getSOQLWhereConditionSObjectFields(string whereConditionString){
        system.debug('Check--Query string'+whereConditionString);
        Set<String> setOfFields= new Set<String>();
        map<string,set<string>> objFieldsmap = new map<string,set<string>>();        
        // Replace "From" where condition
        whereConditionString = whereConditionString.replaceAll('(?i)(from )','');
        whereConditionString = whereConditionString.trim();
        string sObjectName = whereConditionString.split(' ')[0];
        list<string> conditionSplit = whereConditionString.split('(?i)(=|!=|like)');
        integer index = 1;
        for(string fieldString: conditionSplit){
            if(conditionSplit.size() > index){        
                list<string> fieldNames = fieldString.split(' ');
                if(fieldNames.size() > 0){
                    string fieldAPIName = fieldNames[fieldNames.size()-1];
                    fieldAPIName = fieldAPIName.replace('(','');
                    setOfFields.add(fieldAPIName);  
                }
            }    
            index++;
        }
        // To match the case sensitive in Map key (Sobject Name)
        String[] types = new String[]{sObjectName};
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        sObjectName = results[0].getName();           
        objFieldsmap.put(sObjectName,setOfFields);
        return objFieldsmap;   
    }    



    private HttpRequest httpRequestExecutor(string endPointService, string method){
        HttpRequest req = new HttpRequest();
        endPointService += '';
        req.setEndpoint(endPointService);
        req.setMethod(method);
        req.setHeader('Authorization', 'Bearer '+UserInfo.getSessionId());
        req.setHeader('Content-Type','application/json');
        return req;
    }
    
    private String getResponse(HttpRequest req){
        try{
            Http httpReq = new Http();
            HttpResponse res = httpReq.send(req);
            String reqResponse = res.getBody();
            return reqResponse;
        }catch (Exception e){
            return 'Error:' +e.getMessage();
        }
    }   
}