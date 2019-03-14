import CDBus

public enum DBusBasicValue {
    case byte(UInt8)
    case boolean(Bool)
    case int16(Int16)
    case uint16(UInt16)
    case int32(Int32)
    case uint32(UInt32)
    case int64(Int64)
    case uint64(UInt64)
    case double(Double)
    case fileDescriptor(UInt32)
    case string(String)
    case objectPath(String)
    case signature(String)
}

extension DBusBasicValue {
    init(_ basicValue: CDBus.DBusBasicValue, _ type: DBusType) throws {
        switch type {
        case .byte:
            self = .byte(basicValue.byt)
        case .boolean:
            self = .boolean(!(basicValue.bool_val == 0))
        case .int16:
            self = .int16(basicValue.i16)
        case .uint16:
            self = .uint16(basicValue.u16)
        case .int32:
            self = .int32(basicValue.i32)
        case .uint32:
            self = .uint32(basicValue.u32)
        case .int64:
            self = .int64(Int64(basicValue.i64))
        case .uint64:
            self = .uint64(UInt64(basicValue.u64))
        case .double:
            self = .double(basicValue.dbl)
        case .fileDescriptor:
            self = .fileDescriptor(UInt32(basicValue.fd))
        case .string:
            self = .string(String(cString: basicValue.str))
        case .objectPath:
            self = .objectPath(String(cString: basicValue.str))
        case .signature:
            self = .signature(String(cString: basicValue.str))

        default:
            throw RuntimeError.generic("DBusBasicValue.init() \(type) is not encodable as a DBusBasicValue.")
        }
    }

    init(_ string: String, _ type: DBusType) throws {
        switch type {
        case .string:
            self = .string(string)
        case .objectPath:
            self = .objectPath(string)
        case .signature:
            self = .signature(string)

        default:
            throw RuntimeError.generic("DBusBasicValue.init() \(type) can not be initialized from a string.")
        }
    }
}

extension DBusBasicValue {
    func getVariantSignature() -> String {
        switch self {
        case .byte:
            return "y"
        case .boolean:
            return "b"
        case .int16:
            return "n"
        case .uint16:
            return "q"
        case .int32:
            return "i"
        case .uint32:
            return "u"
        case .int64:
            return "x"
        case .uint64:
            return "t"
        case .double:
            return "d"
        case .fileDescriptor:
            return "h"
        case .string:
            return "s"
        case .objectPath:
            return "o"
        case .signature:
            return "g"
        }
    }

    func getType() -> DBusType {
        guard let t = DBusType.init(rawValue: getVariantSignature()) else {
            fatalError("Memory corruption in DBusBasicValue()?")
        }

        return t
    }

    func getC() throws -> CDBus.DBusBasicValue {
        switch self {
        case .byte(let v):
            return CDBus.DBusBasicValue(byt: v)
        case .boolean(let v):
            if v {
                return CDBus.DBusBasicValue(bool_val: 1)
            } else {
                return CDBus.DBusBasicValue(bool_val: 0)
            }
        case .int16(let v):
            return CDBus.DBusBasicValue(i16: v)
        case .uint16(let v):
            return CDBus.DBusBasicValue(u16: v)
        case .int32(let v):
            return CDBus.DBusBasicValue(i32: v)
        case .uint32(let v):
            return CDBus.DBusBasicValue(u32: v)
        case .int64(let v):
            return CDBus.DBusBasicValue(i64: Int(v))
        case .uint64(let v):
            return CDBus.DBusBasicValue(u64: UInt(v))
        case .double(let v):
            return CDBus.DBusBasicValue(dbl: v)
        case .fileDescriptor(let v):
            return CDBus.DBusBasicValue(fd: Int32(v))
        case .string(let v), .objectPath(let v), .signature(let v):
            return CDBus.DBusBasicValue(str: try swiftStringToCharStar(v))
        }
    }
}
