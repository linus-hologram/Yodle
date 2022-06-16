//
//  YodleMIME.swift
//  
//
//  Created by Linus Bohle on 14.06.22.
//

import Foundation

struct MIMEMultipartContainer {
    
}

struct MIMEBodyPart { // default struct for all MIME body parts
    let data: Data
    
    private(set) var headers: [String: String]
    
    private var encodedHeaderValues: String {
        headers.map { "\($0): \($1)\r\n" }.joined()
    }
    
    mutating func declareHeaders(@CustomHeaderBuilder headers: () -> [String: String]) {
        self.headers = headers()
    }
    
    // https://www.rfc-editor.org/rfc/rfc2045#section-6.8, https://docs.microsoft.com/en-us/previous-versions/office/developer/exchange-server-2010/aa494254(v=exchg.140)
    mutating func encodeToBase64() -> String {
        // make sure that content transfer encoding is correct, and override if necessary
        self.headers.merge(["Content-Transfer-Encoding": "base64"]) { _, new in new }
        
        var outputString: String = ""

        outputString.append(encodedHeaderValues)
        outputString.append("\r\n")
        outputString.append(data.base64EncodedString(options: [.lineLength76Characters, .endLineWithCarriageReturn, .endLineWithLineFeed]))
        
        return outputString
    }
    
    // https://www.rfc-editor.org/rfc/rfc2045#section-6.7
    mutating func encodeToQuotedPrintable() -> String {
        self.headers.merge(["Content-Transfer-Encoding": "Quoted-Printable"]) { _, new in new }
        
        var outputString: String = ""

        outputString.append(encodedHeaderValues)
        outputString.append("\r\n")
        
        // TODO: perform actual encoding
        
        return outputString
    }
}

struct MIMEData {
    var content: Data
    
    mutating func addContainer(container: MIMEMultipartContainer) {
        
    }
    
    mutating func addBodyPart(bodyPart part: MIMEBodyPart) {
        
    }
}
