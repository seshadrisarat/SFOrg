/**
 * Company     : Adobe Systems Inc. 
 * Description : Create New Test Class Controller 
*                This controller will create test class with the name ClassNmae_Test with final set of body.
 * History     : 2016 - Code creation.
 */
public class CreateNewTestClass {    
    /**  
     *@Desc:  testClassCreation:  This method is used to create test class. Content of the test are generated in ScanApexClassCtrl
     *                            TestData Preparation is happening by New method JSONDataParser.createTestData
     *                            by using json data. Also this method will scan Parameters and also 
     *                            to assign default values to method parameters. 
     */     
    public static testClassResWrapper testClassCreation(String className, String JSONData, String asyncRequestId) {
        ScanApexClassCtrl apexCtrl = new ScanApexClassCtrl(asyncRequestId, className);
        Map<String, MethodProperties> mapMethodNameProperties = apexCtrl.mapMethodNameProperties;
        String testClassName, testClassBody, testSetUpBody, runAsTestUser, testMethodBody1;
        
        testClassName = className + '_Test';
        testMethodBody1 =  '\t' + className + ' ' + className + '_obj = new ' + className + '();\n';
        
        if (!mapMethodNameProperties.isEmpty()) {
            for (String methodName : mapMethodNameProperties.keySet()) {
                System.debug('methodName: ' + methodName);
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
        System.debug('mapMethodNameProperties: ' + mapMethodNameProperties);
        
        Map<String, Set<String>> foundObjectFieldsMap = new Map<String, Set<String>>();
        String foundObjectFieldStatic = '';
        if (!mapMethodNameProperties.isEmpty()) {
            for (String methodNameKey : mapMethodNameProperties.keySet()) {
                foundObjectFieldsMap.putAll(mapMethodNameProperties.get(methodNameKey).mapObjFields);
            }
        }   
        if (!foundObjectFieldsMap.isEmpty()) {
            System.debug('foundObjectFieldsMap: ' + foundObjectFieldsMap);
            for (String objectKey : foundObjectFieldsMap.keySet()) {
                Set<String> fieldValuesList = foundObjectFieldsMap.get(objectKey);
                System.debug('fieldValuesList: ' + fieldValuesList);
                String tempObjectField = '\'' + objectKey + '\'=> new set<string>{';
                if (!fieldValuesList.isEmpty()) {
                    for (String tempFieldValue : fieldValuesList) {
                        tempObjectField = tempObjectField + '\'' + tempFieldValue + '\'' + ',';
                    }
                }
                tempObjectField = tempObjectField.removeEnd(',');
                tempObjectField = tempObjectField + '},';
                System.debug('tempObjectField: ' + tempObjectField);
                foundObjectFieldStatic = foundObjectFieldStatic + tempObjectField;
            }
        }
        foundObjectFieldStatic = foundObjectFieldStatic.removeEnd(','); 
        System.debug('foundObjectFieldStatic: ' + foundObjectFieldStatic);
        
        String jsonInsert = '\t\t\t\t JSONDataParser.createTestData(\'' + JSONData + '\');\n';
        runAsTestUser = 'new User(Id = Userinfo.getUserId())';
        testSetUpBody = '\t System.runAs(' + runAsTestUser + ') { \n'
                        + jsonInsert + '\n'
                        + '\t\t }';
        testClassBody = ' /* @Company     : Adobe Systems Inc. \n'
                        + '***************************************************************************************************\n'
                        + '****** This is an System generated Test Class for '+ className +' ******\n'
                        + '***************************************************************************************************\n'
                        + '*/ \n\n'
                        + '@isTest \n' 
                        + 'private class ' + testClassName + ' { \n'
                        + '\t @testSetup static void setupTestDataFor_' + testClassName + '() { \n'
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

        if (saveRes.success) {
            newTestClassRes.testClassId = saveRes.id;
            newTestClassRes.isSuccess = true;
            newTestClassRes.testClassName = testClassName;
            newTestClassRes.message = 'Test Class ' + testClassName + ' Successfully created.';
        } else {
            newTestClassRes.testClassId = '';
            newTestClassRes.isSuccess = false;
            newTestClassRes.testClassName = testClassName;
            newTestClassRes.message = 'Test Class ' + testClassName + 'could not be created. The error reported was: ' +  saveRes.errors[0].message + '\n';
        }
        return newTestClassRes;
    }


    public static testClassResWrapper SaveApexClass(string testClassName, string testClassBody){
                
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

        if (saveRes.success) {
            newTestClassRes.testClassId = saveRes.id;
            newTestClassRes.isSuccess = true;
            newTestClassRes.testClassName = testClassName;
            newTestClassRes.message = 'Test Class ' + testClassName + ' Successfully created.';
        } else {
            newTestClassRes.testClassId = '';
            newTestClassRes.isSuccess = false;
            newTestClassRes.testClassName = testClassName;
            newTestClassRes.message = 'Test Class ' + testClassName + 'could not be created. The error reported was: ' +  saveRes.errors[0].message + '\n';
        }    
        
        return newTestClassRes;
    }
    
    /**  
     *@Desc:  testClassResWrapper: To save status, created class id, name and message.
     */    
    public class testClassResWrapper {
        public boolean isSuccess;
        public Id testClassId;  
        public string testClassName;      
        public string message;
    }

    /**  
     *@Desc:  getDefaultValue: Assigning default values for parameters
     */ 
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

    /**  
     *@Desc:  parseListSet: To Get List/Set Sobject Type.
     */   
    private static String parseListSet(String pType) {
        String innerPType = pType.startsWithIgnoreCase('List') ? pType.subString(5, pType.length() - 1) : pType.subString(4, pType.length() - 1);
        return getDefaultValue(innerPType);
    }

    /**  
     *@Desc:  testClassResWrapper: To Get Map Sobject Type.
     */   
    private static String parseMap(String pType) {
        String innerPType = pType.subString(4, pType.length() - 1);
        Integer commaIndex = innerPType.indexOf(',');
        return getDefaultValue(innerPType.subString(0, commaIndex)) + ' => ' + getDefaultValue(innerPType.subString(commaIndex + 1));
    }
}