//
//  MIMEMail.swift
//  
//
//  Created by Linus Bohle on 01.06.23.
//

import Foundation

public struct MIMEMail: SMTPEncodableMail {
    public var id: UUID = UUID()

    public var sender: MailUser
    public var recipients: Set<MailUser>
    public var from: Set<MailUser>? = nil
    public var cc: Set<MailUser>? = nil
    public var bcc: Set<MailUser>? = nil
    public var replyTo: Set<MailUser>? = nil
    public var subject: String? = nil
    public var additionalSMTPHeaders: [SMTPHeader] = [.init(header: "MIME-Version", value: "1.0")]

    /// The MIME content of the mail.
    public var mimeBody: any MIMEEncodableBodyPart

    public init(sender: MailUser, recipients: Set<MailUser>, mimeBody: any MIMEEncodableBodyPart) {
        self.sender = sender
        self.recipients = recipients
        self.mimeBody = mimeBody
    }

    public func encodeMailData() -> String {
        return mimeBody.encode()
    }
}
