//
//  YodleMIME.swift
//  
//
//  Created by Linus Bohle on 14.06.22.
//

import Foundation
import NIOCore

@resultBuilder
private struct YodleMIMEBodyBuilder {
    typealias Component = MIMEEncodable
    
    static func buildBlock(_ components: Component...) -> Component {
        return MIMEMultipartContainer(descendants: Array(components))
    }
}

protocol MIMEEncodable {
    func encode() -> String
    var mimeHeaders: [String: String] { get set }
}

enum MIMEEncoding {
    case base64
    case quotedPritable
}

struct MIMEMultipartContainer: MIMEEncodable {
    let descendants: [MIMEEncodable]
    let divider: String = ""
    var mimeHeaders: [String: String] = [:]
    
    init(descendants: [MIMEEncodable]) {
        self.descendants = descendants
    }
    
    func encode() -> String {
        
        fatalError("Function does not yet properly encode the data according to RFC.")
        
//        var outputString: String = ""
        
//        outputString.append(mimeHeaders.encodedToMIMEHeaders())
//        outputString.append("\r\n")
//        outputString.append(descendants.map { $0.encode() }.joined(separator: "\n\(divider)\n"))
//
//        return outputString
    }
}

struct MIMEBodyPart: MIMEEncodable {
    // default struct for all MIME body parts
    let data: Data
    let encoding: MIMEEncoding
    var mimeHeaders: [String: String]
    
    private var encodedHeaderValues: String {
        mimeHeaders.map { "\($0): \($1)\r\n" }.joined()
    }
    
    func encode() -> String {
        switch encoding {
        case .base64:
            return encodeToBase64()
        case .quotedPritable:
            return encodeToQuotedPrintable()
        }
    }
    
    // https://www.rfc-editor.org/rfc/rfc2045#section-6.8, https://docs.microsoft.com/en-us/previous-versions/office/developer/exchange-server-2010/aa494254(v=exchg.140)
    func encodeToBase64() -> String {
        // make sure that content transfer encoding is correct, and override if necessary
        let headers = self.mimeHeaders.merging(["Content-Transfer-Encoding": "base64"]) { _, new in new }
        var outputString: String = ""
        
        outputString.append(headers.encodedToMIMEHeaders())
        outputString.append("\r\n")
        outputString.append(data.base64EncodedString(options: [.lineLength76Characters, .endLineWithCarriageReturn, .endLineWithLineFeed]))
        return outputString
    }
    
    // https://www.rfc-editor.org/rfc/rfc2045#section-6.7
    func encodeToQuotedPrintable() -> String {
        let headers = self.mimeHeaders.merging(["Content-Transfer-Encoding": "Quoted-Printable"]) { _, new in new }
        
        var outputString: String = ""
        
        outputString.append(headers.encodedToMIMEHeaders())
        outputString.append("\r\n")
        
        // TODO: perform actual encoding
        fatalError("Not yet implemented.")
    }
}

class MIMEMail: Mail, SMTPEncodableMail {
    var mimeBody: MIMEEncodable? = nil
    
    func encodedBodyData() -> String? {
        mimeBody?.encode()
    }
}

func container(withHeaders headers: [String: String], @YodleMIMEBodyBuilder containers: () -> MIMEEncodable) -> MIMEEncodable {
    var container = containers()
    container.mimeHeaders = headers
    return container
}
