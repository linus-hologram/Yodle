//
//  Helper.swift
//  
//
//  Created by Linus Bohle on 25.05.22.
//

import Foundation

extension Date {
    var smtpFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss ZZZ"
        return formatter.string(from: self)
    }
}

extension String {
    var base64Encoded: String {
        Data(utf8).base64EncodedString()
    }
    
    var base64Decoded: String? {
        guard let decodedData = Data(base64Encoded: self) else { return nil }
        return String(data: decodedData, encoding: .utf8)
    }
}

extension Dictionary where Key == String, Value == String {
    func encodedToMIMEHeaders() -> String {
        return self.map { "\($0): \($1)\r\n" }.joined()
    }
}
