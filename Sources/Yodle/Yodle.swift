import NIO
import NIOPosix

public struct Yodle {
    public static func connect(eventLoop: EventLoop, hostname: String, port: Int) async throws -> YodleClient {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<YodleClient, Error>) in
            ClientBootstrap(group: eventLoop).channelInitializer { channel in
                let yodleDecoder = ByteToMessageHandler(YodleInboundHandler())
                let yodleSerializer = MessageToByteHandler(YodleOutboundHandler())
                
                return channel.pipeline.addHandlers([yodleDecoder, yodleSerializer])
            }.connect(host: hostname, port: port).whenComplete { result in
                do {
                    continuation.resume(returning: YodleClient(eventLoop: eventLoop, channel: try result.get()))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        })
    }
}

public struct YodleClient {
    let eventLoop: EventLoop
    let channel: Channel
    let context: YodleClientContext
    
    init(eventLoop: EventLoop, channel: Channel) {
        self.eventLoop = eventLoop
        self.channel = channel
        self.context = YodleClientContext(eventLoop: eventLoop, channel: channel)
    }
}

public actor YodleClientContext {
    let eventLoop: EventLoop
    let channel: Channel
    
    private var processingQueue: [EventLoopPromise<[SMTPResponse]>] = []
    
    init(eventLoop: EventLoop, channel: Channel) {
        self.eventLoop = eventLoop
        self.channel = channel
    }
    
    func send(message: SMTPCommand) async throws -> [SMTPResponse] {
        return try await withCheckedThrowingContinuation({ continuation in
            let result: EventLoopFuture<[SMTPResponse]> = eventLoop.flatSubmit {
                let promise: EventLoopPromise<[SMTPResponse]> = self.eventLoop.makePromise()
                
                self.processingQueue.append(promise)
                
                _ = self.channel.writeAndFlush(message)
                
                return promise.futureResult
            }
            
            result.whenComplete { result in
                do {
                    continuation.resume(returning: try result.get())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func receive(responses: [SMTPResponse]) {
        let finishedPromise = processingQueue.removeFirst()
        finishedPromise.succeed(responses)
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
