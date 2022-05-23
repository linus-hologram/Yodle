//
//  File.swift
//  
//
//  Created by Linus Bohle on 24.05.22.
//

import Foundation

struct Mail {
    let sender: MailUser
    let text: String // https://datatracker.ietf.org/doc/html/rfc5321#section-4.5.2
}

struct MailUser {
    let name: String
    let email: String
}
