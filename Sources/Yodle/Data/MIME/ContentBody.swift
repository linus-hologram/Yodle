//
//  MIMEMail.swift
//  
//
//  Created by Linus Bohle on 30.05.23.
//

import Foundation
import NIOCore

public struct MIMEContentBodyPart {
    let data: ByteBuffer
    let encoding: MIMEEncoding
    var contentType: MIMEType
    let disposition: MIMEType.Disposition? = nil

    var additionalMIMEHeaders: [SMTPHeader]

    func encode() -> String {
        var headers: [SMTPHeader] = []

        if let contentDisposition = disposition {
            headers.append(SMTPHeader(header: "Content-Disposition", value: contentDisposition.rawValue))
        }

        headers.append(SMTPHeader(header: "Content-Type", value: contentType.get()))
        headers.append(SMTPHeader(header: "Content-Transfer-Encoding", value: encoding.rawValue))

        // only add custom header if it does not conflict with standardized ones above
        for additionalHeader in additionalMIMEHeaders {
            if !headers.contains(where: { $0.header == additionalHeader.header }) {
                headers.append(additionalHeader)
            }
        }

        switch encoding {
        case .base64:
            return headers.encodeToSMTPHeaderString() + "\r\n" + encodeToBase64()
        case .quotedPritable:
            return headers.encodeToSMTPHeaderString() + "\r\n" + encodeToQuotedPrintable()
        }
    }

    // https://www.rfc-editor.org/rfc/rfc2045#section-6.8, https://docs.microsoft.com/en-us/previous-versions/office/developer/exchange-server-2010/aa494254(v=exchg.140)
    func encodeToBase64() -> String {
        return Data(data.readableBytesView).base64EncodedString(options: [.lineLength76Characters, .endLineWithCarriageReturn, .endLineWithLineFeed])
    }

    // https://www.rfc-editor.org/rfc/rfc2045#section-6.7
    private func encodeToQuotedPrintable() -> String {
        fatalError("Not yet implemented.")
    }
}
