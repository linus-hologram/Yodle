//
//  SMTPCommand.swift
//  
//
//  Created by Linus Bohle on 18.04.22.
//

import Foundation

enum SMTPCommand {
    // Initial greeting commands
    case HELO(hostname: String)
    case EHLO(hostname: String)
}

enum SMTPResponseType { // per https://datatracker.ietf.org/doc/html/rfc5321#section-4.2.1
    case Positive(SMTPResponse) // 2XX
    case IntermediatePositive(SMTPResponse) // 3XX
    case TransientNegative(SMTPResponse) // 4XX
    case PermanentNegative(SMTPResponse) // 5XX
    
}

struct SMTPResponse {
    let code: Int
    let message: String
}
