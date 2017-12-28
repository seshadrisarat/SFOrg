public Class TestDataPreparation {

    private static Map<string,string> testUserDetails(){
        Map<string,string> testUserMap = new Map<string,string>();
        string userData = 'Profile p = [SELECT Id FROM Profile WHERE Name=\'Standard User\']; \n'
                            + 'User testUser = new User(FirstName = \'Auto\', Email=\'autotestusr1@testorg.com\', \n'
                            + 'EmailEncodingKey=\'UTF-8\', LastName=\'TestUsr\', LanguageLocaleKey=\'en_US\', \n'
                            + 'LocaleSidKey=\'en_US\', ProfileId = p.Id, \n'
                            + 'TimeZoneSidKey=\'America/Los_Angeles\', UserName=\'autotestusr1@testorg.com\');\n';
        testUserMap.put('testUser', userData);
        return testUserMap;
    }
    
    private static Map<string,string> testAccountDetails(){
        Map<string,string> testAccountMap = new Map<string,string>();       
        string accountData = 'Account testAcc = new Account(Name = \'Auto Test Acc1\', AccountNumber = \'1111111\', \n'
                                + 'Description = \'Testing\', Phone = \'111111\', Website = \'Test@test.com\');';       
        testAccountMap.put('testAcc',accountData);
        return testAccountMap;
    }
    
    private static Map<string,string> testContactDetails(){
        Map<string,string> testContactMap = new Map<string,string>();
        string contactData = 'Contact testCon = new Contact(firstName = \'AutoTest\', lastName = \'Cont1\', \n'
                                + 'Department = \'Testing\', Level__c = \'Low\', Languages__c = \'English\', Title = \'Mr.\');';
        testContactMap.put('testCon',contactData);
        return testContactMap;
    }
    
    private static Map<string,string> testOpportunityDetails(){ 
        Map<string,string> testOpportunityMap = new Map<string,string>();
        string opportunityData = 'Opportunity testOpp = new Opportunity(Name = \'AutoTest Opp1\', CloseDate = system.today()+1, \n'
                                + 'MainCompetitors__c = \'Testing\', StageName = \'Prospecting\');';
        testOpportunityMap.put('testOpp',opportunityData);
        return testOpportunityMap;
    }

    public static testDataPrepWrapper getTestUser(){
        Map<string,string> testUser = testUserDetails();
        testDataPrepWrapper testUserData; 
        for(string instanceReference : testUser.keySet()){
            testUserData = new testDataPrepWrapper(instanceReference, testUser.get(instanceReference));
        }
        return testUserData;
    }
    
    public static testDataPrepWrapper getTestAccount(){
        Map<string,string> testAccount = testAccountDetails();
        testDataPrepWrapper testAccountData; 
        for(string instanceReference : testAccount.keySet()){
            testAccountData = new testDataPrepWrapper(instanceReference, testAccount.get(instanceReference));
        }
        return testAccountData;
    }
    
    public static testDataPrepWrapper getTestOpportunity(){
        Map<string,string> testOpportunity = testOpportunityDetails();
        testDataPrepWrapper testOpportunityData; 
        for(string instanceReference : testOpportunity.keySet()){
            testOpportunityData = new testDataPrepWrapper(instanceReference, testOpportunity.get(instanceReference));
        }
        return testOpportunityData;
    }
            
    public static testDataPrepWrapper getTestContact(){
        Map<string,string> testContact = testContactDetails();
        testDataPrepWrapper testContactData; 
        for(string instanceReference : testContact.keySet()){
            testContactData = new testDataPrepWrapper(instanceReference, testContact.get(instanceReference));
        }
        return testContactData;
    }
    
    public class testDataPrepWrapper{
        public string objectReference;
        public string objectData;
        public testDataPrepWrapper(string objectReference, string objectData){
            this.objectReference = objectReference;
            this.objectData = objectData;
        }
    }
}