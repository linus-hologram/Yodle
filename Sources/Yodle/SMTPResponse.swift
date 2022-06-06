//
//  SMTPResponse.swift
//  
//
//  Created by Linus Bohle on 06.06.22.
//

import Foundation

enum SMTPResponseStatus: Int {
    case commandOK = 250
    case serviceReady = 220
}

enum SMTPResponseType: Equatable {
    // per https://datatracker.ietf.org/doc/html/rfc5321#section-4.2.1
    case Positive(SMTPResponse) // 2XX
    case IntermediatePositive(SMTPResponse) // 3XX
    case TransientNegative(SMTPResponse) // 4XX
    case PermanentNegative(SMTPResponse) // 5XX
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
    
    var responseStatus: SMTPResponseStatus? {
        get {
            return SMTPResponseStatus(rawValue: code)
        }
    }
}

extension Array where Element == SMTPResponse {
    func expectResponseStatus(codes: SMTPResponseStatus..., error: YodleError? = nil) throws {
        guard let firstElement = self.first else { throw error ?? YodleError.ResponseMissing }
        guard codes.contains(where: { $0.rawValue == firstElement.code }) else { throw error ?? YodleError.ResponseNotOkay(firstElement) }
    }
    
    func expectResponseType(types: SMTPResponseType...,  error: YodleError? = nil) throws {
        guard let firstElement = self.first else { throw error ?? YodleError.ResponseMissing }
        guard types.contains(where: { $0 == firstElement.responseType }) else { throw error ?? YodleError.ResponseNotOkay(firstElement) }
    }
}
