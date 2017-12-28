trigger CheckPrimary on Opportunity (before insert, before update) {
    
    if(Trigger.isInsert || Trigger.isUpdate) {
        List<Opportunity> newOpps = new List<Opportunity>();
        newOpps=Trigger.new;
        
        //List<Opportunity> oldOpps = new List<Opportunity>();
        //oldOpps=Trigger.old;
        
        List<Opportunity> oldRec = [select Accountid,IsPrimary__c from Opportunity];

        for (Opportunity opp : oldRec) {
            if (opp.IsPrimary__c==true && opp.accountid == newOpps.get(0).accountid) {
                MakeNoPrimaryOpportunity obj=new MakeNoPrimaryOpportunity ();
                obj.makeNoPrimary(oldRec);
            }
        }
    }
    /*else {
        if(Trigger.isUpdate) {
            
        }
    }*/
}