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
    /// Encodes a mail object's body properties for transport via SMTP.
    /// - Returns: A string representing the mail data
    func encodeMailData() throws -> String
}

// https://www.rfc-editor.org/rfc/rfc2045#section-6.2, https://www.rfc-editor.org/rfc/rfc4021.html#section-2.2.4


/// Root class for all Yodle SMTP mail objects. allows specification of SMTP headers and ensures they are set correctly.
public class Mail {
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

/// Represents raw text mail as specified by the original RFC 5321 SMTP specification. If you want to send richer email bodies, refer to ``MIMEMail``.
class RawTextMail: Mail, SMTPEncodableMail {
    // https://datatracker.ietf.org/doc/html/rfc5321#section-4.5.2
    var text: String? = nil
    
    /// Takes the raw text body and performs line splitting to accomodate for [SMTP's maximal line length](https://datatracker.ietf.org/doc/html/rfc5321#section-4.5.3.1.6) of 998 characters (excluding CRLF). If the user already accomodated for this limitation
    /// by including CRLF sequences in appropriate places, this method will not modify the text body of the email.
    /// - Returns: The raw text body split into multiple lines.
    internal func getSplitTextBody() -> [String] {
        guard var _text = self.text else { return [] }
        
        var lines: [String] = []
        
        while _text.count > 0 {
            if let range = _text.range(of: "\r\n"), _text.distance(from: _text.startIndex, to: range.lowerBound) <= 998 { // crlf sequence must occur after 998 chars at the latest
                lines.append(String(_text[..<range.lowerBound]))
                _text.removeSubrange(_text.startIndex...range.upperBound)
            } else {
                lines.append(String(_text.prefix(998)))
                _text = String(_text.dropFirst(998))
            }
        }

        return lines
    }
    
    
    func encodeMailData() throws -> String {
        return applyTransparencyMechanism(lines: getSplitTextBody()).joined(separator: "\r\n")
    }
        
    /// Applies the [SMTP transparency mechanism](https://www.rfc-editor.org/rfc/rfc5321.html#section-4.5.2) to avoid ending mail data transmission prematurely.
    /// - Parameter lines: the lines of mail data for which the transparency mechanism should be applied
    /// - Returns: a fully transparent list of lines which can be transmitted via SMTP
    func applyTransparencyMechanism(lines: [String]) -> [String] {
        var transparentLines = lines
        for i in 0..<transparentLines.count {
            if transparentLines[i].first == "." { transparentLines[i].insert(".", at: transparentLines[i].startIndex) }
        }
        
        return transparentLines
    }
}


/// Represents a typical SMTP mail user.
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
