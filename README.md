# JSON Schema

An implementation of [JSON Schema](http://json-schema.org/) in Swift.
Supporting JSON Schema Draft 4, 6, 7, 2019-09, 2020-12.

The JSON Schema 2019-09 and 2020-12 support are incomplete and have gaps with
some of the newer keywords.

JSONSchema.swift does not support remote referencing [#9](https://github.com/kylef/JSONSchema.swift/issues/9).

## Installation

JSONSchema can be installed via [CocoaPods](http://cocoapods.org/).

```ruby
pod 'JSONSchema'
```

## Usage

```swift
import JSONSchema

try JSONSchema.validate(["name": "Eggs", "price": 34.99], schema: [
  "type": "object",
  "properties": [
    "name": ["type": "string"],
    "price": ["type": "number"],
  ],
  "required": ["name"],
])
```

### Error handling

Validate returns an enumeration `ValidationResult` which contains all
validation errors.

```python
print(try validate(["price": 34.99], schema: ["required": ["name"]]).errors)
>>> "Required property 'name' is missing."
```

## License

JSONSchema is licensed under the BSD license. See [LICENSE](LICENSE) for more
info.

