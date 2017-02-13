//
//  JSONSchemaTests.swift
//  JSONSchemaTests
//
//  Created by Kyle Fuller on 23/02/2015.
//  Copyright (c) 2015 Cocode. All rights reserved.
//

import Foundation
import XCTest
import JSONSchema

class JSONSchemaTests: XCTestCase {
  var schema:Schema!

  override func setUp() {
    super.setUp()

    schema = Schema([
      "title": "Product",
      "description": "A product from Acme's catalog",
      "type": "object",
    ])
  }

  func testTitle() {
    XCTAssertEqual(schema.title!, "Product")
  }

  func testDescription() {
    XCTAssertEqual(schema.description!, "A product from Acme's catalog")
  }

  func testType() {
    XCTAssertEqual(schema.type!, [Type.Object])
  }

  func testSuccessfulValidation() {
    XCTAssertTrue(schema.validate([String:Any]()).valid)
  }

  func testUnsuccessfulValidation() {
    XCTAssertFalse(schema.validate([String]()).valid)
  }

  func testReadme() {
    let schema = Schema([
      "type": "object",
      "properties": [
        "name": ["type": "string"],
        "price": ["type": "number"],
      ],
      "required": ["name"],
    ])

    XCTAssertTrue(schema.validate(["name": "Eggs", "price": 34.99]).valid)
    XCTAssertFalse(schema.validate(["price": 34.99]).valid)
  }

  func testAddFormat() {
    var schema = Schema([
      "type": "object",
      "properties": [
        "letters": ["type": "string", "format": "alpha"],
      ],
      "required": ["letters"],
      ])
    schema.addFormat(formatKey: "alpha") { (value) -> (ValidationResult) in
      if let str = value as? String {
        let allowedCharacters = CharacterSet.letters
        let c = str.components(separatedBy: allowedCharacters)
        let leftover = (c as NSArray).componentsJoined(by: "")
        if leftover.characters.count > 0 {
          return .invalid(["\(str) contains non-alpha characters"])
        }
        return .valid
      }

      return .valid
    }

    XCTAssertTrue(schema.validate(["letters": "HelloWorld"]).valid)
    XCTAssertFalse(schema.validate(["letters": "Hello World"]).valid)
    XCTAssertFalse(schema.validate(["letters": "hi1234"]).valid)
  }

  func testIPv4() {
    let schema = Schema([
      "type": "object",
      "properties": [
        "ip": ["type": "string", "format": "ipv4"],
      ],
      "required": ["ip"],
      ])

    XCTAssertTrue(schema.validate(["ip": "192.168.1.1"]).valid)
    XCTAssertFalse(schema.validate(["ip": "192.168.1.1.1"]).valid)
    XCTAssertFalse(schema.validate(["ip": "192.168.1000.1"]).valid)
    XCTAssertFalse(schema.validate(["ip": "192.168.x.1"]).valid)
    XCTAssertFalse(schema.validate(["ip": 192.168]).valid)

    let badSchema = Schema([
      "type": "object",
      "properties": [
        "ip": ["type": "number", "format": "ipv4"],
      ]
      ])

    XCTAssertFalse(badSchema.validate(["ip": "192.168.1.1"]).valid)
    XCTAssertFalse(badSchema.validate(["ip": 192.168]).valid)
  }

  func testIPv6() {
    let schema = Schema([
      "type": "object",
      "properties": [
        "ip": ["type": "string", "format": "ipv6"],
      ],
      "required": ["ip"],
      ])

    // Test cases here retrieved from:
    // https://www.helpsystems.com/intermapper/ipv6-test-address-validation

    XCTAssertFalse(schema.validate(["ip":""]).valid) // empty string
    XCTAssertTrue(schema.validate(["ip":"::1"]).valid) // loopback, compressed, non-routable
    XCTAssertTrue(schema.validate(["ip":"::"]).valid) // unspecified, compressed, non-routable
    XCTAssertTrue(schema.validate(["ip":"0:0:0:0:0:0:0:1"]).valid) // loopback, full
    XCTAssertTrue(schema.validate(["ip":"0:0:0:0:0:0:0:0"]).valid) // unspecified, full
    XCTAssertTrue(schema.validate(["ip":"2001:DB8:0:0:8:800:200C:417A"]).valid) // unicast, full
    XCTAssertTrue(schema.validate(["ip":"FF01:0:0:0:0:0:0:101"]).valid) // multicast, full
    XCTAssertTrue(schema.validate(["ip":"2001:DB8::8:800:200C:417A"]).valid) // unicast, compressed
    XCTAssertTrue(schema.validate(["ip":"FF01::101"]).valid) // multicast, compressed
    XCTAssertFalse(schema.validate(["ip":"2001:DB8:0:0:8:800:200C:417A:221"]).valid) // unicast, full
    XCTAssertFalse(schema.validate(["ip":"FF01::101::2"]).valid) // multicast, compressed
    XCTAssertTrue(schema.validate(["ip":"fe80::217:f2ff:fe07:ed62"]).valid)

    XCTAssertTrue(schema.validate(["ip":"2001:0000:1234:0000:0000:C1C0:ABCD:0876"]).valid)
    XCTAssertTrue(schema.validate(["ip":"3ffe:0b00:0000:0000:0001:0000:0000:000a"]).valid)
    XCTAssertTrue(schema.validate(["ip":"FF02:0000:0000:0000:0000:0000:0000:0001"]).valid)
    XCTAssertTrue(schema.validate(["ip":"0000:0000:0000:0000:0000:0000:0000:0001"]).valid)
    XCTAssertTrue(schema.validate(["ip":"0000:0000:0000:0000:0000:0000:0000:0000"]).valid)
//    fails, macOS 10.12.3
//    XCTAssertFalse(schema.validate(["ip":"02001:0000:1234:0000:0000:C1C0:ABCD:0876"]).valid)	 // extra 0 not allowed!
//    XCTAssertFalse(schema.validate(["ip":"2001:0000:1234:0000:00001:C1C0:ABCD:0876"]).valid)	 // extra 0 not allowed!

    XCTAssertTrue(schema.validate(["ip":" 2001:0000:1234:0000:0000:C1C0:ABCD:0876"]).valid)		 // leading space
    XCTAssertTrue(schema.validate(["ip":"2001:0000:1234:0000:0000:C1C0:ABCD:0876 "]).valid)		 // trailing space
    XCTAssertTrue(schema.validate(["ip":" 2001:0000:1234:0000:0000:C1C0:ABCD:0876  "]).valid)	 // leading and trailing space
    XCTAssertFalse(schema.validate(["ip":"2001:0000:1234:0000:0000:C1C0:ABCD:0876  0"]).valid)	 // junk after valid address
    XCTAssertFalse(schema.validate(["ip":"2001:0000:1234: 0000:0000:C1C0:ABCD:0876"]).valid)	 // internal space

    XCTAssertFalse(schema.validate(["ip":"3ffe:0b00:0000:0001:0000:0000:000a"]).valid)			 // seven segments
    XCTAssertFalse(schema.validate(["ip":"FF02:0000:0000:0000:0000:0000:0000:0000:0001"]).valid)	 // nine segments
    XCTAssertFalse(schema.validate(["ip":"3ffe:b00::1::a"]).valid)								 // double "::"
    XCTAssertFalse(schema.validate(["ip":"::1111:2222:3333:4444:5555:6666::"]).valid)			 // double "::"
    XCTAssertTrue(schema.validate(["ip":"2::10"]).valid)
    XCTAssertTrue(schema.validate(["ip":"ff02::1"]).valid)
    XCTAssertTrue(schema.validate(["ip":"fe80::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"2002::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"2001:db8::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"2001:0db8:1234::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::ffff:0:0"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::1"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3:4:5:6:7:8"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3:4:5:6::8"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3:4:5::8"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3:4::8"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3::8"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2::8"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1::8"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1::2:3:4:5:6:7"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1::2:3:4:5:6"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1::2:3:4:5"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1::2:3:4"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1::2:3"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1::8"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::2:3:4:5:6:7:8"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::2:3:4:5:6:7"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::2:3:4:5:6"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::2:3:4:5"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::2:3:4"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::2:3"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::8"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3:4:5:6::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3:4:5::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3:4::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3:4:5::7:8"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1:2:3::4:5::7:8"]).valid)	// Double "::"
    XCTAssertFalse(schema.validate(["ip":"12345::6:7:8"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3:4::7:8"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3::7:8"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2::7:8"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1::7:8"]).valid)

    // IPv4 addresses as dotted-quads
    XCTAssertTrue(schema.validate(["ip":"1:2:3:4:5:6:1.2.3.4"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3:4:5::1.2.3.4"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3:4::1.2.3.4"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3::1.2.3.4"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2::1.2.3.4"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1::1.2.3.4"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3:4::5:1.2.3.4"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2:3::5:1.2.3.4"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1:2::5:1.2.3.4"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1::5:1.2.3.4"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1::5:11.22.33.44"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::5:400.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::5:260.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::5:256.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::5:1.256.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::5:1.2.256.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::5:1.2.3.256"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::5:300.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::5:1.300.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::5:1.2.300.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::5:1.2.3.300"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::5:900.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::5:1.900.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::5:1.2.900.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::5:1.2.3.900"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::5:300.300.300.300"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::5:3000.30.30.30"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::400.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::260.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::256.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::1.256.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::1.2.256.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::1.2.3.256"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::300.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::1.300.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::1.2.300.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::1.2.3.300"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::900.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::1.900.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::1.2.900.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::1.2.3.900"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::300.300.300.300"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::3000.30.30.30"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::400.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::260.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::256.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::1.256.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::1.2.256.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::1.2.3.256"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::300.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::1.300.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::1.2.300.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::1.2.3.300"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::900.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::1.900.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::1.2.900.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::1.2.3.900"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::300.300.300.300"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::3000.30.30.30"]).valid)
    XCTAssertTrue(schema.validate(["ip":"fe80::217:f2ff:254.7.237.98"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::ffff:192.168.1.26"]).valid)
    XCTAssertFalse(schema.validate(["ip":"2001:1:1:1:1:1:255Z255X255Y255"]).valid)	// garbage instead of "." in IPv4
    XCTAssertFalse(schema.validate(["ip":"::ffff:192x168.1.26"]).valid)				// ditto
    XCTAssertTrue(schema.validate(["ip":"::ffff:192.168.1.1"]).valid)
    XCTAssertTrue(schema.validate(["ip":"0:0:0:0:0:0:13.1.68.3"]).valid) // IPv4-compatible IPv6 address, full, deprecated
    XCTAssertTrue(schema.validate(["ip":"0:0:0:0:0:FFFF:129.144.52.38"]).valid) // IPv4-mapped IPv6 address, full
    XCTAssertTrue(schema.validate(["ip":"::13.1.68.3"]).valid) // IPv4-compatible IPv6 address, compressed, deprecated
    XCTAssertTrue(schema.validate(["ip":"::FFFF:129.144.52.38"]).valid) // IPv4-mapped IPv6 address, compressed
    XCTAssertTrue(schema.validate(["ip":"fe80:0:0:0:204:61ff:254.157.241.86"]).valid)
    XCTAssertTrue(schema.validate(["ip":"fe80::204:61ff:254.157.241.86"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::ffff:12.34.56.78"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::ffff:2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::ffff:257.1.2.3"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1.2.3.4"]).valid)

    XCTAssertFalse(schema.validate(["ip":"1.2.3.4:1111:2222:3333:4444::5555"]).valid)   // Aeron
    XCTAssertFalse(schema.validate(["ip":"1.2.3.4:1111:2222:3333::5555"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1.2.3.4:1111:2222::5555"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1.2.3.4:1111::5555"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1.2.3.4::5555"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1.2.3.4::"]).valid)

    // Testing IPv4 addresses represented as dotted-quads
    // Leading zero's in IPv4 addresses not allowed: some systems treat the leading "0" in ".086" as the start of an octal number
    // Update: The BNF in RFC-3986 explicitly defines the dec-octet (for IPv4 addresses) not to have a leading zero
//    XCTAssertFalse(schema.validate(["ip":"fe80:0000:0000:0000:0204:61ff:254.157.241.086"]).valid) // fails, macOS 10.12.3
    XCTAssertTrue(schema.validate(["ip":"::ffff:192.0.2.128"]).valid)    // but this is OK, since there's a single digit
    XCTAssertFalse(schema.validate(["ip":"XXXX:XXXX:XXXX:XXXX:XXXX:XXXX:1.2.3.4"]).valid)
//    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:00.00.00.00"]).valid) // fails, macOS 10.12.3
//    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:000.000.000.000"]).valid) // fails, macOS 10.12.3
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:256.256.256.256"]).valid)

    // Not testing address with subnet mask
    // fails, macOS 10.12.3
//    XCTAssertTrue(schema.validate(["ip":"2001:0DB8:0000:CD30:0000:0000:0000:0000/60"]).valid) // full, with prefix
//    XCTAssertTrue(schema.validate(["ip":"2001:0DB8::CD30:0:0:0:0/60"]).valid) // compressed, with prefix
//    XCTAssertTrue(schema.validate(["ip":"2001:0DB8:0:CD30::/60"]).valid) // compressed, with prefix #2
//    XCTAssertTrue(schema.validate(["ip":"::/128"]).valid) // compressed, unspecified address type, non-routable
//    XCTAssertTrue(schema.validate(["ip":"::1/128"]).valid) // compressed, loopback address type, non-routable
//    XCTAssertTrue(schema.validate(["ip":"FF00::/8"]).valid) // compressed, multicast address type
//    XCTAssertTrue(schema.validate(["ip":"FE80::/10"]).valid) // compressed, link-local unicast, non-routable
//    XCTAssertTrue(schema.validate(["ip":"FEC0::/10"]).valid) // compressed, site-local unicast, deprecated
//    XCTAssertFalse(schema.validate(["ip":"124.15.6.89/60"]).valid) // standard IPv4, prefix not allowed

    XCTAssertTrue(schema.validate(["ip":"fe80:0000:0000:0000:0204:61ff:fe9d:f156"]).valid)
    XCTAssertTrue(schema.validate(["ip":"fe80:0:0:0:204:61ff:fe9d:f156"]).valid)
    XCTAssertTrue(schema.validate(["ip":"fe80::204:61ff:fe9d:f156"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::1"]).valid)
    XCTAssertTrue(schema.validate(["ip":"fe80::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"fe80::1"]).valid)
    XCTAssertFalse(schema.validate(["ip":":"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::ffff:c000:280"]).valid)

    // Aeron supplied these test cases
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444::5555:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333::5555:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222::5555:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111::5555:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::5555:"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:"]).valid)
    XCTAssertFalse(schema.validate(["ip":":"]).valid)

    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444::5555"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333::5555"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222::5555"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111::5555"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::5555"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::"]).valid)


    // Additional test cases
    // from http://rt.cpan.org/Public/Bug/Display.html?id=50693

    XCTAssertTrue(schema.validate(["ip":"2001:0db8:85a3:0000:0000:8a2e:0370:7334"]).valid)
    XCTAssertTrue(schema.validate(["ip":"2001:db8:85a3:0:0:8a2e:370:7334"]).valid)
    XCTAssertTrue(schema.validate(["ip":"2001:db8:85a3::8a2e:370:7334"]).valid)
    XCTAssertTrue(schema.validate(["ip":"2001:0db8:0000:0000:0000:0000:1428:57ab"]).valid)
    XCTAssertTrue(schema.validate(["ip":"2001:0db8:0000:0000:0000::1428:57ab"]).valid)
    XCTAssertTrue(schema.validate(["ip":"2001:0db8:0:0:0:0:1428:57ab"]).valid)
    XCTAssertTrue(schema.validate(["ip":"2001:0db8:0:0::1428:57ab"]).valid)
    XCTAssertTrue(schema.validate(["ip":"2001:0db8::1428:57ab"]).valid)
    XCTAssertTrue(schema.validate(["ip":"2001:db8::1428:57ab"]).valid)
    XCTAssertTrue(schema.validate(["ip":"0000:0000:0000:0000:0000:0000:0000:0001"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::1"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::ffff:0c22:384e"]).valid)
    XCTAssertTrue(schema.validate(["ip":"2001:0db8:1234:0000:0000:0000:0000:0000"]).valid)
    XCTAssertTrue(schema.validate(["ip":"2001:0db8:1234:ffff:ffff:ffff:ffff:ffff"]).valid)
    XCTAssertTrue(schema.validate(["ip":"2001:db8:a::123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"fe80::"]).valid)

    XCTAssertFalse(schema.validate(["ip":"123"]).valid)
    XCTAssertFalse(schema.validate(["ip":"ldkfj"]).valid)
    XCTAssertFalse(schema.validate(["ip":"2001::FFD3::57ab"]).valid)
    XCTAssertFalse(schema.validate(["ip":"2001:db8:85a3::8a2e:37023:7334"]).valid)
    XCTAssertFalse(schema.validate(["ip":"2001:db8:85a3::8a2e:370k:7334"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1:2:3:4:5:6:7:8:9"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1::2::3"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1:::3:4:5"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1:2:3::4:5:6:7:8:9"]).valid)

    // New from Aeron
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:7777::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333:4444:5555:6666::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333:4444:5555::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333:4444::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111::"]).valid)
    // XCTAssertTrue(schema.validate(["ip":"::"]).valid)     #duplicate
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333:4444:5555:6666::8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333:4444:5555::8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333:4444::8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333::8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222::8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111::8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333:4444:5555::7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333:4444::7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333::7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222::7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111::7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333:4444::6666:7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333::6666:7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222::6666:7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111::6666:7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::6666:7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333::5555:6666:7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222::5555:6666:7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111::5555:6666:7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::5555:6666:7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222::4444:5555:6666:7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111::4444:5555:6666:7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::4444:5555:6666:7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111::3333:4444:5555:6666:7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::3333:4444:5555:6666:7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::2222:3333:4444:5555:6666:7777:8888"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333:4444:5555::123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333:4444::123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333::123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222::123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111::123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333:4444::6666:123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333::6666:123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222::6666:123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111::6666:123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::6666:123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222:3333::5555:6666:123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222::5555:6666:123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111::5555:6666:123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::5555:6666:123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111:2222::4444:5555:6666:123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111::4444:5555:6666:123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::4444:5555:6666:123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"1111::3333:4444:5555:6666:123.123.123.123"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::2222:3333:4444:5555:6666:123.123.123.123"]).valid)

    // Playing with combinations of "0" and "::"
    // NB: these are all sytactically correct, but are bad form
    //   because "0" adjacent to "::" should be combined into "::"
    XCTAssertTrue(schema.validate(["ip":"::0:0:0:0:0:0:0"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::0:0:0:0:0:0"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::0:0:0:0:0"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::0:0:0:0"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::0:0:0"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::0:0"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::0"]).valid)
    XCTAssertTrue(schema.validate(["ip":"0:0:0:0:0:0:0::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"0:0:0:0:0:0::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"0:0:0:0:0::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"0:0:0:0::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"0:0:0::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"0:0::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"0::"]).valid)

    // New invalid from Aeron
    // Invalid data
    XCTAssertFalse(schema.validate(["ip":"XXXX:XXXX:XXXX:XXXX:XXXX:XXXX:XXXX:XXXX"]).valid)

    // Too many components
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:7777:8888:9999"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:7777:8888::"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::2222:3333:4444:5555:6666:7777:8888:9999"]).valid)

    // Too few components
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:7777"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111"]).valid)

    // Missing :
    XCTAssertFalse(schema.validate(["ip":"11112222:3333:4444:5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:22223333:4444:5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:33334444:5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:44445555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:55556666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:66667777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:77778888"]).valid)

    // Missing : intended for ::
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:7777:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:"]).valid)
    XCTAssertFalse(schema.validate(["ip":":"]).valid)
    XCTAssertFalse(schema.validate(["ip":":8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":4444:5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":3333:4444:5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":2222:3333:4444:5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444:5555:6666:7777:8888"]).valid)

    // :::
    XCTAssertFalse(schema.validate(["ip":":::2222:3333:4444:5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:::3333:4444:5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:::4444:5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:::5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:::6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:::7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:::8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:7777:::"]).valid)

    // Double ::"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::2222::4444:5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::2222:3333::5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::2222:3333:4444::6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::2222:3333:4444:5555::7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::2222:3333:4444:5555:7777::8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::2222:3333:4444:5555:7777:8888::"]).valid)

    XCTAssertFalse(schema.validate(["ip":"1111::3333::5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111::3333:4444::6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111::3333:4444:5555::7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111::3333:4444:5555:6666::8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111::3333:4444:5555:6666:7777::"]).valid)

    XCTAssertFalse(schema.validate(["ip":"1111:2222::4444::6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222::4444:5555::7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222::4444:5555:6666::8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222::4444:5555:6666:7777::"]).valid)

    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333::5555::7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333::5555:6666::8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333::5555:6666:7777::"]).valid)

    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444::6666::8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444::6666:7777::"]).valid)

    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555::7777::"]).valid)


    // Too many components"
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:7777:8888:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:7777:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666::1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::2222:3333:4444:5555:6666:7777:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:1.2.3.4.5"]).valid)

    // Too few components
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1.2.3.4"]).valid)

    // Missing :
    XCTAssertFalse(schema.validate(["ip":"11112222:3333:4444:5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:22223333:4444:5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:33334444:5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:44445555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:55556666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:66661.2.3.4"]).valid)

    // Missing .
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:255255.255.255"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:255.255255.255"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:255.255.255255"]).valid)

    // Missing : intended for ::
    XCTAssertFalse(schema.validate(["ip":":1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":4444:5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":3333:4444:5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":2222:3333:4444:5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444:5555:6666:1.2.3.4"]).valid)

    // :::
    XCTAssertFalse(schema.validate(["ip":":::2222:3333:4444:5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:::3333:4444:5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:::4444:5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:::5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:::6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:::1.2.3.4"]).valid)

    // Double ::
    XCTAssertFalse(schema.validate(["ip":"::2222::4444:5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::2222:3333::5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::2222:3333:4444::6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::2222:3333:4444:5555::1.2.3.4"]).valid)

    XCTAssertFalse(schema.validate(["ip":"1111::3333::5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111::3333:4444::6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111::3333:4444:5555::1.2.3.4"]).valid)

    XCTAssertFalse(schema.validate(["ip":"1111:2222::4444::6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222::4444:5555::1.2.3.4"]).valid)

    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333::5555::1.2.3.4"]).valid)

    // Missing parts
    XCTAssertFalse(schema.validate(["ip":"::."]).valid)
    XCTAssertFalse(schema.validate(["ip":"::.."]).valid)
    XCTAssertFalse(schema.validate(["ip":"::..."]).valid)
    XCTAssertFalse(schema.validate(["ip":"::1..."]).valid)
    XCTAssertFalse(schema.validate(["ip":"::1.2.."]).valid)
    XCTAssertFalse(schema.validate(["ip":"::1.2.3."]).valid)
    XCTAssertFalse(schema.validate(["ip":"::.2.."]).valid)
    XCTAssertFalse(schema.validate(["ip":"::.2.3."]).valid)
    XCTAssertFalse(schema.validate(["ip":"::.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::..3."]).valid)
    XCTAssertFalse(schema.validate(["ip":"::..3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::...4"]).valid)

    // Extra : in front
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444:5555:6666:7777::"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444:5555:6666::"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444:5555::"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444::"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333::"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222::"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111::"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444:5555:6666::8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444:5555::8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444::8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333::8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222::8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111::8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444:5555::7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444::7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333::7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222::7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111::7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444::6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333::6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222::6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111::6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333::5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222::5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111::5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222::4444:5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111::4444:5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::4444:5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111::3333:4444:5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::3333:4444:5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::2222:3333:4444:5555:6666:7777:8888"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444:5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444:5555::1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444::1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333::1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222::1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111::1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333:4444::6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333::6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222::6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111::6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222:3333::5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222::5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111::5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111:2222::4444:5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111::4444:5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::4444:5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":1111::3333:4444:5555:6666:1.2.3.4"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::2222:3333:4444:5555:6666:1.2.3.4"]).valid)

    // Extra : at end
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:7777:::"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666:::"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:::"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:::"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:::"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:::"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:::"]).valid)
    XCTAssertFalse(schema.validate(["ip":":::"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555:6666::8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555::8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444::8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333::8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222::8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111::8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444:5555::7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444::7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333::7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222::7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111::7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333:4444::6666:7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333::6666:7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222::6666:7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111::6666:7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::6666:7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222:3333::5555:6666:7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222::5555:6666:7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111::5555:6666:7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::5555:6666:7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111:2222::4444:5555:6666:7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111::4444:5555:6666:7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::4444:5555:6666:7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"1111::3333:4444:5555:6666:7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::3333:4444:5555:6666:7777:8888:"]).valid)
    XCTAssertFalse(schema.validate(["ip":"::2222:3333:4444:5555:6666:7777:8888:"]).valid)
    
    // Additional cases: http://crisp.tweakblogs.net/blog/2031/ipv6-validation-%28and-caveats%29.html
    XCTAssertTrue(schema.validate(["ip":"0:a:b:c:d:e:f::"]).valid)
    XCTAssertTrue(schema.validate(["ip":"::0:a:b:c:d:e:f"]).valid)  // syntactically correct, but bad form (::0:... could be combined)
    XCTAssertTrue(schema.validate(["ip":"a:b:c:d:e:f:0::"]).valid)
    XCTAssertFalse(schema.validate(["ip":"':10.0.0.1"]).valid)

  }
}
