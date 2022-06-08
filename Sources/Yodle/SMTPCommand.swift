//
//  SMTPCommand.swift
//  
//
//  Created by Linus Bohle on 18.04.22.
//

import Foundation

enum SMTPCommand {
    // Initial greeting commands
    case Helo(hostname: String)
    case Ehlo(hostname: String)
    
    // Mail Commands
    case StartMail(String)
    case Recipient(String)
    case StartMailData
    case MailData(Mail)
    
    case Reset
    case Verify(String)
    case Expand(String)
    
    case Help(String?)
    case Noop(String?)
    
    case Quit
    
    // Extensions
    case StartTLS
    case XOAuth2(username: String, token: String)
}

enum SMTPExtension: String, CaseIterable {
    case STARTTLS
    case EIGHTBITMIME = "8BITMIME"
    case AUTH
}

// https://www.iana.org/assignments/sasl-mechanisms/sasl-mechanisms.xhtml
// https://datatracker.ietf.org/doc/html/rfc4422#section-1.3
enum SASLMethods: String {
    case XOAUTH2 // https://developers.google.com/gmail/imap/xoauth2-protocol https://docs.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth
    case LOGIN
    case PLAIN
    case CRAMMD5
}

