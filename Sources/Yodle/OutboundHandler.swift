//
//  OutboundHandler.swift
//  
//
//  Created by Linus Bohle on 15.05.22.
//

import Foundation
import NIOCore

class YodleOutboundHandler: MessageToByteEncoder {
    typealias OutboundIn = SMTPCommand
    
    func encode(data: SMTPCommand, out: inout ByteBuffer) throws {
        
        switch data {
        case .Helo(let hostname):
            out.writeString("HELO \(hostname)")
        case .Ehlo(let hostname):
            out.writeString("EHLO \(hostname)")
        case .StartMail(let address):
            out.writeString("MAIL FROM: <\(address)>")
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
        }
        
        out.writeString("\r\n")
        fatalError("not yet implemented")
    }
}
