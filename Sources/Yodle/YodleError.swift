//
//  YodleError.swift
//  
//
//  Created by Linus Bohle on 30.05.22.
//

import Foundation

enum YodleError: Error {
    case Disconnected
    case InvalidResponseCode(String?)
    case InvalidResponse(String?)
}
