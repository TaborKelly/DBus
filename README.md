# DBus
Swift library for D-Bus

## Notes
- DBus does not support nil values. If we encounter one in a keyed container (probably an `a{sv}`) we will simply ignore it. If we encounter it in any other context we throw an error. Perhaps this could be relaxed in some circumstances (like an `av`).
- DBus does not support Floats, but it does support Doubles. Floats will automatically be converted to Doubles when encoding.

## TODO:
- Complete Encodable support.
- Decodable support.
- Server side support.
- Better test harness.

## Licenses
Portions of this code (`AnyCodingKey.wift`, `Encoder.swift`, and `SingleValueEncodingContainer.wift`) are based off of [MessagePack](https://github.com/Flight-School/MessagePack) by Flight-School/Read Evaluate Press:
```
Copyright 2018 Read Evaluate Press, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
