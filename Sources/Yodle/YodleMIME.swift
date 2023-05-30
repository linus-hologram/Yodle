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
