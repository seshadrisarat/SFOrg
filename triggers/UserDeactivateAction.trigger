trigger UserDeactivateAction on User (after update) {
	
	for(User oldUser : Trigger.old){
		for (User newUser : Trigger.new) {
		    if (oldUser.ID == newUser.ID && oldUser.IsActive == true && newUser.IsActive == false && newUser.Email != null && newUser.FirstName != null) {
				UserDeactivateActionClass.processUser(newUser);
			}
		}
	}


}