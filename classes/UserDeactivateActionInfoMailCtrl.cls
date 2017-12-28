public class UserDeactivateActionInfoMailCtrl {
    
    public Integer NoOfOpenAgmt {get;set;}
    public List<GroupMember> queuesList {get;set;}
    public String managerName {get;set;}
    
    public void deactivationMailInfo (User deactivatedUser){
        User userInfo = [Select Name,Email,Manager.Email,Manager.Name from User where Id = :deactivatedUser.Id].get(0);
        String managerEmailId = userInfo.Manager.Email;
        
        queuesList = [SELECT Id,Group.Name FROM GroupMember WHERE UserOrGroupId = :deactivatedUser.ID AND Group.Type = 'Queue'];
    
        NoOfOpenAgmt = 0 ;/*[SELECT count() FROM Apttus__APTS_Agreement__c WHERE 
        (Ownerid =:deactivatedUser.ID OR Legal_Owner__c = :deactivatedUser.ID OR Business_Owner__c =:deactivatedUser.ID OR Apttus__Requestor__c =:deactivatedUser.ID) 
        AND (Apttus__Status__c NOT IN ('Activated','Cancelled Request') AND Apttus__Status_Category__c NOT IN ('Cancelled','Expired'))];*/
        
        List<String> sendTo = new List<String>();
        //Create a new Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        //Set Email Template
        mail.setTemplateId('00X0m000000I6HN');
                
        if(managerEmailId != null) {
            sendTo.add(managerEmailId);
        } else {
            sendTo.add('okumar@adobe.com');
        }
        
        mail.setToAddresses(sendTo);
    
        //Set list of people who should be CC'ed
        List<String> ccTo = new List<String>();
        ccTo.add('eshanna@adobe.com');
        ccTo.add('omkar.kumar857@gmail.com');
        mail.setCcAddresses(ccTo);
        mail.setSenderDisplayName('ECM Team');
        
        
        Boolean isThisProfile = false;
        List<ID> forProfileIDList = new List<ID>();
        forProfileIDList.add('00e30000001cGpX');
        Set<ID> forProfileIDSet = new Set<ID>(forProfileIDList);
    
        if(forProfileIDSet.contains(deactivatedUser.profileID))
            isThisProfile = true;
            
            
        String groupNames;
        if(queuesList.size()>0){
            for(GroupMember el : queuesList)
                groupNames=groupNames+el.Group.Name+', ';
        }
                
    }              
}