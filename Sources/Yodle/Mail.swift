//
//  File.swift
//  
//
//  Created by Linus Bohle on 24.05.22.
//

import Foundation

// https://datatracker.ietf.org/doc/html/rfc5322
// https://datatracker.ietf.org/doc/html/rfc5321
// https://datatracker.ietf.org/doc/html/rfc822

protocol SMTPEncodableMail: Mail {
    func encodeMailData() throws -> String
}

// https://www.rfc-editor.org/rfc/rfc2045#section-6.2, https://www.rfc-editor.org/rfc/rfc4021.html#section-2.2.4
internal class Mail {
    internal let messageId: String = UUID().uuidString
    
    let sender: MailUser
    let recipients: Set<MailUser>
    
    var from: Set<MailUser>? = nil // https://serverfault.com/questions/554520/smtp-allows-for-multiple-from-addresses-in-the-rfc-was-this-ever-useful-why-do
    var cc: Set<MailUser>? = nil
    var bcc: Set<MailUser>? = nil
    
    var replyTo: Set<MailUser>? = nil
    
    var subject: String? = nil
    
    var additionalSMTPHeaders: [String: String] = [:]
    
    internal var processedSMTPHeaders: [String: String] {
        var dict: [String: String] = [:]
        
        dict["Message-Id"] = "\(messageId)@localhost"
        dict["Date"] = Date().smtpFormattedDate
        
        if let from = from {
            dict["From"] = from.compactMap{ $0.smtpFormatted }.joined(separator: ",")
        } else { dict["From"] = sender.smtpFormatted }
        
        dict["To"] = recipients.compactMap{ $0.smtpFormatted }.joined(separator: ",")
        
        if let cc = cc {
            dict["Cc"] = cc.compactMap{ $0.smtpFormatted }.joined(separator: ",")
        }
        
        if let bcc = bcc {
            dict["Bcc"] = bcc.compactMap{ $0.smtpFormatted }.joined(separator: ",")
        }
        
        if let replyTo = replyTo {
            dict["Reply-To"] = replyTo.compactMap{ $0.smtpFormatted }.joined(separator: ",")
        }
        
        if let subject = subject {
            dict["Subject"] = subject
        }
        
        // add custom headers but give priority to standardized ones
        dict.merge(additionalSMTPHeaders) { standardized, custom in
            return standardized
        }
        
        return dict
    }
    
    init(sender: MailUser, recipients: Set<MailUser>) {
        self.sender = sender
        self.recipients = recipients
    }
}

class RawTextMail: Mail, SMTPEncodableMail {
    // https://datatracker.ietf.org/doc/html/rfc5321#section-4.5.2
    var text: String? = nil
    
    // https://datatracker.ietf.org/doc/html/rfc5321#section-2.3.8
    internal func getSplitTextBody() throws -> [String] {
        guard var _text = self.text else { return [] }
        
        var lines: [String] = []
        
        while _text.count > 0 {
            
            if let range = _text.range(of: "\r\n") {
                lines.append(String(_text[..<range.lowerBound]))
                _text.removeSubrange(_text.startIndex...range.upperBound)
            } else {
                lines.append(String(_text.prefix(998)))
                _text = String(_text.dropFirst(998))
            }
        }
        
        if _text.count > 0 { lines.append(_text) }
        
        return lines
    }
    
    func encodeMailData() throws -> String {
        return try applyTransparencyMechanism().joined(separator: "\r\n")
    }
    
    // applies transparency mechanism according to https://www.rfc-editor.org/rfc/rfc5321.html#section-4.5.2
    func applyTransparencyMechanism() throws -> [String] {
        var lines = try getSplitTextBody()
        for i in 0..<lines.count {
            if lines[i].first == "." { lines[i].insert(".", at: lines[i].startIndex) }
        }
        
        return lines
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
