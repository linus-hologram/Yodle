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

extension Sequence where Element == SMTPHeader {
    /// Encodes the given Array of ``SMTPHeader``'s to a CRLF separated string for submission to an SMTP server.
    func encodeToSMTPHeaderString() -> String {
        return self.map { "\($0.header): \($0.value)\r\n" }.joined()
    }
}
