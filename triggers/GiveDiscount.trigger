trigger GiveDiscount on Book__c (before insert) {
    Book__c[] books = Trigger.new;
    MyBookDiscount.applyDiscount(books);
}