# JSON Schema

[![Build Status](http://img.shields.io/travis/kylef/JSONSchema.swift/master.svg?style=flat)](https://travis-ci.org/kylef/JSONSchema.swift)

An implementation of [JSON Schema](http://json-schema.org/) in Swift.

## Installation

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
])

schema.validate(["name": "Eggs", "price": 34.99])
```

JSONSchema has full support for the draft4 of the specification. It does not
yet support remote referencing #9.

## License

JSONSchema is licensed under the BSD license. See [LICENSE](LICENSE) for more
info.

