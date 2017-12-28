public class MyBookDiscount {

    public MyBookDiscount (String name, Decimal price) {
        Book__c b=new Book__c();
        b.Name=name;
        b.Price__c=price;
        
        insert b;
    }
    
    public static void applyDiscount(Book__c[] books) {     
        for (Book__c b : books)      
            b.Price__c *= 0.9;
    }
}