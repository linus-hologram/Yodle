//
//  StructuralTests.swift
//  YodleTests
//
//  Created by Linus Bohle on 12.07.22.
//

import XCTest
@testable import Yodle

class StructuralTests: XCTestCase {
    
    var mail: Mail! = nil
    var rawTextMail: RawTextMail! = nil
    var mimeMail: MIMEMail! = nil
    
    var linus = MailUser(name: "Linus", email: "linus@yodle-package.com")
    var john = MailUser(name: "John", email: "john@yodle-package.com")
    var ninna = MailUser(name: "Ninna", email: "ninna@yodle-package.com")
    var anna = MailUser(name: "Anna", email: "anna@yodle-package.com")
    var lawrence = MailUser(name: "Lawrence", email: "lawrence@yodle-package.com")
    var bernhard = MailUser(name: "Bernhard", email: "bernhard@yodle-package.com")
    var susan = MailUser(name: "Susan", email: "susan@yodle-package.com")
    
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        mail = RawTextMail(sender: john, recipients: [bernhard, susan])
        rawTextMail = RawTextMail(sender: john, recipients: [bernhard, susan])
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        rawTextMail = nil
        mail = nil
        mimeMail = nil
    }
    
    func testMailUserStructure() {
        XCTAssertEqual(linus.smtpFormatted, "Linus <linus@yodle-package.com>", "MailUser smtp format incorrect.")
        XCTAssertEqual(MailUser(name: nil, email: "robert@yodle-package.com").smtpFormatted, "robert@yodle-package.com", "MailUser smtp format incorrect.")
    }
    
    func testMailHeaderStructure() {
        mail?.from = [linus]
        mail?.cc = [anna]
        mail?.bcc = [ninna]
        mail?.replyTo = [lawrence]
        mail?.subject = "Very important subject."
        
        mail?.additionalSMTPHeaders = ["From": "This is a test.", "X-Custom-Field": "A header value."]
        
        let processedHeaders = mail!.processedSMTPHeaders
        
        XCTAssertEqual(processedHeaders["From"], linus.smtpFormatted, "From header field holds incorrect value.") // standard property should be prioritized over additionalSMTPHeaders
        XCTAssertNotNil(processedHeaders["Message-Id"], "Message id is not set.")
        XCTAssertNotNil(processedHeaders["Date"], "Date field is not set.")
        XCTAssert((processedHeaders["To"] == bernhard.smtpFormatted + "," + susan.smtpFormatted) || (processedHeaders["To"] == susan.smtpFormatted + "," + bernhard.smtpFormatted), "To header field holds incorrect value.")
        XCTAssertEqual(processedHeaders["Cc"], anna.smtpFormatted, "Cc header field holds incorrect value.")
        XCTAssertEqual(processedHeaders["Bcc"], ninna.smtpFormatted, "Bcc header field holds incorrect value.")
        XCTAssertEqual(processedHeaders["Reply-To"], lawrence.smtpFormatted, "Reply-To header field holds incorrect value.")
        XCTAssertEqual(processedHeaders["X-Custom-Field"], "A header value.", "Custom header field holds incorrect value.")
        XCTAssertEqual(processedHeaders["Subject"], "Very important subject.", "Subject header field holds incorrect value.")
    }
    
    func testMailHeaderEncoding() {
        let headers = ["Field 1": "My value.", "Field 2": "Another value."].encodeToMailHeaders()
        XCTAssert(headers.contains("Field 1: My value.\r\n") && headers.contains("Field 2: Another value.\r\n"), "Mail headers are encoded incorrectly.")
    }
    
    func testAutomaticLineSplitting() {
        rawTextMail.text = """
        Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatu
        """
        
        let splitTextBody = rawTextMail.getSplitTextBody()
        XCTAssert(splitTextBody.count == 2, "Performed line splitting is incorrect")
        XCTAssertEqual(splitTextBody[0].count, 998, "Line length does not match expected maximum of 998 characters excluding crlf.")
        XCTAssertEqual(splitTextBody[1].count, rawTextMail.text!.count - 998, "Line does not match expected value for the remaining characters.")
        
        rawTextMail.text = "test"
        XCTAssert(rawTextMail.getSplitTextBody().count == 1, "Performed line splitting is incorrect.")
    }
    
    func testTransparencyMechanism() {
        let transparentLines = rawTextMail.applyTransparencyMechanism(lines: [".test", "another", "..cat", ".\r\n"])
        XCTAssertEqual(transparentLines, ["..test", "another", "...cat", "..\r\n"], "Transparency mechanism is not performed correctly.")
    }
    
    func testRawTextEncoding() {
        rawTextMail.text = ".test"
        XCTAssertEqual(rawTextMail.encodeMailData(), "..test", "Incorrect raw text encoding.")
        
        rawTextMail.text = """
        .Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatu
        """
        let encodedText = rawTextMail.encodeMailData()
        XCTAssertEqual(encodedText, "." + rawTextMail.text!.prefix(998) + "\r\n" + rawTextMail.text!.suffix(rawTextMail.text!.count - 998), "Incorrect raw text encoding.")
    }
    
    func testBase64Encoding() {
        let bodyPart = MIMEBodyPart(data: "This is a test. And we have to make sure to reach a maximum line length of at least 76 to see the splitting behavior.".data(using: .utf8)!, encoding: .base64, contentType: .text("plain"), mimeHeaders: [:])
        XCTAssertEqual(bodyPart.encodeToBase64(), "VGhpcyBpcyBhIHRlc3QuIEFuZCB3ZSBoYXZlIHRvIG1ha2Ugc3VyZSB0byByZWFjaCBhIG1heGlt\r\ndW0gbGluZSBsZW5ndGggb2YgYXQgbGVhc3QgNzYgdG8gc2VlIHRoZSBzcGxpdHRpbmcgYmVoYXZp\r\nb3Iu", "Incorrect base64 encoding.")
    }
    
    func testMimeBodyPartHeaderEncoding() {
        let part = MIMEBodyPart(data: "This is a test".data(using: .utf8)!, encoding: .base64, contentType: .video("mp4"), mimeHeaders: ["Content-Type": "text/raw", "Content-Transfer-Encoding": "non existent encoding!"]).encode()
        
        XCTAssert(part.contains("Content-Type: video/mp4"), "MIME header does not populate correct content type.")
        XCTAssert(part.contains("Content-Transfer-Encoding: base64"), "MIME header does not populate correct content transfer encoding.")
    }
}
