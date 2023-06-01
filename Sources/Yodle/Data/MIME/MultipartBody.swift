//
//  MultipartBody.swift
//  
//
//  Created by Linus Bohle on 01.06.23.
//

import Foundation

@resultBuilder
private struct YodleMIMEBodyBuilder {
    typealias Component = MIMEEncodableBodyPart

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

/// The standard protocol to which all MIME body parts conform.
public protocol MIMEEncodableBodyPart {
    var additionalMIMEHeaders: [SMTPHeader] { get set }
    var contentType: MIMEType { get set }

    /// Encodes the body part's data into a string that can be interpreted by SMTP agents.
    func encode() -> String
}

public struct MIMEMultipartContainer: MIMEEncodableBodyPart {
    public var contentType: MIMEType = .multipart("mixed")
    public var additionalMIMEHeaders: [SMTPHeader]

    private let boundary: String = String((0...70).map{ _ in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/+_:().?=,-".randomElement()! }) // supported boundary characters

    @YodleMIMEBodyBuilder var descendants: () -> [MIMEEncodableBodyPart]

    public func encode() -> String {
        var outputString: String = ""

        var headers: [SMTPHeader] = []

        headers.append(SMTPHeader(header: "Content-Type", value: "\(contentType.get()); boundary=\"\(boundary)\""))

        // only add custom header if it does not conflict with standardized ones above
        for additionalHeader in additionalMIMEHeaders {
            if !headers.contains(where: { $0.header == additionalHeader.header }) {
                headers.append(additionalHeader)
            }
        }

        outputString.append(headers.encodeToSMTPHeaderString())
        outputString.append("\r\n--\(boundary)\r\n")
        outputString.append(descendants().map { $0.encode() }.joined(separator: "\r\n--\(boundary)\r\n"))
        outputString.append("\r\n--\(boundary)--\r\n")

        return outputString
    }
}
