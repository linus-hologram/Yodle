//
//  InboundHandler.swift
//  
//
//  Created by Linus Bohle on 15.05.22.
//

import Foundation
import NIOCore

class YodleInboundHandler: ByteToMessageDecoder {
    typealias InboundOut = Never
    
    let yodleContext: YodleClientContext
    
    init(context: YodleClientContext) {
        yodleContext = context
    }
    
    func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        if buffer.readableBytesView.firstIndex(of: 0x0A) == nil { return .needMoreData } // need more data if there is no LF occuring in the byte buffer
        
        do {
            let response = try processRawSMTPResponse(buffer: &buffer)
            Task { await yodleContext.receiveOne(response: response) }
        } catch {
            Task { await yodleContext.disconnect() }
            throw error
        }
        
        return .continue
    }
    
    func decodeLast(context: ChannelHandlerContext, buffer: inout ByteBuffer, seenEOF: Bool) throws -> DecodingState {
        if buffer.readableBytes == 0 {
            Task { try await yodleContext.deliverResponses() }
            return .continue
        }
        
        if buffer.readableBytesView.firstIndex(of: 0x0A) == nil {
            throw YodleError.InvalidResponseMessage(buffer.readString(length: buffer.readableBytes))
        } // throw error if the buffer isn't empty and doesn't contain a LF occurrence

        do {
            let response = try processRawSMTPResponse(buffer: &buffer)
            Task {
                await yodleContext.receiveOne(response: response)
                try await yodleContext.deliverResponses()
            }
        } catch {
            Task { await yodleContext.disconnect() }
            throw error
        }
        
        return .continue
    }
    
    func processRawSMTPResponse(buffer: inout ByteBuffer) throws -> SMTPResponse {
        guard let codeDigits = buffer.readString(length: 3) else {
            throw YodleError.UnexpectedError("Inbound byte buffer insufficiently propagated. This should not have happened.")
        }
        
        guard let code = Int(codeDigits) else {
            throw YodleError.InvalidResponseCode(codeDigits)
        }
        
        guard let crIndex = buffer.readableBytesView.firstIndex(of: 0x0D),
              let lfIndex = buffer.readableBytesView.firstIndex(of: 0x0A),
              lfIndex - crIndex == 1, // they must follow after another
              lfIndex + 3 <= 511 // stop after 512 characters including CRLF and the 3 digits in the beginning; https://datatracker.ietf.org/doc/html/rfc5321#section-4.5.3.1.5
        else {
            throw YodleError.InvalidResponseMessage(buffer.readString(length: buffer.readableBytes))
        }
        
        guard var message = buffer.readString(length: crIndex) else { throw YodleError.UnexpectedError("Could not read string from byte buffer. This should not have happened.")}
        buffer.moveReaderIndex(forwardBy: 2) // skip the CRLF sequence
        
        if message.first == " " || message.first == "-" {
            message.removeFirst()
        }
        
        return SMTPResponse(code: code, message: message)
    }
}
