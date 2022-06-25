import Foundation
import NIO
import NIOPosix
import NIOSSL
import CryptoKit

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
    private(set) var supportedExtensions: [SMTPExtension] = []
    private(set) var supportedAuthentication: [String] = []
    
    init (handshakeResponse: [SMTPResponse]) {
        for r in handshakeResponse {
            let parameters = r.message.components(separatedBy: " ").map({ $0.uppercased() })
            
            if let ext = SMTPExtension(rawValue: parameters[0]) {
                supportedExtensions.append(ext)
                
                if ext == .AUTH {
                    supportedAuthentication = Array(parameters.dropFirst())
                }
            }
        }
    }
}

public struct Yodle {
    public static func connect(eventLoop: EventLoop, hostname: String, port: Int, ssl: YodleSSLOption) async throws -> YodleClient {
        var yodleContext: YodleClientContext?
        
        var client = try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<YodleClient, Error>) in
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
                    continuation.resume(returning: YodleClient(hostname: hostname, eventLoop: eventLoop, channel: try result.get(), context: yodleContext!))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        })
        
        do {
            try await client.performHandshake()
            
            if case .STARTTLS(let configuration) = ssl {
                guard client.handshake.supportedExtensions.contains(.STARTTLS) else {
                    throw YodleError.ExtensionNotSupported(.STARTTLS)
                }
                
                try await client.performStartTLS(configuration: configuration)
            }
            
            return client
        } catch {
            await client.shutdown()
            throw error
        }
    }
}

public struct YodleClient {
    let hostname: String
    let eventLoop: EventLoop
    let channel: Channel
    let context: YodleClientContext
    
    var handshake: ClientHandshake!
    
    init(hostname: String, eventLoop: EventLoop, channel: Channel, context: YodleClientContext) {
        self.hostname = hostname
        self.eventLoop = eventLoop
        self.channel = channel
        self.context = context
    }
    
    func shutdown() async {
        _ = try? await context.send(message: .Quit)
        await context.disconnect()
        try? await channel.close()
    }
    
    func sendMail(mail: SMTPEncodableMail) async throws {
        try await context.send(message: .StartMail(mail.sender.email)).expectResponseStatus(codes: .commandOK)
        
        for recipient in mail.recipients {
            try await context.send(message: .Recipient(recipient.email)).expectResponseStatus(codes: .commandOK)
        }
        
        try await context.send(message: .StartMailData).expectResponseStatus(codes: .startMailInput)
        try await context.send(message: .MailData(mail)).expectResponseStatus(codes: .commandOK)
    }
    
    internal mutating func performHandshake() async throws {
        do {
            // Attempt 1: EHLO
            let handshakeResponse = try await context.send(message: SMTPCommand.Ehlo(hostname: hostname))
            try handshakeResponse.expectResponseStatus(codes: .commandOK)
            self.handshake = ClientHandshake(handshakeResponse: handshakeResponse)
            await context.updateSupportedExtensions(extensions: self.handshake.supportedExtensions)
        } catch {
            // Attempt 2: HELO
            let handshakeResponse = try await context.send(message: SMTPCommand.Helo(hostname: hostname))
            try handshakeResponse.expectResponseStatus(codes: .commandOK, error: .HandshakeError)
            self.handshake = ClientHandshake(handshakeResponse: handshakeResponse)
            await context.updateSupportedExtensions(extensions: self.handshake.supportedExtensions)
        }
    }
    
    internal mutating func performStartTLS(configuration: YodleSSLConfiguration) async throws {
        try await context.send(message: SMTPCommand.StartTLS).expectResponseStatus(codes: .serviceReady, error: .ExtensionError(.STARTTLS))
        
        let sslContext = try NIOSSLContext(configuration: configuration.makeTLSConfiguration())
        let sslHandler = try NIOSSLClientHandler(context: sslContext, serverHostname: hostname)
        
        try await self.channel.pipeline.addHandler(sslHandler, position: .first)
        try await performHandshake()
    }
    
    // https://developers.google.com/gmail/imap/xoauth2-protocol
    // https://docs.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth
    public func performXOAuth2(username: String, accessToken: String) async throws {
        guard handshake.supportedAuthentication.contains(SASLMethods.XOAUTH2.rawValue) else {
            throw YodleError.AuthenticationNotSupported(.XOAUTH2)
        }
        
        let response = try await context.send(message: .XOAuth2(username: username, token: accessToken))
        try response.expectResponseStatus(codes: .authenticationSuccessful, error: .AuthenticationFailure(response))
    }
    
    // https://datatracker.ietf.org/doc/html/rfc4616
    public func performPlainAuth(authorizationIdentity: String?, authenticationIdentity: String, password: String) async throws {
        guard handshake.supportedAuthentication.contains(SASLMethods.PLAIN.rawValue) else {
            throw YodleError.AuthenticationNotSupported(.PLAIN)
        }
        
        let response = try await context.send(message: .PlainAuth(authorization: authorizationIdentity, authentication: authenticationIdentity, password: password))
        try response.expectResponseStatus(codes: .authenticationSuccessful, error: .AuthenticationFailure(response))
    }
    
    // https://www.ietf.org/archive/id/draft-murchison-sasl-login-00.txt
    public func performLoginAuth(username: String, password: String) async throws {
        guard handshake.supportedAuthentication.contains(SASLMethods.LOGIN.rawValue) else {
            throw YodleError.AuthenticationNotSupported(.LOGIN)
        }
        
        let initialLoginResponse = try await context.send(message: .LoginAuth)
        try initialLoginResponse.expectResponseStatus(codes: .containingChallenge, error: .AuthenticationFailure(initialLoginResponse))
        
        let usernameLoginResponse = try await context.send(message: .LoginUser(username: username))
        try usernameLoginResponse.expectResponseStatus(codes: .containingChallenge, error: .AuthenticationFailure(usernameLoginResponse))
        
        let passwordLoginResponse = try await context.send(message: .LoginPassword(password: password))
        try passwordLoginResponse.expectResponseStatus(codes: .authenticationSuccessful, error: .AuthenticationFailure(passwordLoginResponse))
    }
    
    // https://mailtrap.io/blog/smtp-auth/
    // https://www.rfc-editor.org/rfc/rfc2195.html
    // TODO - Test correctness using rfc above
    public func performCramMD5(username: String, password: String) async throws {
        guard handshake.supportedAuthentication.contains(SASLMethods.CRAMMD5.rawValue) else {
            throw YodleError.AuthenticationNotSupported(.CRAMMD5)
        }
        
        let initialResponse = try await context.send(message: .StartCramMD5Auth)
        try initialResponse.expectResponseStatus(codes: .containingChallenge, error: .AuthenticationFailure(initialResponse))
        
        guard let serverChallenge = initialResponse.first?.message.base64Decoded?.data(using: .utf8) else { throw YodleError.AuthenticationFailure(initialResponse) }
        guard let passwordData = password.data(using: .utf8) else { throw YodleError.ParsingError("password parameter could not be parsed to data using utf8 encoding") }
        
        let key = SymmetricKey(data: passwordData)
        // https://stackoverflow.com/questions/39075043/how-to-convert-data-to-hex-string-in-swift - convert to lowercase hex digits
        let solvedChallenge = HMAC<Insecure.MD5>.authenticationCode(for: serverChallenge, using: key).map{ String(format: "%02hhx", $0) }.joined()
        
        let solvedChallengeResponse = try await context.send(message: .SubmitCramMD5Challenge(username: username, solvedChallenge: solvedChallenge))
        try solvedChallengeResponse.expectResponseStatus(codes: .authenticationSuccessful, error: .AuthenticationFailure(solvedChallengeResponse))
    }
}
