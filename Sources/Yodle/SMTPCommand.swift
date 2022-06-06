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
}

enum SMTPResponseType: Equatable {
    // per https://datatracker.ietf.org/doc/html/rfc5321#section-4.2.1
    case Positive(SMTPResponse) // 2XX
    case IntermediatePositive(SMTPResponse) // 3XX
    case TransientNegative(SMTPResponse) // 4XX
    case PermanentNegative(SMTPResponse) // 5XX
}

enum SMTPResponseStatus: Int {
    case commandOK = 250
}

struct SMTPResponse: Equatable {
    let code: Int
    let message: String
    
    var responseType: SMTPResponseType {
        get {
            let stringRepresentation = String(code)
            
            if stringRepresentation.hasPrefix("2") { return .Positive(self) }
            else if stringRepresentation.hasPrefix("3") { return .IntermediatePositive(self)}
            else if stringRepresentation.hasPrefix("4") { return .TransientNegative(self)}
            else { return .PermanentNegative(self)}
        }
    }
    
}

extension Array where Element == SMTPResponse {
    func expectResponseStatus(codes: SMTPResponseStatus...) throws {
        guard let firstElement = self.first else { throw YodleError.ResponseMissing }
        guard codes.contains(where: { $0.rawValue == firstElement.code }) else { throw YodleError.ResponseNotOkay(firstElement) }
    }
    
    func expectResponseType(types: SMTPResponseType...) throws {
        guard let firstElement = self.first else { throw YodleError.ResponseMissing }
        guard types.contains(where: { $0 == firstElement.responseType }) else { throw YodleError.ResponseNotOkay(firstElement) }
    }
}
