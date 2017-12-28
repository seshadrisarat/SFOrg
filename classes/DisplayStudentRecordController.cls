public class DisplayStudentRecordController {
    
    public boolean isEditEnabled {get; set;}
    
    public DisplayStudentRecordController() {
            isEditEnabled = false;
            //students = [select First_Name__c,Last_Name__c,Full_Name__c,Age__c,EmailID__c from Student__c];
    }
    
    public List<Student__c> students {
    get {
        if(students ==null) students = [select First_Name__c,Last_Name__c,Full_Name__c,Age__c,EmailID__c from Student__c];
        return students;
    }
     set;}
    
    
    
    
    public PageReference edit() {
            if(isEditEnabled = true) {
            }
            return null;
    }
    
    public PageReference save() {
            
            update students;
            isEditEnabled = false;
            return null;
    }
    
    public PageReference cancel() {
            return null;
    }
    
    public boolean getIsEditEnabled () {
            return isEditEnabled;
    }
}