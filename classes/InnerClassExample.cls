public with sharing class InnerClassExample {
	public InnerClassExample() {
		
	}
	public class InnerClass {
		public String xyz {get;set;}
		public void innerSampleMethod(){
			System.debug('Sample Inner Method -- Success');
		}
	}

	public class AnotherInnerClass {
		public String abc {get;set;}
		public void innerSampleMethod(){
			System.debug('Sample Inner Method -- Success');
		}
	}

	public static void sampleMethod(){
		InnerClass ic = new InnerClass();
		ic.innerSampleMethod();
	}

	public static void anotherSampleMethod(){
		Map < ID, String []> amap = new Map <ID, String[] > ();
		String[ ] xyz = new String[]{};
	}
}