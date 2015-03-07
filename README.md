# JSON Schema

[![Build Status](http://img.shields.io/travis/kylef/JSONSchema.swift/master.svg?style=flat)](https://travis-ci.org/kylef/JSONSchema.swift)

An implementation of [JSON Schema](http://json-schema.org/) in Swift.

## Installation

```ruby
pod 'JSONSchema'
```

## Usage

```swift
let schema = [
    "type": "object",
    "properties": [
        "name": ["type": "string"],
        "price": ["type": "number"],
    ],
]

validate(["name": "Eggs", "price": 34.99], schema)
```

## License

Mockingjay is licensed under the BSD license. See [LICENSE](LICENSE) for more
info.

