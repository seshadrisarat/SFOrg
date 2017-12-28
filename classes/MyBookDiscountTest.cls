/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class MyBookDiscountTest {

    static @isTest /* testMethod */ void myUnitTest() {
        // TO DO: implement unit test
        Book__c book=new Book__c(Name='NewBook1',Price__c=120);
        //book.Price__c=120;
        insert book;
        System.debug(Limits.getDmlStatements());
        try {
        	Book__c testBook=[select Price__c from Book__c where name='NewBook1'];
        	Decimal testPrice=testBook.Price__c;
        	System.assertEquals(testPrice,108);
        	
        }
        catch (System.Exception e) {
        	e.getStackTraceString();
        }
    }
}