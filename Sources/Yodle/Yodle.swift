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
    
    init(eventLoop: EventLoop, channel: Channel) {
        self.eventLoop = eventLoop
        self.channel = channel
    }
}

public struct YodleClientContext {
     
}
