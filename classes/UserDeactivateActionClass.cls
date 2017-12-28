public with sharing class UserDeactivateActionClass {
	
    public UserDeactivateActionClass() {
		
	}

	public static void processUser(User deactivatedUser){
		List <Messaging.SingleEmailMessage> mails = prepareMail(deactivatedUser);
		ID recCaseID = sendEmail(deactivatedUser, mails);
	}

	public static List <Messaging.SingleEmailMessage> prepareMail(User deactivatedUser){

		List <Messaging.SingleEmailMessage> listSingleEmailMessages = new List <Messaging.SingleEmailMessage> ();

		EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE ID = '00X6F000001OFPG'];
		User userInfo = [Select Name,Email,Manager.Email,Manager.Name from User where Id = :deactivatedUser.Id].get(0);
		String managerEmailId = userInfo.Manager.Email;
		
		List<GroupMember> queuesList = [SELECT Id,Group.Name FROM GroupMember WHERE UserOrGroupId = :deactivatedUser.ID AND Group.Type = 'Queue'];

		/*List<Apttus__APTS_Agreement__c> agmtsList = [SELECT count() FROM Apttus__APTS_Agreement__c WHERE 
		(Ownerid =:deactivatedUser.ID OR Legal_Owner__c = :deactivatedUser.ID OR Business_Owner__c =:deactivatedUser.ID OR Apttus__Requestor__c =:deactivatedUser.ID) 
		AND (Apttus__Status__c NOT IN ('Activated','Cancelled Request') AND Apttus__Status_Category__c NOT IN ('Cancelled','Expired'))];
		*/
		Integer countOfAgmts = 0;//agmtsList.size();

		List<String> sendTo = new List<String>();
		//Create a new Email
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		//Set Email Template
		mail.setTemplateId('00X6F000001OFPG');
				
		if(managerEmailId != null) {
			sendTo.add(managerEmailId);
		} else {
			sendTo.add('okumar@adobe.com');
		}
		
		mail.setToAddresses(sendTo);

		//Set list of people who should be CC'ed
		List<String> ccTo = new List<String>();
		//ccTo.add('eshanna@adobe.com');
		ccTo.add('omkar.kumar857@gmail.com');
		ccTo.add('omkar.k1@tcs.com');
		mail.setCcAddresses(ccTo);

	
		mail.setSenderDisplayName('ECM Team');
		
		
		String subject = emailTemplate.Subject;
		
		subject = subject.replace('{!DeactivatedUserName}', userInfo.Name);
		mail.setSubject(subject);
		String htmlBody = emailTemplate.HtmlValue;
		String plainBody = emailTemplate.Body;
		

		htmlBody = htmlBody.replace('{!DeactivatedUserName}', userInfo.Name);
		plainBody = plainBody.replace('{!DeactivatedUserName}', userInfo.Name);

		htmlBody = htmlBody.replace('{!DeactivatedUserEmail}', deactivatedUser.Email);
		plainBody = plainBody.replace('{!DeactivatedUserEmail}', deactivatedUser.Email);

		htmlBody = htmlBody.replace('{!ManagerName}',userInfo.Manager.Name);
		plainBody = plainBody.replace('{!ManagerName}',userInfo.Manager.Name);

		Boolean isThisProfile = false;
		List<ID> forProfileIDList = new List<ID>();
		forProfileIDList.add('00e6F000002jjgcQAA');
		Set<ID> forProfileIDSet = new Set<ID>(forProfileIDList);

		if(forProfileIDSet.contains(deactivatedUser.profileID))
			isThisProfile = true;

		if(isThisProfile){
			htmlBody = htmlBody.replace('{!isLegalSalutation}','/Legal Ops Team');
			plainBody = plainBody.replace('{!isLegalSalutation}','/Legal Ops Team');
		}else{
			htmlBody = htmlBody.replace('{!isLegalSalutation}','');
			plainBody = plainBody.replace('{!isLegalSalutation}','');
		}

		String groupNames;
		if(queuesList.size()>0){
			for(GroupMember el : queuesList)
				groupNames=groupNames+el.Group.Name+', ';
			groupNames = groupNames.substring(0, groupNames.length()-2);
			htmlBody = htmlBody.replace('{!StatusOfAssignment}','was assigned to Queues: '+groupNames);
			plainBody = plainBody.replace('{!StatusOfAssignment}','was assigned to Queues: '+groupNames);
		}else{
			htmlBody = htmlBody.replace('{!StatusOfAssignment}','was not assigned to any Queues');
			plainBody = plainBody.replace('{!StatusOfAssignment}','was not assigned to any Queues');
		}

		if(countOfAgmts > 0){
			if(countOfAgmts == 1){
				htmlBody = htmlBody.replace('{!NoOfOpenAgmt}','is '+countOfAgmts);
				plainBody = plainBody.replace('{!NoOfOpenAgmt}','is '+countOfAgmts);
			}else{
				htmlBody = htmlBody.replace('{!NoOfOpenAgmt}','are around '+countOfAgmts);
				plainBody = plainBody.replace('{!NoOfOpenAgmt}','are around '+countOfAgmts);
			}
		}else{
			htmlBody = htmlBody.replace('{!NoOfOpenAgmt}','is no');
			plainBody = plainBody.replace('{!NoOfOpenAgmt}','is no');
		}

		System.debug(plainBody);
		mail.setHtmlBody(htmlBody);
		mail.setSaveAsActivity(false);
		mail.setPlainTextBody(plainBody);
		listSingleEmailMessages.add(mail);

		return listSingleEmailMessages;
	}

	public static ID sendEmail(User deactivatedUser, List <Messaging.SingleEmailMessage> listSingleEmailMessages) {
		ID caseRecId =null;
		List <Messaging.SendEmailResult> listEmailResult = null;
			if (!Test.isRunningTest() && listSingleEmailMessages.size()>0)
				listEmailResult = Messaging.sendEmail(listSingleEmailMessages);

			if(listEmailResult.size()>0 && listEmailResult.get(0).isSuccess()){
				//caseRecId = createCase(deactivatedUser.Name);
			}
			return caseRecId;
	}

	public static ID createCase(String name){

		Case caseRecord = new Case();

        caseRecord.Subject = 'Deactivation of User '+name+' ';
        caseRecord.OwnerId = '0056F000006vXEe';
        caseRecord.Priority = 'P3- Med Impact';
        caseRecord.Status = 'Submitted';  
        caseRecord.Description = 'User deactivation track';

        insert caseRecord;

        return caseRecord.ID;
	}
}