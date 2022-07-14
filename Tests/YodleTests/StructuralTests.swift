//
//  StructuralTests.swift
//  YodleTests
//
//  Created by Linus Bohle on 12.07.22.
//

import XCTest
@testable import Yodle

class StructuralTests: XCTestCase {
    
    var rawTextMail: RawTextMail? = nil
    var mimeMail: MIMEMail? = nil
    
    var linus = MailUser(name: "Linus", email: "linus@yodle-package.com")
    var john = MailUser(name: "John", email: "john@yodle-package.com")
    var ninna = MailUser(name: "Ninna", email: "ninna@yodle-package.com")
    var anna = MailUser(name: "Anna", email: "anna@yodle-package.com")
    var lawrence = MailUser(name: "Lawrence", email: "lawrence@yodle-package.com")
    var bernhard = MailUser(name: "Bernhard", email: "bernhard@yodle-package.com")
    var susan = MailUser(name: "Susan", email: "susan@yodle-package.com")
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        rawTextMail = RawTextMail(sender: john, recipients: [bernhard, susan])
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        rawTextMail = nil
    }
    
    func testMailUserStructure() {
        XCTAssertEqual(linus.smtpFormatted, "Linus <linus@yodle-package.com>", "MailUser smtp format incorrect.")
        XCTAssertEqual(MailUser(name: nil, email: "robert@yodle-package.com").smtpFormatted, "robert@yodle-package.com", "MailUser smtp format incorrect.")
    }
    
    func testMailHeaderStructure() {
        rawTextMail?.from = [linus]
        rawTextMail?.cc = [anna]
        rawTextMail?.bcc = [ninna]
        rawTextMail?.replyTo = [lawrence]
        rawTextMail?.subject = "Very important subject."
        
        rawTextMail?.additionalSMTPHeaders = ["From": "This is a test.", "X-Custom-Field": "A header value."]
        
        let processedHeaders = rawTextMail!.processedSMTPHeaders
        
        XCTAssertEqual(processedHeaders["From"], linus.smtpFormatted, "From header field holds incorrect value.") // standard property should be prioritized over additionalSMTPHeaders
        XCTAssertNotNil(processedHeaders["Message-Id"], "Message id is not set.")
        XCTAssertNotNil(processedHeaders["Date"], "Date field is not set.")
        XCTAssertEqual(processedHeaders["To"], bernhard.smtpFormatted + "," + susan.smtpFormatted, "To header field holds incorrect value.")
        XCTAssertEqual(processedHeaders["Cc"], anna.smtpFormatted, "Cc header field holds incorrect value.")
        XCTAssertEqual(processedHeaders["Bcc"], ninna.smtpFormatted, "Bcc header field holds incorrect value.")
        XCTAssertEqual(processedHeaders["Reply-To"], lawrence.smtpFormatted, "Reply-To header field holds incorrect value.")
        XCTAssertEqual(processedHeaders["X-Custom-Field"], "A header value.", "Custom header field holds incorrect value.")
        XCTAssertEqual(processedHeaders["Subject"], "Very important subject.", "Subject header field holds incorrect value.")
    }
    
    func testMailHeaderEncoding() {
        let headers = ["Field 1": "My value.", "Field 2": "Another value."]
        print(headers.encodeToMailHeaders())
        XCTAssertEqual(headers.encodeToMailHeaders(), "Field 1: My value.\r\nField 2: Another value.\r\n", "Mail headers are encoded incorrectly.")
    }
    
    func testAutomaticLineSplitting() throws {
        rawTextMail!.text = """
        Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu f
        """
        
//        let splitTextBody = try rawTextMail?.getSplitTextBody()
//        print(splitTextBody)
//        XCTAssert(try rawTextMail?.getSplitTextBody().count == 2, "Performed line splitting is incorrect")
    }
}
