public class ConditionParser{

    public static String tempValue= '';
    public static Map<Integer,String> conditionMap = new Map<Integer,String>();
    //public static Map<Integer,SObject> testObjects = new Map<Integer,SObject>();
    public static Map<String,SObject> testObjects = new Map<String,SObject>();
    
    public static String mainMethod(Node parentNode, Map<Integer,list<Integer>> traversalOrder){
    	createConditionalMap(traversalOrder, parentNode);
        Map<Integer,List<Conditions>> conditionsMap = createNewConditionalMap(conditionMap);
        System.debug('conditionMap final: ' +conditionsMap);

        for(Integer key : conditionsMap.keySet()){
            List<Conditions> conditionsList = conditionsMap.get(key);

            // TODO
            Customer__c cust_cc = new Customer__c();
            defaultValues(cust_cc);

            for(Conditions cond : conditionsList){
                createInstance(cond, cust_cc);
            }
            testObjects.put('TestMethod_ ' + key, cust_cc);
        }
        // Temp code starts
        String className = 'MyClass_Test';
        String testContent = createTestClassContent(className,testObjects);
        CreateNewTestClass.SaveApexClass(className,testContent);
        System.debug('Test Content : '+testContent);
        // Temp code ends

        System.debug('Test objects : '+testObjects);
        String jsonValue = JSON.serialize(testObjects);
        return jsonValue;
    }


    // Temp method
    private static String createTestClassContent(String className, Map<String,SObject> mapObjects){
        String returnValue = '@isTest\n';
        returnValue+= 'private class '+className+' {\n\n';
        Integer counter = 0;

        for(String key : mapObjects.keySet()){
            Customer__c cust = new Customer__c();
            cust = (Customer__c)mapObjects.get(key);

            returnValue += '\t@isTest public static void testMethod'+counter+'(){\n';
            returnValue += '\t\tCustomer__c cust= new Customer__c();\n';
            returnValue += '\t\tcust.name__c =  \''+cust.name__c+'\';\n';
            returnValue += '\t\tcust.gender__c = \''+cust.gender__c+'\';\n';
            returnValue += '\t\tcust.age__c = '+cust.age__c+';\n';
            returnValue += '\t\tMyClass myCls = new MyClass();\n';
            returnValue += '\t\tmyCls.getDiscount(cust);\n';
            returnValue += '\t}\n\n';

            counter++;
        }
        returnValue += '}\n';
        return returnValue;
    }

    private static void defaultValues(Customer__c cust_cc){
        cust_cc.name__c = 'Default';
        cust_cc.gender__c = 'Default';
        cust_cc.age__c = -1;
    }
    
    private static void createInstance(Conditions condarg, Customer__c cust_cc){
        String operatorType = condarg.condition;
        String lhs = condarg.lhs;
        String rhs = condarg.rhs;
        lhs = trimInput(lhs);
        rhs = trimInput(rhs);

        // TODO get the instance variable from map in init method and remove it from lhs and rhs
        lhs = lhs.replaceAll('customer', '');

        if(lhs.contains('gender')){
           cust_cc.gender__c = rhs; 
        }else if(lhs.contains('age')){
            if(operatorType.equals('>')){
                cust_cc.age__c = Integer.valueOf(rhs) + 1;
            }else if(operatorType.equals('<')){
                cust_cc.age__c = Integer.valueOf(rhs);
                cust_cc.age__c = cust_cc.age__c--;
            }else if(operatorType.equals('==')){
                cust_cc.age__c = Integer.valueOf(rhs);
            }

        }else if(lhs.contains('name')){
            cust_cc.name__c = rhs;
        }

    }

    private static void createConditionalMap(Map<Integer, list<Integer>> inTraversalOrder, Node parentNode) {
            system.debug('Number of test methods that need to be created : '+inTraversalOrder.size());
            system.debug(inTraversalOrder.size() + ' sets of conditions are:');

        Map<Integer,String> nodemap = new Map<Integer,String>();

        // Update the nodemap with number of traversal paths as key and conditions as value.
        for(integer i =0; i < inTraversalOrder.size(); i++){
            nodemap.put(parentNode.id, parentNode.condition);
            if(parentNode.childNodes != null){
                updateNodeMap(parentNode.childNodes, nodemap);
            }
        }

        // for the nodemap trim the conditional strings and append the separator between the conditions
        for(integer k=0;k<inTraversalOrder.size();k++){
            list<Integer> listTravers = inTraversalOrder.get(k);
            String condition = '';

            for(Integer inte: listTravers ){
                condition = nodemap.get(inte);
                if(condition != null){
                    if(condition.contains('else if')){
                        condition = condition.replaceAll('else if', '');
                    }
                    if(condition.contains('if')){
                        condition = condition.replaceAll('if', '');
                    }

                    tempValue = tempValue+''+ condition +''+'-';
                }
            }
            
            conditionMap.put(k, tempValue);
            tempValue = '';
        }

    }

    private static void updateNodeMap(List<Node> childNodes, Map<Integer, String> nodemap) {
        for(integer j=0; j<childNodes.size();j++){
            nodemap.put(childNodes.get(j).id, childNodes.get(j).condition);
            if(childNodes.get(j).childNodes != null){
                updateNodeMap(childNodes.get(j).childNodes , nodemap);
            }
        }

    }

    private static Object findValuesWithType(String lhs,String rhs, Map<String, String> fieldTypes, String condition) {
        String checkType = fieldTypes.get(lhs);
        Object returnValue = '';
        if(checkType.equals('String')){
            returnValue = rhs;
        }else if(checkType.equals('Integer')){
            if(condition.equals('>')){
                returnValue = (Integer.valueOf(rhs))+1;
            }else if(condition.equals('<')){
                returnValue = (Integer.valueOf(rhs))-1;
            }
        }
        return returnValue;
    }



    private static String findOperator(String tempData) {
        String returnValue = '';
        if(tempData.contains('equals')){
            returnValue = 'equals';
        }else if(tempData.contains('>')){
            returnValue = '>';
        }else if(tempData.contains('<')){
            returnValue = '<';
        }
        return returnValue;
    }


    private static Map<Integer,List<Conditions>> createNewConditionalMap(Map<Integer,String> conditionMap1){
        Map<Integer,List<Conditions>> conditionsLocalMap = new Map<Integer,List<Conditions>>();
        for(Integer key : conditionMap1.keySet()){
            String value = conditionMap1.get(key);
            List<String> conditionList = value.split('-');
            
            List<Conditions> conditionsList1 = new List<Conditions>();
            for(String conditions1 : conditionList){
                if(conditions1 != null && conditions1 != ''){
                    Conditions cond = createConditions(conditions1);
                    conditionsList1.add(cond);
                }
            }
            conditionsLocalMap.put(key,conditionsList1);

        }
        return conditionsLocalMap;

    }

    private static Conditions createConditions(String cond1){
        Conditions cond = new Conditions();
        String oper  = findOperator(cond1);
        cond.setCondition(oper);
        List<String> cond11 = cond1.split(oper);

        // TODO
        //String refType = findReferenceType(cond1);
        //System.debug('refType '+refType);


        cond.setLhs(cond11.get(0));
        cond.setRhs(cond11.get(1));
        return cond;
    }

    /*private static String findReferenceType(String dataa){
        Set<String> refValues = CodeParser.referenceMap.keySet();
        for(String refVal : refValues){
            if(dataa.contains(refVal)){
                return CodeParser.referenceMap.get(refVal);
            }
        }
        return null;
    }*/

    private static String trimInput(String inputData){
        String data = inputData;
        inputData = inputData.trim();
        inputData = inputData.replaceAll('\'', '');
        inputData = inputData.replaceAll('[()]', '');

        // TODO Check why removeEnd method is not working
        //inputData = inputData.removeEnd('\\.');

        inputData = inputData.replaceAll('\\.','');

        return inputData;

    }
}