# SFDC-JSON-Parser
A JSON parsing abstraction built over the existing JSONParser in Salesforce to simplify extracting JSON values.

Helper class for parsing JSON content without having to serialise to a class.

Usage:
  String jsonContent = '{"someKey": "someValue", "anotherKey": true, "aKeyWithObject": {"moreValues":"foo"}}';
  Util_JSONParser parser = Util_JSONParser.createParser(jsonContent);

  String value1 = parser.get('someKey').Value; // returns 'someValue'
  String value2 = parser.get('anotherKey').Value; // returns 'true'
  String value3 = parser.get('notPresentKey').Value; // returns Null
  String value4 = parser.get('aKeyWithObject').get('moreValues').Value; // returns 'foo'
  String value5 = parser.get('aKeyWithObject').Value; // returns '{"moreValues":"foo"}'

NOTE: 	
This class is currently agnostic to an array of objects in a JSON object.
If you request a property on one of the objects in the array, it will search through the objects
in the array in order and return the value the first time it finds the key.
