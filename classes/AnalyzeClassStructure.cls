public class AnalyzeClassStructure {
	
	/*
	public static Map<String,List<MethodRefInfo>> getAllClassDetails() {
		Map<String,List<MethodRefInfo>> classDetails = new Map<String,List<MethodRefInfo>> ();
		System.debug('BreakPoint');
		List<ApexClass> classes = [select Id,name,body from ApexClass];
		List<MethodRefInfo> ListOfTokens=new List<MethodRefInfo> ();
		System.debug('BreakPoint');
		for(ApexClass elementClass : classes) {
			ListOfTokens=definedMethodsScanner(elementClass.body);
			classDetails.put(elementClass.name,ListOfTokens);
		}
		return classDetails;
	}
	*/

	public static List<MethodStructureInfo> definedMethodsScanner (String classToScan) {

		List<MethodStructureInfo> classInfoList = new List<MethodStructureInfo>();		
		MethodStructureInfo cinfo = new MethodStructureInfo();
		String patternString = '(?i)(public|protected|private)\\s*(static)?\\s*([\\w\\.\\<\\,\\>\\[\\]]*)\\s*(\\w+)\\s*\\((.*)\\)\\s*\\{';

		Pattern p = Pattern.compile(patternString);
		Matcher m = p.matcher(classToScan);
		while(m.find()) {
			cinfo.accessModifier=m.group(1);
			if(m.group(2) != null) {
				if (m.group(2).equalsIgnoreCase('static'))
					cinfo.isStatic=true;
				else
					cinfo.isStatic=false;
			}
			cinfo.returnType=m.group(3);
			cinfo.methodName=m.group(4);
			cinfo.paramList=m.group(5).split('\\,');

			classInfoList.add(cinfo);
			cinfo = new MethodStructureInfo();
		}

		return classInfoList;
	}

	public static Map<String,Map<String,List<MethodRefInfo>>> callingMethodScanner (String nameOfClass, String bodyOfClass) {
		
		Map<String,Map<String,List<MethodRefInfo>>> finalMap = new Map<String,Map<String,List<MethodRefInfo>>> ();
	    //Map<String,List<MethodRefInfo>> classRefMap = new Map<String,List<MethodRefInfo>> ();
		//List<MethodRefInfo> classInfoList = new List<MethodRefInfo>();
		ApexClass currentClass = new ApexClass();

		List<ApexClass> allClassesList = [select Name from ApexClass];
		List<String> allClassesNamesList = new List<String> ();
		for (ApexClass apx : allClassesList) {
			allClassesNamesList.add(apx.name);
			if(apx.name.equalsIgnoreCase(nameOfClass))
				currentClass = apx;
		}

		Set<String> allClassesNamesSet = new Set<String> (allClassesNamesList);
		
		String findClassNamePattern = 'class\\s+(\\w+)\\s*';
		Pattern innerClassFind = Pattern.compile(findClassNamePattern);
		Matcher innerClassMatcher = innerClassFind.matcher(bodyOfClass);
		List<String> allInnerClassesNamesList = new List<String> ();
		
		while(innerClassMatcher.find()){
			if(!innerClassMatcher.group(1).equalsIgnoreCase(currentClass.Name))
				allInnerClassesNamesList.add(innerClassMatcher.group(1));
		}
		
		System.debug(allInnerClassesNamesList);
		System.debug(allInnerClassesNamesList.size());
		
		
		String patternString = '(\\w*\\.)?(\\w*)\\.?(\\b\\w*\\b)\\s*\\(';

		Pattern p = Pattern.compile(patternString);

		Set<String> keywords1 = new Set<String> {'system','schema'};
		Set<String> keywords2 = new Set<String> {'if','for','while','do','return'};
		
		//Pattern seqMethodCallPattern = Pattern.compile('(\\w*)\\.?(\\b\\w*\\b)\\(');
		//Matcher seqMethodCallMatcher;
		
		List<MethodStructureInfo> allMethodsOfThisClass = definedMethodsScanner(bodyOfClass);
		
		List<String> methodNamesOfThisClassList = new List<String> ();
		System.debug('BreakPoint1');
		for(MethodStructureInfo el : allMethodsOfThisClass)
			methodNamesOfThisClassList.add(el.methodName.toLowerCase());

		System.debug('BreakPoint2');
		Set<String> methodNamesOfThisClassSet = new Set<String> (methodNamesOfThisClassList);
		Map<String,String> classInstanceDeclarationMap = new Map<String,String> ();
		Map<String,String> classOnlyDeclarationMap = new Map<String,String> ();
		//System.debug(methodNamesOfThisClassSet);
		//classInstanceDeclarationMap = getDeclaredSObjects(bodyOfClass);
		//System.debug(classInstanceDeclarationMap.keySet());
		//System.debug(classInstanceDeclarationMap.keySet().size());
		

		List<String> elements = new List<String> ();
		MethodRefInfo msinfo = new MethodRefInfo();

		Map<String,String> methodContentsMap= fetchMethodContent(bodyOfClass);
		
		String contentOfClassOnly=bodyOfClass;

		for(String methodNameElement : methodContentsMap.keySet()) {
			contentOfClassOnly.replace(methodContentsMap.get(methodNameElement),'');
		}

		classOnlyDeclarationMap = getDeclaredSObjects(contentOfClassOnly);
		
		Boolean methodCallInChain=false;

		for(String methodNameElement : methodContentsMap.keySet()) {

			Matcher m = p.matcher(methodContentsMap.get(methodNameElement));

			while(m.find()) {
				if(m.group(1)!=null)
					if(keywords1.contains(m.group(2).trim().toLowerCase()))
						continue;

				if(methodCallInChain && m.group(1)!=null) {
					System.debug('BP3');
					System.debug(m.group(1));
					System.debug(m.group(2));
					
					if(m.group(1).equals('.') && m.group(2).equalsIgnoreCase('get')){
						continue;
						System.debug('BP4');}
					else {
						methodCallInChain = false;
					}
					continue;
				}

				if(m.group(1)!=null && !m.group(1).equalsIgnoreCase('.')) {
					String temp = m.group(1).trim().subString(0,m.group(1).length()-1);
					temp = (temp.endsWith(']')) ? temp.split('\\[').get(0) : temp;

					if(keywords1.contains(temp.toLowerCase()))
						continue;
					else{
						//Static method call check
						if(allClassesNamesSet.contains(temp.toLowerCase())) {
							msinfo.refMethodName=methodNameElement;
							msinfo.refClassName=currentClass.Name;

							if(finalMap.containsKey(temp)) { 
									if(finalMap.get(temp).containsKey(m.group(2))) {
										Boolean isContainObj=false;
										for (MethodRefInfo mref : finalMap.get(temp).get(m.group(2))) {
											if(mref.refClassName.equalsIgnoreCase(msinfo.refClassName) && mref.refMethodName.equalsIgnoreCase(msinfo.refMethodName))
												isContainObj=true;
										}
										if(!isContainObj)
											finalMap.get(temp).get(m.group(2)).add(msinfo);
									}else{
										List<MethodRefInfo> classInfoList = New List<MethodRefInfo>();
										classInfoList.add(msinfo);
										finalMap.get(temp).put(m.group(2),classInfoList);
									} 
							}else {
								List<MethodRefInfo> classInfoList = New List<MethodRefInfo>();
								classInfoList.add(msinfo);
								Map<String,List<MethodRefInfo>> classRefMap = New Map<String,List<MethodRefInfo>>();
								classRefMap.put(m.group(2),classInfoList);
								finalMap.put(temp,classRefMap);
							}
							msinfo = new MethodRefInfo();
						}else {
							//Method calling through instance check
							if(classInstanceDeclarationMap.containsKey(temp)) {
								String temp2 = classInstanceDeclarationMap.get(temp);
								Boolean isCollection = temp2.subString(0,3).equalsIgnoreCase('set')
											|| temp2.subString(0,3).equalsIgnoreCase('map')
											|| temp2.subString(0,4).equalsIgnoreCase('list');
								if(isCollection && m.group(2).equalsIgnoreCase('get')){
									//Method calling through collection object check
									Integer i;
									for(i=temp2.length();i>=0;i--) {
										if(!temp2.substring(i-1,i).equals('>'))
											break;
									}
									i=temp2.length()-i;
									String clsName = temp2.split('\\<').get(temp2.split('\\<').size()-1);
									clsName = clsName.contains(',') ? clsName.split('\\,').get(1) : clsName;
									clsName = clsName.substring(0,clsName.length()-i);
									
									Boolean isPrimitiveType = clsName.equalsIgnoreCase('Blob')
											|| clsName.equalsIgnoreCase('Boolean')
											|| clsName.equalsIgnoreCase('Date')
											|| clsName.equalsIgnoreCase('Datetime')
											|| clsName.equalsIgnoreCase('Decimal')
											|| clsName.equalsIgnoreCase('Double')
											|| clsName.equalsIgnoreCase('ID')
											|| clsName.equalsIgnoreCase('Integer')
											|| clsName.equalsIgnoreCase('Long')
											|| clsName.equalsIgnoreCase('String')
											|| clsName.equalsIgnoreCase('Time');

									if(isPrimitiveType)
										continue;

									if(allClassesNamesSet.contains(clsName)) {
										methodCallInChain=true;
									}
								}else {
									//Method calling through class instance object check
									if(allClassesNamesSet.contains(temp2)) {
										msinfo.refMethodName=methodNameElement;
										msinfo.refClassName=currentClass.Name;

										if(finalMap.containsKey(temp2)) { 
											if(finalMap.get(temp2).containsKey(m.group(2))) {
												Boolean isContainObj=false;
												for (MethodRefInfo mref : finalMap.get(temp2).get(m.group(2))) {
													if(mref.refClassName.equalsIgnoreCase(msinfo.refClassName) && mref.refMethodName.equalsIgnoreCase(msinfo.refMethodName))
														isContainObj=true;
												}
												if(!isContainObj)
													finalMap.get(temp2).get(m.group(2)).add(msinfo);
											}else{
												List<MethodRefInfo> classInfoList = New List<MethodRefInfo>();
												classInfoList.add(msinfo);
												finalMap.get(temp2).put(m.group(2),classInfoList);
											} 
										}else {
											List<MethodRefInfo> classInfoList = New List<MethodRefInfo>();
											classInfoList.add(msinfo);
											Map<String,List<MethodRefInfo>> classRefMap = New Map<String,List<MethodRefInfo>>();
											classRefMap.put(m.group(2),classInfoList);
											finalMap.put(temp2,classRefMap);
										}
									}
								}
								msinfo = new MethodRefInfo();
							}
						}
					}
				} else{
					if(m.group(1)==null) {
						//Method of same class call check
						if(keywords2.contains(m.group(2).trim().toLowerCase()))
							continue;
						if(methodNamesOfThisClassSet.contains(m.group(2).toLowerCase())) {
							msinfo.refMethodName=methodNameElement;
							msinfo.refClassName=currentClass.Name;
							if(finalMap.containsKey(currentClass.Name)) { 
									if(finalMap.get(currentClass.Name).containsKey(m.group(2))) {
										Boolean isContainObj=false;
										for (MethodRefInfo mref : finalMap.get(currentClass.Name).get(m.group(2))) {
											if(mref.refClassName.equalsIgnoreCase(msinfo.refClassName) && mref.refMethodName.equalsIgnoreCase(msinfo.refMethodName))
												isContainObj=true;
										}
										if(!isContainObj)
											finalMap.get(currentClass.Name).get(m.group(2)).add(msinfo);
									}
									else{
										List<MethodRefInfo> classInfoList = New List<MethodRefInfo>();
										classInfoList.add(msinfo);
										finalMap.get(currentClass.Name).put(m.group(2),classInfoList);
									} 
							}else {
								List<MethodRefInfo> classInfoList = New List<MethodRefInfo>();
								classInfoList.add(msinfo);
								Map<String,List<MethodRefInfo>> classRefMap = New Map<String,List<MethodRefInfo>>();
								classRefMap.put(m.group(2),classInfoList);
								finalMap.put(currentClass.Name,classRefMap);
							}
							msinfo = new MethodRefInfo();
						}
					}else {
						
					}
				}
			}
		}
		
		return finalMap;
	}

	public static Map<String,String> getDeclaredSObjects(String classContent){

		Map<String,String> classInstanceDeclarationMap = new Map<String,String>();
        Pattern findSObjectFields = Pattern.compile('(?i)(?:public|static|final|private|global)?((?!\\bupsert\\b|\\bstring\\b|\\binteger\\b)\\s?(?:list|map|set)[\\w,.<>\\s]+\\>\\s*|[\\w,.<>]+\\s+|[\\w,.<>]+\\s*\\[\\s*\\]\\s*)([\\w]+)\\s*(?:\\=\\s*new\\s[\\w,.<>\\s\\[\\]()]+|\\=\\s*[\\w\\.]+\\([\\w.<>\\s]*\\))?\\s*(?:\\;|\\=|\\{\\s*get|\\{\\s*set)');
   		//Pattern classMemberVarFields = Pattern.compile();
   		//Pattern collectionVarFields = Pattern.compile('(?i)((?:(?:(?:set|map|list)\\s*\\<\\s*[\\w,<>]+\\s*\\,?\\s*)*[\\w,<>]+)\\s*\\>)\\s*(\\w+)\\s*(?:\\;|\\=)');

        Matcher sObjectFieldsFind = findSObjectFields.matcher(classContent);
         //while (sObjectFieldsFind.find()) {
        while(!sObjectFieldsFind.hitEnd()) {
            if(sObjectFieldsFind.find()) {
	            String className = sObjectFieldsFind.group(1).trim();
	            className = className.contains('[') ? className.replaceAll('\\[\\s*\\]','') : className;
	            String variablDecl = sObjectFieldsFind.group(2).trim();
	            Boolean isDmlStmt = className.equalsIgnoreCase('insert') || className.equalsIgnoreCase('update') || className.equalsIgnoreCase('delete') || className.equalsIgnoreCase('upsert') || className.equalsIgnoreCase('throw');
	            if(variablDecl != null && !variablDecl.startsWith('=') && !className.equalsIgnoreCase('return') && !isDmlStmt){                  
	                variablDecl = variablDecl.replaceAll('\\{(.*+)','');                
	                //system.debug('@*****----'+className+'--'+variablDecl);        
	                if(variablDecl.contains(',') && !variablDecl.contains('(')){
	                    for(String varD: variablDecl.split(',')){
	                        String variable = varD.contains('=') ? varD.split('=')[0] : varD;                        
	                        classInstanceDeclarationMap.put(variable,className);
	                    }
	                }else{
	                    //system.debug('variablDecl---'+variablDecl); 
	                    String variable = variablDecl.contains('=') ? variablDecl.split('=')[0] : variablDecl;
	                    if(!variable.contains(' ') && !variable.contains('*') && !variable.contains('+')){
	                        //system.debug('variable---'+variable); 
	                        classInstanceDeclarationMap.put(variable.trim(),className.trim());   
	                    }                   
	                }
	                classInstanceDeclarationMap.put(variablDecl,className);
	            }
	        } else
            	sObjectFieldsFind.reset(classContent);         
        }
        return classInstanceDeclarationMap;           
    }

    public static Map<String,String> fetchInnerClassContent(String classBody, String className) {
        Map<string,string> innerClassNameBodyMap = new Map<string,string>();

		String findClassNamePattern = 'class\\s+(\\w+)\\s*';
		Pattern innerClassFind = Pattern.compile(findClassNamePattern);
		Matcher innerClassMatcher = innerClassFind.matcher(classBody);
		List<String> allInnerClassesNamesList = new List<String> ();
		
		while(innerClassMatcher.find()){
			if(!innerClassMatcher.group(1).equalsIgnoreCase(className))
				allInnerClassesNamesList.add(innerClassMatcher.group(1));
		}
		System.debug(allInnerClassesNamesList);
		System.debug(allInnerClassesNamesList.size());
		for (String innerClassName : allInnerClassesNamesList) {
        	
	        String ptrn = '(?i)class\\s+' + innerClassName + '(?:\\s*[\\w\\,]+)*\\s*\\{';
	        Pattern p = Pattern.compile(ptrn);
	        Matcher m = p.matcher(classBody);
	        Integer i = 0;

	        //while(m.find()) {
	        while(!m.hitEnd()) {
	            if(m.find()) {
		        	System.debug(m.group(0));
		            i = m.end();
		        } else
		        	m.reset(classBody);
	    	}
	        if (i == 0) {
	            return null;
	        }
	        String innerClassContent = charParse(classBody.subString(i));
	        innerClassContent = innerClassContent.subString(0, innerClassContent.length() - 1);
	        innerClassNameBodyMap.put(innerClassName, innerClassContent);
	    }
        return innerClassNameBodyMap;
    }

	public static Map<String,String> fetchMethodContent(String classBody) {
        Map<string,string> methodNameBodyMap = new Map<string,string>();

        List<MethodStructureInfo> allMethodsOfThisClass = definedMethodsScanner(classBody);
		
		List<String> methodNamesOfThisClassList = new List<String> ();

		for(MethodStructureInfo el : allMethodsOfThisClass)
			methodNamesOfThisClassList.add(el.methodName);

		//System.debug(methodNamesOfThisClassList);
		for (String refMethodName : methodNamesOfThisClassList) {
        
	        String ptrn = '(?i)(?:(public|protected|private)\\s*(static)?\\s*([\\w\\.\\<\\,\\>\\[\\]]*)\\s*' + refMethodName + '\\s*\\([^\\)]*\\)\\s*\\{)';
	        Pattern p = Pattern.compile(ptrn);
	        Matcher m = p.matcher(classBody);
	        Integer i = 0;
	        while(m.find()) {
	            i = m.end();
	        }
	        if (i == 0) {
	            return null;
	        }
	        String methodContent = charParse(classBody.subString(i));
	        methodContent = methodContent.subString(0, methodContent.length() - 1);
	        methodNameBodyMap.put(refMethodName, methodContent);
	    }
        return methodNameBodyMap;
    }
	
	private static String charParse(String content) {
        String m = '';
        Integer cnt = 0;
        Boolean stringStarted = false;
        Boolean singleLineCommentStarted = false;
        Boolean multiLineCommentStarted = false;
        for (Integer i = 0; i < content.length(); i++) {
            String c = content.subString(i, i + 1);
            if (singleLineCommentStarted) {
                m += c;
                if (c == '\n') {
                    singleLineCommentStarted = false;
                }
            } else if (multiLineCommentStarted) {
                m += c;
                if (c == '*') {
                    String c1 = content.subString(i + 1, i + 2);
                    if (c1 == '/') {
                        m += c1;
                        i++;
                        multiLineCommentStarted = false;
                    }
                }
            } else if (c == '\\') {
                m += c + content.subString(++i, i + 1);
            } else if (c == '\'') {
                m += c;
                stringStarted = !stringStarted;
            } else if (stringStarted) {
                m += c;
            } else if (c == '/') {
                String c1 = content.subString(i + 1, i + 2);
                if (c1 == '/') {
                    singleLineCommentStarted = true;
                } else if (c1 == '*') {
                    multiLineCommentStarted = true;
                }
                m += c;
            } else if (c == '{') {
                m += c;
                cnt++;
            } else if (c == '}') {
                m += c;
                cnt--;
            } else {
                m += c;
            }
            if (cnt == -1) {
                break;
            }
        }
        return m;
    }
}