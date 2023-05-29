//
//  RawTextMail.swift
//  
//
//  Created by Linus Bohle on 30.05.23.
//

import Foundation

/// Represents raw text mail as specified by the original RFC 5321 SMTP specification. If richer email bodies are needed, use ``MIMEMail``.
public struct RawTextMail: SMTPEncodableMail {
    public var id: UUID = UUID()

    public var sender: MailUser
    public var recipients: Set<MailUser>
    public var from: Set<MailUser>? = nil
    public var cc: Set<MailUser>? = nil
    public var bcc: Set<MailUser>? = nil
    public var replyTo: Set<MailUser>? = nil
    public var subject: String? = nil
    public var additionalSMTPHeaders: [SMTPHeader] = []

    /// The raw-text to be used as the mail's body.
    var text: String

    public init(sender: MailUser, recipients: Set<MailUser>, text: String) {
        self.sender = sender
        self.recipients = recipients
        self.text = text
    }

    /// Takes the raw text body and performs line splitting to accomodate for [SMTP's maximal line length](https://datatracker.ietf.org/doc/html/rfc5321#section-4.5.3.1.6) of 998 characters (excluding CRLF). If the user already accomodated for this limitation
    /// by including CRLF sequences in appropriate places, this method will not modify the text body of the email.
    /// - Returns: The raw text body split into multiple lines.
    internal func getSplitTextBody() -> [String] {
        var textCopy = text
        var lines: [String] = []

        while textCopy.count > 0 {
            if let range = textCopy.range(of: "\r\n"), textCopy.distance(from: textCopy.startIndex, to: range.lowerBound) <= 998 { // crlf sequence must occur after 998 chars at the latest
                lines.append(String(textCopy[..<range.lowerBound]))
                textCopy.removeSubrange(textCopy.startIndex...range.upperBound)
            } else {
                lines.append(String(textCopy.prefix(998)))
                textCopy = String(textCopy.dropFirst(998))
            }
        }

        return lines
    }

    public func encodeMailData() -> String {
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
