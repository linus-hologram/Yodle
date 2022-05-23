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
    
    init() {
        fatalError("not yet implemented")
    }
    
    func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        fatalError("not yet implemented")
    }
    
}
