import Foundation
import Leaf

enum FormatDoubleTagError: Error {
    case invalidFormatParameter
    case notTwoParameters
}

struct FormatDoubleTag: LeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        let format: String
        let value: Double
        switch ctx.parameters.count {
        case 2:
            guard let string = ctx.parameters[0].string else {
                print("0 not string. \(ctx.parameters[0])")
                throw FormatDoubleTagError.invalidFormatParameter
            }
            format = string
            guard let double = ctx.parameters[1].double else {
                print("1 not double. \(ctx.parameters[1].description)")
                throw FormatDoubleTagError.invalidFormatParameter
            }
            value = double
        default:
            throw FormatDoubleTagError.notTwoParameters
        }

        return LeafData.string(String(format: format, value))
    }
}
