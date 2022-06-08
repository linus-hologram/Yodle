//
//  OutboundHandler.swift
//  
//
//  Created by Linus Bohle on 15.05.22.
//

import Foundation
import NIOCore

class YodleOutboundHandler: MessageToByteEncoder {
    typealias OutboundIn = (SMTPCommand, [SMTPExtension])
    
    func encode(data: OutboundIn, out: inout ByteBuffer) throws {
        
        switch data.0 {
        case .Helo(let hostname):
            out.writeString("HELO \(hostname)")
        case .Ehlo(let hostname):
            out.writeString("EHLO \(hostname)")
        case .StartMail(let address):
            out.writeString("MAIL FROM: <\(address)>")
            if data.1.contains(.EIGHTBITMIME) { out.writeString(" BODY=8BITMIME")}
        case .Recipient(let address):
            out.writeString("MAIL RCPT: <\(address)>")
        case .StartMailData:
            out.writeString("DATA")
        case .MailData(let mail):
            mail.headers.forEach { (key: String, value: String) in
                out.writeString("\(key): \(value) \r\n")
            }
            out.writeString("\r\n")
            out.writeString(mail.text)
            out.writeString("\r\n.")
        case .Reset:
            out.writeString("RSET")
        case .Verify(let address):
            out.writeString("VRFY \(address)")
        case .Expand(let argument):
            out.writeString("EXPN \(argument)")
        case .Help(let argument):
            out.writeString("HELP")
            if let argument = argument {
                out.writeString(" \(argument)")
            }
        case .Noop(let argument):
            out.writeString("NOOP")
            if let argument = argument {
                out.writeString(" \(argument)")
            }
        case .Quit:
            out.writeString("QUIT")
        case .StartTLS:
            out.writeString("STARTTLS")
        case .XOAuth2(let username, let token):
            let ctrlA = String(0x01)
            out.writeString("AUTH XOAUTH2 ")
            out.writeString("user=\(username)\(ctrlA)auth=Bearer \(token + ctrlA + ctrlA)".base64Encoded)
        }
        
        out.writeString("\r\n")
    }
}
