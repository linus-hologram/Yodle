//
//  ClientContext.swift
//  
//
//  Created by Linus Bohle on 07.06.22.
//

import Foundation
import NIOCore

public actor YodleClientContext {
    let eventLoop: EventLoop
    let channel: Channel
    var supportedExtensions: [SMTPExtension] = []
    
    internal var processingQueue: [EventLoopPromise<[SMTPResponse]>] = []
    internal var currentResponseBuffer: [SMTPResponse] = []
    
    init(eventLoop: EventLoop, channel: Channel) {
        self.eventLoop = eventLoop
        self.channel = channel
    }
    
    func updateSupportedExtensions(extensions: [SMTPExtension]) {
        self.supportedExtensions = extensions
    }
    
    func send(message: SMTPCommand) async throws -> [SMTPResponse] {
//        return try await withCheckedThrowingContinuation({ continuation in
        // use task queue lib
        let result: EventLoopFuture<[SMTPResponse]> = eventLoop.flatSubmit {
            let promise: EventLoopPromise<[SMTPResponse]> = self.eventLoop.makePromise()
            
            self.processingQueue.append(promise)
            
            _ = self.channel.writeAndFlush((message, self.supportedExtensions))
            
            return promise.futureResult
        }
        
        return try await result.get()
    }
    
    func receiveOne(response: SMTPResponse) {
        currentResponseBuffer.append(response)
    }
    
    func deliverResponses() throws {
        guard !currentResponseBuffer.isEmpty else { throw YodleError.UnexpectedError("Client context response buffer was empty.")}
        let finishedPromise = processingQueue.removeFirst()
        finishedPromise.succeed(currentResponseBuffer)
        currentResponseBuffer.removeAll()
    }
        
    func disconnect() {
        for promise in processingQueue {
            promise.fail(YodleError.Disconnected)
        }
        
        processingQueue.removeAll()
    }
    
    deinit {
        disconnect()
    }
}
