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
