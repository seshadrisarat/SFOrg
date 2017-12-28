Public class FetchApexClassSymbolTable{

    Public Static Map<Id, set<string>> classMethodMap;
    Public Static Map<Id, Map<string,string>> classMethodNameContentMap;
    Public static Map<string,string> methodNameContentMap;
    
    Public static Map<string,string> getMethodNameContent(string classId, String ApexClassBody){
        classMethodMap = new Map<Id, set<string>>();
        methodNameContentMap = new Map<string,string>();
        classMethodNameContentMap = new Map<Id, Map<string,string>>();
        ToolingApi tooling = new ToolingApi();
        String metadataContainerId;             
        String classBody = ApexClassBody;
        
        List<ToolingAPI.MetadataContainer> containers = (List<ToolingAPI.MetadataContainer>)tooling.query('SELECT Id, Name FROM MetadataContainer WHERE Name = \'ApexTestClass\'').records;
        if (containers != null && ! containers.isEmpty()){
            tooling.deleteSObject(ToolingAPI.SObjectType.MetadataContainer, containers[0].Id);
        }else{
            ToolingAPI.MetadataContainer container = new ToolingAPI.MetadataContainer();
            container.name = 'ApexTestClass';
            ToolingAPI.SaveResult containerSaveResult = tooling.createSObject(container);
            metadataContainerId = containerSaveResult.id;   
        }

        ToolingAPI.ApexClassMember apexClassMember = new ToolingAPI.ApexClassMember();
        apexClassMember.Body = classBody; 
        apexClassMember.ContentEntityId = classId;
        apexClassMember.MetadataContainerId = metadataContainerId;
        ToolingAPI.SaveResult apexClassMemberSaveResult = tooling.createSObject(apexClassMember);

        ToolingAPI.ContainerAsyncRequest asyncRequest = new ToolingAPI.ContainerAsyncRequest();
        asyncRequest.metadataContainerId = metadataContainerId;
        asyncRequest.IsCheckOnly = true;
        ToolingAPI.SaveResult asyncRequestSaveResult = tooling.createSObject(asyncRequest);

        string requestId = asyncRequestSaveResult.id;
        system.debug('requestId-->>>'+requestId);
        String soql = 'SELECT Id, State, ErrorMsg FROM ContainerAsyncRequest Where id = \'' + requestId + '\'';
        ToolingAPI.QueryResult queryResult = tooling.query(soql);

        //ToolingAPI.ContainerAsyncRequest request = (ToolingAPI.ContainerAsyncRequest)queryResult.records[0];  
        if (queryResult.size > 0){
            ToolingAPI.ContainerAsyncRequest request = (ToolingAPI.ContainerAsyncRequest)queryResult.records[0];
            while (request.State == 'Queued'){
                queryResult = tooling.query(soql);
                request = (ToolingAPI.ContainerAsyncRequest)queryResult.records[0];
            }
        }

        String soql1 = 'SELECT Body, ContentEntityId, SymbolTable FROM ApexClassMember WHERE ContentEntityId = \'' + classId + '\' Order by createdDate desc';
        ToolingApi.queryResult qResult = tooling.query(soql1);
        system.debug('**************Debug sym'+qResult);
        ToolingAPI.ApexClassMember apexClass = (ToolingAPI.ApexClassMember)qResult.records[0];
        ToolingAPI.SymbolTable symbolTableRef = apexClass.SymbolTable;
        system.debug('Method Name--->>'+symbolTableRef);

        system.debug(logginglevel.debug,'**************Debug sym'+qResult);
        Set<string> methodNameSet;
        for(Integer i=0; i < symbolTableRef.Methods.size();i++){             
            if(!classMethodMap.containsKey(classId)){
                methodNameSet = new Set<string>();
                methodNameSet.add(string.valueOf(symbolTableRef.Methods[i].name));
                classMethodMap.put(classId,methodNameSet);
            }else{              
                methodNameSet = classMethodMap.get(classId);
                methodNameSet.add(string.valueOf(symbolTableRef.Methods[i].name));
                classMethodMap.put(classId,methodNameSet);
            }
        }       
        if(!classMethodMap.isEmpty()){  
            Set<string> methodNames = classMethodMap.get(classId);
            system.debug('methodName-->>>'+methodNames);
            for(string methodNameRef : methodNames){
                Map<string,string> methodNameContent = new Map<string,string>();            
                methodNameContent = fetchMethodContent(ApexClassBody,methodNameRef);  
                system.debug('methodNameContent-->>>'+methodNameContent);               
                methodNameContentMap.putAll(methodNameContent);
            }           
        }
        system.debug('methodNameContentMap-->>>'+methodNameContentMap);
        return methodNameContentMap;
    }
    
    
    public static Map<string,string> fetchMethodContent(String classBody, String methodName) {
        Map<string,string> methodNameBodyMap = new Map<string,string>();
        
        String ptrn = '(?:.*' + methodName + '\\s*\\([^\\)]*\\)\\s*\\{)';
        Pattern p = Pattern.compile(ptrn);
        Matcher m = p.matcher(classBody);
        Integer i = 0;
        while(m.find()) {
            i = m.end();
            System.debug('Starting index of method: ' + i);
        }
        if (i == 0) {
            return null;
        }
        String methodContent = charParse(classBody.subString(i));
        methodContent = methodContent.subString(0, methodContent.length() - 1);
        //methodContent = methodContent.replace('\n','');
        System.debug('Return string: ' + methodContent);
        methodNameBodyMap.put(methodName, methodContent);
        system.debug('methodNameBodyMap-->>'+methodNameBodyMap);
        return methodNameBodyMap;
    }
    
    private static String charParse(String content) {
        String m = '';
        Integer cnt = 0;
        Boolean stringStarted = false;
        Boolean singleLineCommentStarted = false;
        Boolean multiLineCommentStarted = false;
        for (Integer i = 0; i < content.length(); i++) {
            String c = content.subString(i, i + 1);
            if (singleLineCommentStarted) {
                m += c;
                if (c == '\n') {
                    singleLineCommentStarted = false;
                }
            } else if (multiLineCommentStarted) {
                m += c;
                if (c == '*') {
                    String c1 = content.subString(i + 1, i + 2);
                    if (c1 == '/') {
                        m += c1;
                        i++;
                        multiLineCommentStarted = false;
                    }
                }
            } else if (c == '\\') {
                m += c + content.subString(++i, i + 1);
            } else if (c == '\'') {
                m += c;
                stringStarted = !stringStarted;
            } else if (stringStarted) {
                m += c;
            } else if (c == '/') {
                String c1 = content.subString(i + 1, i + 2);
                if (c1 == '/') {
                    singleLineCommentStarted = true;
                } else if (c1 == '*') {
                    multiLineCommentStarted = true;
                }
                m += c;
            } else if (c == '{') {
                m += c;
                cnt++;
            } else if (c == '}') {
                m += c;
                cnt--;
            } else {
                m += c;
            }
            if (cnt == -1) {
                break;
            }
        }
        return m;
    }
    
    public static List<String> fetchDMLs(String content) {
        String ptrn = '(?i)((?:Database\\.)?(?:insert|update|upsert|delete|undelete|merge)\\b\\s*.*\\s*;)';
        return fetchMatchingContent(ptrn, content);
    }
    
    public static List<String> fetchQueries(String content) {
        String ptrn = '(?i)((?:[\\[\']\\s*Select\\b)[\\s\\S]*?[\\]\']\\s*?;)';
        return fetchMatchingContent(ptrn, content);
    }
    
    public static List<String> fetchMatchingContent(String ptrn, String content) {
        Pattern p = Pattern.compile(ptrn);
        Matcher m = p.matcher(content);
        Set<String> setMatch = new Set<String>();
        while(m.find()) {
            setMatch.add(m.group(1));
        }
        return new List<String>(setMatch);
    }

}