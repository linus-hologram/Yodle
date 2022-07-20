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
    
    static func buildBlock(_ components: Component...) -> [Component] {
        return Array(components)
    }
    
    static func buildEither(first component: Component) -> Component {
        return component
    }
    
    static func buildEither(second component: Component) -> Component {
        return component
    }
}

protocol MIMEEncodable {
    func encode() -> String
    var mimeHeaders: [String: String] { get set }
    var contentType: MIMEType { get set }
}

enum MIMEEncoding {
    case base64
    case quotedPritable
}

enum MIMEType {
    case multipart(String)
    case image(String)
    case audio(String)
    case video(String)
    case application(String)
    case text(String)
    case font(String)
    
    case custom(String)
    
    func get() -> String {
        switch self {
        case .multipart(let subtype), .image(let subtype), .audio(let subtype), .video(let subtype), .application(let subtype), .text(let subtype), .font(let subtype):
            return String(describing: self) + "/" + subtype
        case .custom(let mimeType):
            return mimeType
        }
    }
}

public struct MIMEMultipartContainer: MIMEEncodable {
    var contentType: MIMEType = .multipart("mixed")
    let boundary: String = String((0...70).map{ _ in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/+_:().?=,-".randomElement()! }) // supported boundary characters
    var mimeHeaders: [String: String] = [:]
    @YodleMIMEBodyBuilder var descendants: () -> [MIMEEncodable]
    
    func encode() -> String {
        var outputString: String = ""
        
        // merge content type header into mime headers before next step
        let headers = mimeHeaders.merging(["Content-Type": "\(contentType.get()); boundary=\"\(boundary)\""]) { _, new in new }
        outputString.append(headers.encodeToMailHeaders())
        outputString.append("\r\n--\(boundary)\r\n")
        outputString.append(descendants().map { $0.encode() }.joined(separator: "\r\n--\(boundary)\r\n"))
        outputString.append("\r\n--\(boundary)--\r\n")
        
        return outputString
    }
}

public struct MIMEBodyPart: MIMEEncodable {
    // default struct for all MIME body parts
    let data: Data
    let encoding: MIMEEncoding
    var contentType: MIMEType
    var mimeHeaders: [String: String]
    
    func encode() -> String {
        switch encoding {
        case .base64:
            // make sure that content transfer encoding is correct, and override if necessary
            let headers = self.mimeHeaders.merging(["Content-Type": contentType.get(), "Content-Transfer-Encoding": "base64"]) { _, new in new }
            return headers.encodeToMailHeaders() + "\r\n" + encodeToBase64()
        case .quotedPritable:
            let headers = self.mimeHeaders.merging(["Content-Type": contentType.get(), "Content-Transfer-Encoding": "Quoted-Printable"]) { _, new in new }
            return headers.encodeToMailHeaders() + "\r\n" + encodeToQuotedPrintable()
        }
    }
    
    // https://www.rfc-editor.org/rfc/rfc2045#section-6.8, https://docs.microsoft.com/en-us/previous-versions/office/developer/exchange-server-2010/aa494254(v=exchg.140)
    func encodeToBase64() -> String {
        return data.base64EncodedString(options: [.lineLength76Characters, .endLineWithCarriageReturn, .endLineWithLineFeed])
    }
    
    // https://www.rfc-editor.org/rfc/rfc2045#section-6.7
    func encodeToQuotedPrintable() -> String {
        fatalError("Not yet implemented.")
    }
}

public class MIMEMail: Mail, SMTPEncodableMail {
    private(set) var mimeBody: MIMEEncodable?
    
    func encodeMailData() -> String {
        self.additionalSMTPHeaders.merge(["MIME-Version": "1.0"]) { _, new in new }
        
        var outputString: String = ""
        outputString.append(self.processedSMTPHeaders.encodeToMailHeaders())
        outputString.append("\r\n")
        
        if let mimeBody = mimeBody {
            outputString.append(mimeBody.encode())
        }
        
        return outputString
    }
}
