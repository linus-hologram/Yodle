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
            out.writeString(mail.combinedHeaders.encodeToSMTPHeaderString())
            out.writeString("\r\n")
            out.writeString(mail.encodeMailData())
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
        case .PlainAuth(let authorization, let authentication, let passowrd):
            out.writeString("AUTH PLAIN ")
            out.writeString("\((authorization != nil) ? authorization! : "")\("\0" + authentication + "\0" + passowrd)".base64Encoded)
        case .LoginAuth:
            out.writeString("AUTH LOGIN")
        case .LoginUser(let username):
            out.writeString(username.base64Encoded)
        case .LoginPassword(let password):
            out.writeString(password.base64Encoded)
        case .StartCramMD5Auth:
            out.writeString("AUTH CRAM-MD5")
        case .SubmitCramMD5Challenge(let username, let solvedChallenge):
            out.writeString("\(username) \(solvedChallenge)".base64Encoded)
        }
        
        out.writeString("\r\n")
    }
}
