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

@resultBuilder
struct CustomHeaderBuilder {
    typealias HeaderDeclaration = (String, String)
    
    static func buildBlock(_ components: HeaderDeclaration...) -> [String: String] {
        return Dictionary(Array(components.compactMap({ $0 })), uniquingKeysWith: { (first, last) in last })
    }
    
    static func buildEither(first component: HeaderDeclaration) -> [String: String] {
        return Dictionary(dictionaryLiteral: component)
    }
    
    static func buildEither(second component: HeaderDeclaration) -> [String: String] {
        return Dictionary(dictionaryLiteral: component)
    }
}

// https://www.rfc-editor.org/rfc/rfc2045#section-6.2, https://www.rfc-editor.org/rfc/rfc4021.html#section-2.2.4
class Mail {
    internal let messageId: String = UUID().uuidString
    
    let sender: MailUser
    let recipients: Set<MailUser>
    
    var from: Set<MailUser>? = nil // https://serverfault.com/questions/554520/smtp-allows-for-multiple-from-addresses-in-the-rfc-was-this-ever-useful-why-do
    var cc: Set<MailUser>? = nil
    var bcc: Set<MailUser>? = nil
    
    var replyTo: Set<MailUser>? = nil
    
    var subject: String? = nil
    
    private(set) var customHeaders: [String: String] = [:]
    
    internal var headers: [String: String] {
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
        dict.merge(customHeaders) { standardized, custom in
            return standardized
        }
        
        return dict
    }
    
    init(sender: MailUser, recipients: Set<MailUser>) {
        self.sender = sender
        self.recipients = recipients
    }
    
    func declareHeaders(@CustomHeaderBuilder content: () -> [String: String]) {
        customHeaders = content()
    }
}

class RawTextMail: Mail {
    // https://datatracker.ietf.org/doc/html/rfc5321#section-4.5.2
    let text: String
    
    private var transparentTextLines: [String] {
        if self.text.count > 1000 {
            var lines: [String] = []
            var _text = self.text
            
            while _text.count > 0 {
                _text = String(_text.dropFirst(1000))
                lines.append(_text)
            }
            
            applyTransparencyMechanism(lines: &lines)
            
            return lines
        } else {
            var line = [self.text]
            applyTransparencyMechanism(lines: &line)
            return line
        }
    }
    
    init(sender: MailUser, recipients: Set<MailUser>, from: Set<MailUser>? = nil, cc: Set<MailUser>? = nil, bcc: Set<MailUser>? = nil,
         replyTo: Set<MailUser>? = nil, subject: String? = nil, message: String) {
        self.text = message
        super.init(sender: sender, recipients: recipients)
    }
    
    // applys transparency mechanism according to https://www.rfc-editor.org/rfc/rfc5321.html#section-4.5.2
    func applyTransparencyMechanism(lines: inout [String]) {
        for i in 0..<lines.count {
            if lines[i].first == "." { lines[i].insert(".", at: lines[i].startIndex) }
        }
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
