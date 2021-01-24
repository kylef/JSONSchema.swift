//
//  JSONSchemaValidatorHelper.swift
//
//  Created by Geert Michiels on 24/01/2021.
//

import Foundation
import JSONSchema
import Combine

struct JSONSchemaValidatorHelper {
    
    private var fetchSchemaCancellable : AnyCancellable?
    
    ///loads the json schema from the specified url (using combine framework aka publishers)
    mutating func loadJsonSchema(url: URL, completion: @escaping ([String: Any]?) -> Void) {
        fetchSchemaCancellable = URLSession.shared.dataTaskPublisher(for: url)
            //after receiving the data from the load, convert it to jsonObject that is representing our schema
            .map { data, urlResponse in
                try? JSONSerialization.jsonObject(with: data, options: [])
            }
            //don't care about the url loading errors, just return nil schema if this happens
            .replaceError(with: nil)
            //go and call ourpassed in completion handler when finished
            .sink { value in
                completion(value as? [String:Any])
            }
    }
    
    ///converts the specified encodable object to json and validates it agains the specified schema url
    mutating func validate<Object>(encodableObject: Object, againstSchemaUrl schemaUrl: URL, completion: @escaping (ValidationResult?) -> Void ) where  Object: Encodable {
        //first load our schema
        loadJsonSchema(url: schemaUrl) { schema in
            //check schema loaded successfully
            guard let schema = schema else {
                completion(ValidationResult.invalid(["Could not schema"]))
                return
            }
            //convert our object to json
            guard let jsonData   = (try? JSONEncoder().encode(encodableObject)),
                  let jsonEquivalentFoundationObjects = (try? JSONSerialization.jsonObject(with: jsonData, options: [])) else {
                completion(ValidationResult.invalid(["Could not convert 'encodableObject' to json equivalent foundation objects"]))
                return
            }
            //perform validation and let our completion handler know the result
            completion(JSONSchema.validate(jsonEquivalentFoundationObjects, schema: schema))
        }
    }
    
}
