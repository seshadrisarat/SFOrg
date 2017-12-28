public class myController1 {
    public String myString {get; set;}
    
    /*public String getMyString () {
        return 'getMyString';
    }*/
    
    public String getStringMethod1() {
       return myString;
    }
    public String getStringMethod2() {
       if (myString == null)
         myString = 'Method2'; 
       return myString;
    }
    
    public void noMethod(){
        
    }
}