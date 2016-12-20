# JSON Schema

An implementation of [JSON Schema](http://json-schema.org/) in Swift.

## Requirements

The latest version of `JSON Schema` requires Swift `3`.

If you are using Swift `2.2` then use version `0.3.0` of `JSON Schema`.

## Installation

[CocoaPods](http://cocoapods.org/) is the recommended installation method.

```ruby
pod 'JSONSchema'
```

## Usage

```swift
import JSONSchema

let schema = Schema([
    "type": "object",
    "properties": [
        "name": ["type": "string"],
        "price": ["type": "number"],
    ],
    "required": ["name"],
])

schema.validate(["name": "Eggs", "price": 34.99])
```

### Error handling

Validate returns an enumeration `ValidationResult` which contains all
validation errors.

```python
println(schema.validate(["price": 34.99]).errors)
>>> "Required property 'name' is missing."
```

JSONSchema has full support for the draft4 of the specification. It does not
yet support remote referencing [#9](https://github.com/kylef/JSONSchema.swift/issues/9).

## License

JSONSchema is licensed under the BSD license. See [LICENSE](LICENSE) for more
info.

