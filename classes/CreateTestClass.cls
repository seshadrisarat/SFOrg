public class CreateTestClass {
    
    public static testClassResWrapper testClassCreation(string className, Map<string,Map<string,set<string>>> classProperties){
        
        Map<string,Map<string,set<string>>> foundClassProperties = classProperties; 
        
        Map<string,set<string>> foundSobjectFields = new Map<string,set<string>>();        
        Map<String, Map<String,String>> testDataFinal = new Map<String, Map<String,String>>();
        
        
        string testClassName, testClassBody, testSetUpBody, runAsTestUser, testMethodBody1;
        //testDataPreparation.testDataPrepWrapper testUser, testAccount, testContact, testOpportunity;
        testClassName = className+'_Test';
        
        //testUser = testDataPreparation.getTestUser();
        
        testDataPreparation.testDataPrepWrapper testAccount = testDataPreparation.getTestAccount();
        testDataPreparation.testDataPrepWrapper testContact = testDataPreparation.getTestContact();
        testDataPreparation.testDataPrepWrapper testOpportunity = testDataPreparation.getTestOpportunity();
                
        
        testMethodBody1 =  '\t' + className + ' ' + className + '_obj = new ' + className + '();\n';
        if(!foundClassProperties.isEmpty()){              
            for(string methodName : foundClassProperties.keySet()){
                system.debug('methodName-->'+methodName);
                //foundSobjectFields.putAll((Map<string,set<string>>)foundClassProperties.get(methodName));
                testMethodBody1 = testMethodBody1 + '\t\t\t' + className + '_obj.' + methodName + '(); \n';
            }
        }
        system.debug('classProperties---->>'+classProperties);
    
        /*  
        Map<String, set<string>> temp = new Map<String, set<string>>{'Account'=> new set<string>{},'Contact'=> new set<string>{'firstName','lastName','Department'},'Opportunity'=> new set<string>{'Name','CloseDate','MainCompetitors__c'}};

        Map<String,Map<String,TestClassDataPrepareUtility.FieldInfoWrapper>> objectFieldProperties = TestClassDataPrepareUtility.getFieldInfoUsingDescribeCall(temp);
        
        Map<String,Map<String,String>>  testDataRes = createTestData.createData(objectFieldProperties);
        
        system.debug('testDataRes--->>'+testDataRes);
        */
        
        //'Account'=> new set<string>{},'Contact'=> new set<string>{'firstName','lastName','Department'},'Opportunity'=> new set<string>{'Name','CloseDate','MainCompetitors__c'}
    
        Map<string,set<string>> foundObjectFieldsMap = new Map<string,set<string>>();
        string foundObjectFieldStatic = '';
        string invokeTestDataPreparation = '';
    
        if(!classProperties.isEmpty()){
            for(string methodNameKey : classProperties.keySet()){
                foundObjectFieldsMap.putAll(classProperties.get(methodNameKey));
            }
        }   
        if(!foundObjectFieldsMap.isEmpty()){
            system.debug('foundObjectFieldsMap--->>'+foundObjectFieldsMap);
            for(string objectKey : foundObjectFieldsMap.keySet()){
                set<string> fieldValuesList = foundObjectFieldsMap.get(objectKey);
                system.debug('fieldValuesList--->>'+fieldValuesList);
                string tempObjectField = '\'' +objectKey+ '\'=> new set<string>{';
                if(!fieldValuesList.isEmpty()){
                    for(string tempFieldValue : fieldValuesList){
                        tempObjectField = tempObjectField + '\'' +tempFieldValue+ '\'' + ',';
                    }
                }
                tempObjectField = tempObjectField.removeEnd(',');
                tempObjectField = tempObjectField + '},';
                system.debug('tempObjectField--->>'+tempObjectField);
                foundObjectFieldStatic = foundObjectFieldStatic + tempObjectField;
            }
        }
        foundObjectFieldStatic = foundObjectFieldStatic.removeEnd(','); 
        system.debug('foundObjectFieldStatic--->>'+foundObjectFieldStatic);
        
        invokeTestDataPreparation = '\t\t\t\t Map<string,set<string>> finalObjectFieldMap = new Map<string,set<string>>{'+foundObjectFieldStatic+'};\n'
                                    + '\t\t\t\t Map<String,Map<String,TestClassDataPrepareUtility.FieldInfoWrapper>> objectFieldProperties = TestClassDataPrepareUtility.getFieldInfoUsingDescribeCall(finalObjectFieldMap);\n'
                                    + '\t\t\t\t Map<string,Map<string,string>> genTestDataResult = createTestData.createData(objectFieldProperties);\n'
                                    + '\t\t\t\t Map<string, sObject> sObjectFinalMap = createTestData.dynamicSobject(genTestDataResult,objectFieldProperties);';
                                /*    
                                    + 'system.debug(LoggingLevel.INFO, \'<<< Test Data for Unit Testing >>> \' + sObjectFinalMap);\n'
                                    
                                    + 'string testDataResult = \'\';\n'
                                    + 'for(string testRec : sObjectFinalMap.keySet()){\n'
                                    + 'testDataResult = testDataResult + sObjectFinalMap.get(testRec)' + '\n' + ';\n'
                                    + '}\n'
                                    + 'system.debug(\'Checking--->>\'+testDataResult);\n';
                                */
        runAsTestUser = 'new User(Id = Userinfo.getUserId())';
        testSetUpBody = '\t System.runAs('+ runAsTestUser + ') { \n'
                        + invokeTestDataPreparation + '\n'
                        + '\t\t }';
                        
        testClassBody = ' /* @Company     : Adobe Systems Inc. \n'
                        + '***************************************************************************************************\n'
                        + '****** This is an System generated Test Class for '+ className +' ******\n'
                        + '***************************************************************************************************\n'
                        + '*/ \n\n'
                        + '@isTest \n' 
                        + 'private class ' + testClassName + ' { \n'
                        + '\t @testSetup static void setupTestDataFor_'+ testClassName +'() { \n'
                        + '\t' + testSetUpBody + '\n'
                        + '\t } \n'
                        + '\t static testMethod void testScenario1() { \n'
                        + '\t\t' + testMethodBody1
                        + '\t } \n'
                        + '}';
                        
        testClassResWrapper newTestClassRes = new testClassResWrapper();
        ToolingAPI toolingAPI = new ToolingAPI();
        ToolingAPI.ApexClass newTestClass = new ToolingAPI.ApexClass();
        newTestClass.Name = testClassName;
        newTestClass.Body = testClassBody;      
        ToolingAPI.SaveResult saveRes = toolingAPI.createSObject(newTestClass);             

        if (saveRes.success){
            newTestClassRes.testClassId = saveRes.id;
            newTestClassRes.isSuccess = true;
            newTestClassRes.message = 'Test Class '+ testClassName +' Successfully created.';
        } else{
            newTestClassRes.testClassId = '';
            newTestClassRes.isSuccess = false;
            newTestClassRes.message = 'Test Class '+ testClassName +'could not be created. The error reported was: ' +  saveRes.errors[0].message + '\n';
        }
        return newTestClassRes;
    }
    
    public static TestClassResWrapper testClassCreation1(String className, Map<String, MethodProperties> mapMethodNameProperties) {
        Map<string,set<string>> foundSobjectFields = new Map<string,set<string>>();        
        Map<String, Map<String,String>> testDataFinal = new Map<String, Map<String,String>>();
        
        
        String testClassName, testClassBody, testSetUpBody, runAsTestUser, testMethodBody1;
        testClassName = className+'_Test';
        
        testDataPreparation.testDataPrepWrapper testAccount = testDataPreparation.getTestAccount();
        testDataPreparation.testDataPrepWrapper testContact = testDataPreparation.getTestContact();
        testDataPreparation.testDataPrepWrapper testOpportunity = testDataPreparation.getTestOpportunity();
                
        
        testMethodBody1 =  '\t' + className + ' ' + className + '_obj = new ' + className + '();\n';
        if(!mapMethodNameProperties.isEmpty()){
            for(String methodName : mapMethodNameProperties.keySet()){
                System.debug('methodName-->'+methodName);
                MethodProperties mp = mapMethodNameProperties.get(methodName);
                String mdf = '';
                if (mp.method.modifiers != null) {
                    mdf = String.join(mp.method.modifiers, ';').toLowerCase();
                }
                if (mdf.indexOf('private') > -1) {
                    continue;
                }
                testMethodBody1 += '\t\t\t' + className + '_obj.' + methodName + '(';
                if (mp.method.parameters != null) {
                    System.debug('Method Params: ' + mp.method.parameters);
                    String paramBody = '';
                    for (ToolingAPI.Parameter p : mp.method.parameters) {
                        paramBody += ',' + getDefaultValue(p.type);
                    }
                    testMethodBody1 += paramBody != '' ? paramBody.subString(1) : '';
                }
                testMethodBody1 += '); \n';
            }
        }
        System.debug('mapMethodNameProperties---->>'+mapMethodNameProperties);
        
        Map<string,set<string>> foundObjectFieldsMap = new Map<string,set<string>>();
        string foundObjectFieldStatic = '';
        string invokeTestDataPreparation = '';
    
        if(!mapMethodNameProperties.isEmpty()){
            for(string methodNameKey : mapMethodNameProperties.keySet()){
                foundObjectFieldsMap.putAll(mapMethodNameProperties.get(methodNameKey).mapObjFields);
            }
        }   
        if(!foundObjectFieldsMap.isEmpty()){
            system.debug('foundObjectFieldsMap--->>'+foundObjectFieldsMap);
            for(string objectKey : foundObjectFieldsMap.keySet()){
                set<string> fieldValuesList = foundObjectFieldsMap.get(objectKey);
                system.debug('fieldValuesList--->>'+fieldValuesList);
                string tempObjectField = '\'' +objectKey+ '\'=> new set<string>{';
                if(!fieldValuesList.isEmpty()){
                    for(string tempFieldValue : fieldValuesList){
                        tempObjectField = tempObjectField + '\'' +tempFieldValue+ '\'' + ',';
                    }
                }
                tempObjectField = tempObjectField.removeEnd(',');
                tempObjectField = tempObjectField + '},';
                system.debug('tempObjectField--->>'+tempObjectField);
                foundObjectFieldStatic = foundObjectFieldStatic + tempObjectField;
            }
        }
        foundObjectFieldStatic = foundObjectFieldStatic.removeEnd(','); 
        system.debug('foundObjectFieldStatic--->>'+foundObjectFieldStatic);
        
        invokeTestDataPreparation = '\t\t\t\t Map<string,set<string>> finalObjectFieldMap = new Map<string,set<string>>{'+foundObjectFieldStatic+'};\n'
                                    + '\t\t\t\t Map<String,Map<String,TestClassDataPrepareUtility.FieldInfoWrapper>> objectFieldProperties = TestClassDataPrepareUtility.getFieldInfoUsingDescribeCall(finalObjectFieldMap);\n'
                                    + '\t\t\t\t Map<string,Map<string,string>> genTestDataResult = createTestData.createData(objectFieldProperties);\n'
                                    + '\t\t\t\t Map<string, sObject> sObjectFinalMap = createTestData.dynamicSobject(genTestDataResult,objectFieldProperties);';
                                /*    
                                    + 'system.debug(LoggingLevel.INFO, \'<<< Test Data for Unit Testing >>> \' + sObjectFinalMap);\n'
                                    
                                    + 'string testDataResult = \'\';\n'
                                    + 'for(string testRec : sObjectFinalMap.keySet()){\n'
                                    + 'testDataResult = testDataResult + sObjectFinalMap.get(testRec)' + '\n' + ';\n'
                                    + '}\n'
                                    + 'system.debug(\'Checking--->>\'+testDataResult);\n';
                                */
        runAsTestUser = 'new User(Id = Userinfo.getUserId())';
        testSetUpBody = '\t System.runAs('+ runAsTestUser + ') { \n'
                        + invokeTestDataPreparation + '\n'
                        + '\t\t }';
                        
        testClassBody = ' /* @Company     : Adobe Systems Inc. \n'
                        + '***************************************************************************************************\n'
                        + '****** This is an System generated Test Class for '+ className +' ******\n'
                        + '***************************************************************************************************\n'
                        + '*/ \n\n'
                        + '@isTest \n' 
                        + 'private class ' + testClassName + ' { \n'
                        + '\t @testSetup static void setupTestDataFor_'+ testClassName +'() { \n'
                        + '\t' + testSetUpBody + '\n'
                        + '\t } \n'
                        + '\t static testMethod void testScenario1() { \n'
                        + '\t\t' + testMethodBody1
                        + '\t } \n'
                        + '}';
                        
        System.debug('testClassBody: ' + testClassBody);
        testClassResWrapper newTestClassRes = new testClassResWrapper();
        ToolingAPI toolingAPI = new ToolingAPI();
        ToolingAPI.ApexClass newTestClass = new ToolingAPI.ApexClass();
        newTestClass.Name = testClassName;
        newTestClass.Body = testClassBody;
        Id testClassId;
        for (ApexClass ac : [Select Id From ApexClass Where Name = :testClassName]) {
            testClassId = ac.Id;
        }
        if (testClassId != null) {
            ToolingAPI.ApexClass extTestClass = new ToolingAPI.ApexClass();
            extTestClass.Id = testClassId;
            ToolingAPI.SaveResult delRes = toolingAPI.deleteSObject(extTestClass);
        }
        ToolingAPI.SaveResult saveRes = toolingAPI.createSObject(newTestClass);             

        if (saveRes.success){
            newTestClassRes.testClassId = saveRes.id;
            newTestClassRes.isSuccess = true;
            newTestClassRes.message = 'Test Class '+ testClassName +' Successfully created.';
        } else{
            newTestClassRes.testClassId = '';
            newTestClassRes.isSuccess = false;
            newTestClassRes.message = 'Test Class '+ testClassName +'could not be created. The error reported was: ' +  saveRes.errors[0].message + '\n';
        }
        return newTestClassRes;
    }
    
    public class testClassResWrapper {
        public boolean isSuccess;
        public Id testClassId;        
        public string message;
    }

    private static String getDefaultValue(String pType) {
        try {
            if (pType == 'Integer' || pType == 'Double' || pType == 'Long' || pType == 'Decimal') {
                return '2';
            } else if (pType == 'String') {
                return '\'I am String\'';
            } else if (pType == 'Date') {
                return 'Date.today()';
            } else if (pType == 'DateTime') {
                return 'System.now()';
            } else if (pType == 'Time') {
                return 'System.now().time()';
            } else if (pType == 'Blob') {
                return 'Blob.valueOf(\'I am Blob\')';
            } else if (pType.startsWithIgnoreCase('List') || pType.startsWithIgnoreCase('Set')) {
                return 'new ' + pType + '{ ' + parseListSet(pType) + ' }';
            } else if (pType.startsWithIgnoreCase('Map')) {
                System.debug('pType: ' + pType);
                return 'new ' + pType + '{ ' + parseMap(pType) + ' }';
            } else {
                return null;
            }
        } catch (Exception e) {
            return null;
        }
    }

    private static String parseListSet(String pType) {
        String innerPType = pType.startsWithIgnoreCase('List') ? pType.subString(5, pType.length() - 1) : pType.subString(4, pType.length() - 1);
        return getDefaultValue(innerPType);
    }

    private static String parseMap(String pType) {
        String innerPType = pType.subString(4, pType.length() - 1);
        Integer commaIndex = innerPType.indexOf(',');
        return getDefaultValue(innerPType.subString(0, commaIndex)) + ' => ' + getDefaultValue(innerPType.subString(commaIndex + 1));
    }
}