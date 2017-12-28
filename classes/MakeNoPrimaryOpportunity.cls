public class MakeNoPrimaryOpportunity {
    public void makeNoPrimary(List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            if(opp.IsPrimary__c == true)
                opp.IsPrimary__c=false;
        }
        update opps;
    }
}