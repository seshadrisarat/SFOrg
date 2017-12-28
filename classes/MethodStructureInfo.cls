public class MethodStructureInfo {
    
    public String methodName {get;set;}
    public String accessModifier {get;set;}
    public Boolean isStatic{get;set;}
    public String returnType{get;set;}
    public List<String> paramList{get;set;}
    public String methodType {get;set;}
    public List<String> referringClassNames {get;set;}

    public MethodStructureInfo() {
        
    }
}