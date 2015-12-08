//
//	Usage:
//		String jsonContent = '{"someKey": "someValue", "anotherKey": true, "aKeyWithObject": {"moreValues":"foo"}}';
//		Util_JSONParser parser = Util_JSONParser.createParser(jsonContent);
//
//		String value1 = parser.get('someKey').Value; // returns 'someValue'
//		String value2 = parser.get('anotherKey').Value; // returns 'true'
//		String value3 = parser.get('notPresentKey').Value; // returns Null
//		String value4 = parser.get('aKeyWithObject').get('moreValues').Value; // returns 'foo'
//		String value5 = parser.get('aKeyWithObject').Value; // returns '{"moreValues":"foo"}'

// 	NOTE: 	This class is currently agnostic to an array of objects in a JSON object.
//		  	If you request a property on one of the objects in the array, it will search through the objects
//			in the array in order and return the value the first time it finds the key.

public with sharing class Util_JSONParser {
	private String OriginalJson { get; set; }
    
    private Util_JSONParser(String jsonString) {
    	OriginalJson = jsonString;
    }
    
    public JSONField get(String key) {
    	JSONField jsonField = new JSONField(OriginalJson);
    	return jsonField.get(key);
    }
    
    public static Util_JSONParser createParser(String jsonString) {
    	return new Util_JSONParser(jsonString);
    }
    
    public static List<Util_JSONParser> parseArray(String jsonArray) {
    	if (!jsonArray.startsWith('[')) return null;
    	
    	List<Util_JSONParser> parsers = new List<Util_JSONParser>();
    	
    	JSONParser parser = JSON.createParser(jsonArray);
    	
    	String currentObject = '';
    	while (parser.nextToken() != null)
    	{
    		JSONToken currentToken = parser.getCurrentToken();
    		if (IsValue(currentToken)) {
    			// Array contains values, we only want to deal with arrays of objects.
    			return null;
    		}
    		else if (currentToken == JSONToken.START_OBJECT) { 
    			currentObject = ReadObjectAsString(parser);
    			parsers.add(Util_JSONParser.createParser(currentObject));
    			currentObject = '';
    		}
    	}
    	
    	return parsers;
    }
    
    private static String ParseNextToken(JSONParser parser) {
    	String parsedToken = '';
    	JSONToken currentToken = parser.nextToken();
    	if (IsValue(currentToken)) {
			parsedToken = parser.getText();
		}
		else if (currentToken == JSONToken.START_OBJECT) {
			parsedToken = ReadObjectAsString(parser);
		}
		else if (currentToken == JSONToken.START_ARRAY) {
			parsedToken = ReadArrayAsString(parser);
		}
		else {
			// Error: not a parseable token...
			System.debug(LoggingLevel.Error, 'Not a parseable token: ' + currentToken);
		}
		return parsedToken;
    }
    
    private static String ReadObjectAsString(JSONParser parser) {
    	String jsonObject = '{';
    	
    	while (parser.nextToken() != null) {
    		JSONToken currentToken = parser.getCurrentToken();
			if (currentToken == JSONToken.END_OBJECT) {
					break;
			}
			else if (currentToken == JSONToken.START_OBJECT) {
				jsonObject = jsonObject + ReadObjectAsString(parser) + ',';
			}
			else if (currentToken == JSONToken.START_ARRAY) {
				jsonObject = jsonObject + ReadArrayAsString(parser) + ',';
			}
			else {
    			jsonObject = jsonObject + FormatCurrentToken(parser);
			}
    	}
    	
    	return jsonObject.removeEnd(',') + '}';
    }
    
    private static String ReadArrayAsString(JSONParser parser) {
    	String jsonArray = '[';
    	
    	while (parser.nextToken() != null) {
    		JSONToken currentToken = parser.getCurrentToken();
			if (currentToken == JSONToken.END_ARRAY) {
				break;
			}
			else if (currentToken == JSONToken.START_ARRAY) {
				jsonArray = jsonArray + ReadArrayAsString(parser) + ',';
			}
			else if (currentToken == JSONToken.START_OBJECT) {
				jsonArray = jsonArray + ReadObjectAsString(parser) + ',';
			}
			else {
    			jsonArray = jsonArray + FormatCurrentToken(parser);
			}
    	}
    	
    	return jsonArray.removeEnd(',') + ']';
    }
    
    private static String FormatCurrentToken(JSONParser parser) {
    	JSONToken currentToken = parser.getCurrentToken();
    	if (currentToken == JSONToken.FIELD_NAME) {
    		return '"' + parser.getText() + '":';
    	}
    	else if (currentToken == JSONToken.VALUE_STRING) {
    		return '"' + parser.getText() + '",';
    	}
    	else if (currentToken == JSONToken.START_OBJECT || currentToken == JSONToken.START_ARRAY) {
    		return parser.getText();
    	}
    	else {
    		return parser.getText() + ',';
    	}
    }
    
    private static Boolean IsValue(JSONToken token) {
    	return token == JSONToken.VALUE_FALSE ||
    		   token == JSONToken.VALUE_NULL ||
    		   token == JSONToken.VALUE_NUMBER_FLOAT ||
    		   token == JSONToken.VALUE_NUMBER_INT ||
    		   token == JSONToken.VALUE_STRING ||
    		   token == JSONToken.VALUE_TRUE;
    }
    
    public with sharing class JSONField {
		private String JsonContent = null;
	    public String Value { get; private set; }
	    
	    public JSONField(String jsonString) {
	    	if (jsonString != null && (jsonString.startsWith('\u007B') || jsonString.startsWith('['))) {
	    		JsonContent = jsonString;
	    	}
	    	Value = null;
	    }
	    
	    private JSONField() { }
	    
	    private JSONField(String jsonString, String currentValue) {
	    	if (jsonString != null && (jsonString.startsWith('\u007B') || jsonString.startsWith('['))) {
	    		JsonContent = jsonString;
	    	}
	    	Value = currentValue;
	    }
	    
	    public JSONField get(String key) {
	    	if (JsonContent == null) return new JSONField();
	    	Value = null;
	    	JSONParser parser = JSON.createParser(JsonContent);
	    	
	    	Integer objectDepth = 0;
	    	while (parser.nextToken() != null) {
	    		JSONToken currentToken = parser.getCurrentToken();
	    		if (currentToken == JSONToken.START_OBJECT) { // The very first token will always be START_OBJECT
	    			objectDepth++;
	    		}
	    		else if (currentToken == JSONToken.END_OBJECT) {
	    			objectDepth--;
	    		}
	    		
	    		if (objectDepth == 1 && currentToken == JSONToken.FIELD_NAME && parser.getText() == key) {
	    			Value = ParseNextToken(parser);
	    			break;
	    		}
	    	}
	    	return new JSONField(Value, Value);
	    }
    }  // End nested class
}
