//
//  File.swift
//  
//
//  Created by Linus Bohle on 24.05.22.
//

import Foundation

// https://datatracker.ietf.org/doc/html/rfc5322
// https://datatracker.ietf.org/doc/html/rfc5321
struct Mail {
    let messageId: String = UUID().uuidString

    let sender: MailUser
    let recipients: Set<MailUser>

    let from: Set<MailUser>? // https://serverfault.com/questions/554520/smtp-allows-for-multiple-from-addresses-in-the-rfc-was-this-ever-useful-why-do
    let cc: Set<MailUser>?
    let bcc: Set<MailUser>?
    
    let replyTo: Set<MailUser>?
    
    let subject: String?
    
    let customHeaders: [String: String]
    
    let text: String // https://datatracker.ietf.org/doc/html/rfc5321#section-4.5.2
    
    internal var headers: [String: String] {
        var dict: [String: String] = [:]
        
        dict["Message-Id"] = "\(messageId)@localhost"
        dict["Date"] = Date().smtpFormattedDate
        
        if let from = from {
            dict["From"] = from.compactMap{$0.smtpFormatted}.joined(separator: ",")
        } else { dict["From"] = sender.smtpFormatted }
        
        dict["To"] = recipients.compactMap{$0.smtpFormatted}.joined(separator: ",")
        
        if let cc = cc {
            dict["Cc"] = cc.compactMap{$0.smtpFormatted}.joined(separator: ",")
        }
        
        if let bcc = bcc {
            dict["Bcc"] = bcc.compactMap{$0.smtpFormatted}.joined(separator: ",")
        }
        
        if let replyTo = replyTo {
            dict["Reply-To"] = replyTo.compactMap{$0.smtpFormatted}.joined(separator: ",")
        }
        
        if let subject = subject {
            dict["Subject"] = subject
        }
        
        // add custom headers but give priority to standardized ones
        dict.merge(customHeaders) { standardized, custom in
            return standardized
        }
        
        return dict
    }
}

struct MailUser: Hashable {
    let name: String?
    let email: String
    
    var smtpFormatted: String {
        if let name = name {
            return "\(name) <\(email)>"
        } else {
            return email
        }
    }
}
