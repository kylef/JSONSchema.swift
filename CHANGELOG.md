# JSONSchema Changelog

## Master

### Breaking Changes

- Support for Swift <= 4.2 was removed.
- `ValidationResult.Valid` was renamed to `ValidationResult.valid`.

### Enhancements

- `uri` format is now validated.
- Support for Swift 4 and 5.

### Bug Fixes

- Fixes cases where schemas containing an `enum` with a boolean or number may
  be incorrectly matched against values which are boolean or numbers.

  For example, `{ "enum": [1] }` incorrectly validated with values of `true`
  and vice-versa.

- Added support for referencing parts using escaped `~` and `/`.

## 0.3.0

### Enhancements

- Adds support for Swift 2.2.
- Adds support for Swift Package Manager.
