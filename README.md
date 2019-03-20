# DBus
Swift library for D-Bus

## Logging
This library uses IBM's HeliumLogger. If you wish to see debug logs do something like this:
```
import HeliumLogger
import LoggerAPI

HeliumLogger.use(.debug) // For even more debug replace .debug with .entry
```

## Type Notes
- DBus does not support nil values. If we encounter one in a keyed container (probably an `a{sv}`) we will simply ignore it. If we encounter it in any other context we throw an error.
- DBus does not support Floats, but it does support Doubles. Floats will automatically be converted to Doubles when encoding.
- All complex types in variants will be encoded as variants, because the alternative is untenable.
- DBus does not support Signed 8 bit integers, so they are encoded as unsigned integers in the event that they appear in a variant.

## TODO:
- Better documentation
- Revisit serial numbers
- Revisit code cleanup. We probably have some code and types that we don't really need.
- Better test harness.
- Revisit file handles (`UNIX_FD h (104)`). The [DBus specification](https://dbus.freedesktop.org/doc/dbus-specification.html) says that they are unsigned 32 bit integers, but libdbus treats them as signed 32 bit integers, which would seem to make more sense.
- Test on 32 bit platforms.
- Check for memory leaks
- Consider removing all debug logging from the Codable code, they make a lot of method calls.
- Server side DBus property support.
- DBusManager: support system bus.
- Investigate printing `DBusMessage`s - sometimes the decoding fails.

## Source code organization
- `DBus` - things that don't fit in a more specific subdirectory. Mostly higher level abstractions.
  - `Codable` - codable things that don't fit in `Decoder` or `Encoder`.
  - `Core` - Swift wrappers for libdbus types.
  - `Decoder` - implementation of the Swift `Decoder` protocol.
  - `Encoder` - implementation of the Swift `Encoder` protocol.
- `DBusClient` - a simple test client.

## Licenses
This code is licensed under the MIT license.

### Attribution
Portions of this code (the parts in the `Codable` `Decoder`, and `Encoder` directories) are based off of [MessagePack](https://github.com/Flight-School/MessagePack) by Flight-School/Read Evaluate Press:
```
Copyright 2018 Read Evaluate Press, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
