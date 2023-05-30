//
//  Type+Encoding.swift
//  
//
//  Created by Linus Bohle on 30.05.23.
//

import Foundation

/// The encoding used for the MIME content bodies.
enum MIMEEncoding: String {
    case base64
    case quotedPritable = "Quoted-Printable"
}

/// A set of default content types used within MIME content bodies.
enum MIMEType {
    case multipart(String)
    case image(String)
    case audio(String)
    case video(String)
    case application(String)
    case text(String)
    case font(String)

    case custom(String)

    var typeDescription: String {
        var description = "\(self)"
        let subtypeRange = description.range(of: "(")!.lowerBound..<description.endIndex
        description.removeSubrange(subtypeRange)
        return description
    }

    func get() -> String {
        switch self {
        case .multipart(let subtype), .image(let subtype), .audio(let subtype), .video(let subtype), .application(let subtype), .text(let subtype), .font(let subtype):
            return typeDescription + "/" + subtype
        case .custom(let mimeType):
            return mimeType
        }
    }
}

extension MIMEType {
    /// Available dispositions relevant for use with MIME Content Bodies. See[RFC 2183](https://datatracker.ietf.org/doc/rfc2183/) for more details.
    enum Disposition: String {
        case inline
        case attachment
    }
}
