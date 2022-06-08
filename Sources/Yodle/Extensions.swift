//
//  Extensions.swift
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
}
