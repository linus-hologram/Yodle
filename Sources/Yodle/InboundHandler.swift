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
        
        var responses: [SMTPResponse] = []
        
        while buffer.readableBytes > 0 {
            do {
                responses.append(try processRawSMTPResponse(buffer: &buffer))
            } catch {
                Task { await yodleContext.disconnect() }
                throw error
            }
        }
        
        let _responses = responses
        
        Task { await yodleContext.receive(responses: _responses) }
        
        return .continue
        
    }
    
    func processRawSMTPResponse(buffer: inout ByteBuffer) throws -> SMTPResponse {
        guard let codeDigits = buffer.readString(length: 3) else {
            throw YodleError.InvalidResponseCode(nil)
        }
        
        guard let code = Int(codeDigits) else {
            throw YodleError.InvalidResponseCode(codeDigits)
        }
        
        guard buffer.readableBytes >= 2 else { throw YodleError.InvalidResponse(nil) } // even if there's no text, \r\n is still needed
        
        var message: String = ""
        
        while !message.hasSuffix("\r\n") {
            guard let char = buffer.readString(length: 1) else {
                throw YodleError.InvalidResponse(message)
            }
            
            message.append(char)
        }
        
        if message.first == " " {
            message.removeFirst()
        }
        
        message.removeLast(2) // remove the \r\n
        
        return SMTPResponse(code: code, message: message)
    }
    
}
