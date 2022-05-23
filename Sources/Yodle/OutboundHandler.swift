//
//  OutboundHandler.swift
//  
//
//  Created by Linus Bohle on 15.05.22.
//

import Foundation
import NIOCore

class YodleOutboundHandler: MessageToByteEncoder {
    typealias OutboundIn = SMTPCommand
    
    func encode(data: SMTPCommand, out: inout ByteBuffer) throws {
        fatalError("not yet implemented")
    }
}
