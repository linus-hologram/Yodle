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
}

enum SMTPExtension: String {
    case STARTTLS
}

