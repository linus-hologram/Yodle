import NIO
import NIOPosix
import NIOSSL

public enum YodleSSLOption {
    case insecure
    case TLS(YodleSSLConfiguration)
    case STARTTLS(YodleSSLConfiguration)
}

public enum YodleSSLConfiguration {
    case standard
    case custom(TLSConfiguration)
    
    internal func makeTLSConfiguration() -> TLSConfiguration {
        switch self {
        case .standard:
            return TLSConfiguration.makeClientConfiguration()
        case .custom(let configuration):
            return configuration
        }
    }
}

internal struct ClientHandshake {
    init?() async throws {
        // perform EHLO procedure
        return nil
    }
}

public struct Yodle {
    public static func connect(eventLoop: EventLoop, hostname: String, port: Int, ssl: YodleSSLOption) async throws -> YodleClient {
        var yodleContext: YodleClientContext?
        
        let client = try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<YodleClient, Error>) in
            ClientBootstrap(group: eventLoop).channelInitializer { channel in
                yodleContext = YodleClientContext(eventLoop: eventLoop, channel: channel)
                
                let yodleDecoder = ByteToMessageHandler(YodleInboundHandler(context: yodleContext!))
                let yodleSerializer = MessageToByteHandler(YodleOutboundHandler())
                
                var handlers: [ChannelHandler] = [yodleDecoder, yodleSerializer]
                
                switch ssl {
                case .insecure, .STARTTLS(_):
                    break
                case .TLS(let yodleSSLConfiguration):
                    do {
                        let sslContext = try NIOSSLContext(configuration: yodleSSLConfiguration.makeTLSConfiguration())
                        let sslClientHandler = try NIOSSLClientHandler(context: sslContext, serverHostname: hostname)
                        
                        handlers.insert(sslClientHandler, at: 0)
                    } catch {
                        return eventLoop.makeFailedFuture(error)
                    }
                }
                
                return channel.pipeline.addHandlers(handlers)
            }.connect(host: hostname, port: port).whenComplete { result in
                do {
                    continuation.resume(returning: YodleClient(eventLoop: eventLoop, channel: try result.get(), context: yodleContext!))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        })
        
//        if case .STARTTLS(let configuration) = ssl {
//
//        }
        
        return client
    }
}

public struct YodleClient {
    let eventLoop: EventLoop
    let channel: Channel
    let context: YodleClientContext
    
    init(eventLoop: EventLoop, channel: Channel, context: YodleClientContext) {
        self.eventLoop = eventLoop
        self.channel = channel
        self.context = context
    }
}

public actor YodleClientContext {
    let eventLoop: EventLoop
    let channel: Channel
    
    internal var processingQueue: [EventLoopPromise<[SMTPResponse]>] = []
    
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
