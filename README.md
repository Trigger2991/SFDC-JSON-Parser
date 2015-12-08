# SFDC-JSON-Parser
A JSON parsing abstraction built over the existing JSONParser in Salesforce to simplify extracting values (no need to create a class to serialise to).

I built this when making many HTTP callouts to an API returning many different JSON formatted responses. I only wanted one or two values from each response so it made no send to build classes for these responses. Using the basic JSONParser in Salesforce is a nightmare iterating through the different tokens, working out where you are in the token tree.

So now you can just create this serialiser and call `get()` to find your key in the JSON object. `get()` only does a shallow scan of the parent object and always returns a `JSONField`. You then access the value from the `Value` property (`Value` is `null` if the key was not found). If your key is multiple objects deep then you can recursively call `get()` to access the key walking down the object tree. If the value for a key is an object or array then it will be returned as a string.

If your need to access an array, first return the array string from your key. Then call `Util_JSONParser.parseArray()` passing in your array as a string. This method returns a list of `Util_JSONParser`s. You can then iterate through these parsers, accessing the keys as usual.

###Usage:
```
  String jsonContent = '{"someKey": "someValue", "anotherKey": true, "aKeyWithObject": {"moreValues":"foo"}}';
  Util_JSONParser parser = Util_JSONParser.createParser(jsonContent);

  String value1 = parser.get('someKey').Value; // returns 'someValue'
  String value2 = parser.get('anotherKey').Value; // returns 'true'
  String value3 = parser.get('notPresentKey').Value; // returns Null
  String value4 = parser.get('aKeyWithObject').get('moreValues').Value; // returns 'foo'
  String value5 = parser.get('aKeyWithObject').Value; // returns '{"moreValues":"foo"}'
```

#####*NOTE:*
This class is currently agnostic to an array of objects in a JSON object.
If you request a property on one of the objects in the array, it will search through the objects
in the array in order and return the value the first time it finds the key.
