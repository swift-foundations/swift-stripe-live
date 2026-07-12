//
//  File.swift
//  rule-law
//
//  Created by Coen ten Thije Boonkkamp on 05/01/2025.
//

import Authenticating
import Foundation
import URLRouting

public typealias Authenticated<
    API: Equatable & Sendable,
    APIRouter: ParserPrinter & Sendable,
    Client: Sendable
> = Authenticating<
    BearerAuth,
    StripeAuthRouter,
    API,
    APIRouter,
    Client
> where APIRouter.Output == API, APIRouter.Input == URLRequestData

extension Authenticated where APIRouter: Sendable {
    public init(
        router: APIRouter,
        buildClient:
            @escaping @Sendable (@escaping @Sendable (API) throws -> URLRequest) -> Client
    ) throws where Auth == BearerAuth, AuthRouter == StripeAuthRouter {
        @Dependency(\.envVars.stripe.baseUrl) var baseUrl
        @Dependency(\.envVars.stripe.secretKey) var secretKey

        guard let secretKey else {
            throw NSError(
                domain: "StripeAuth",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "STRIPE_SECRET_KEY environment variable not set"
                ]
            )
        }

        self = .init(
            baseURL: baseUrl,
            auth: try .init(token: secretKey.rawValue),
            apiRouter: router,
            authRouter: .init(),
            buildClient: buildClient
        )
    }
}

extension Authenticated where APIRouter: Sendable {
    package static func fromEnvironmentVariables(
        router: APIRouter,
        buildClient:
            @escaping @Sendable (
                _ makeRequest: @escaping @Sendable (_ route: API) throws -> URLRequest
            ) -> Client
    ) throws -> Self where Auth == BearerAuth, AuthRouter == StripeAuthRouter {
        try .init(
            router: router,
            buildClient: { buildClient($0) }
        )
    }
}

extension Authenticated where APIRouter: Dependency.Key, APIRouter.Value == APIRouter {
    package init(
        buildClient: @escaping @Sendable () -> Client
    ) throws where Auth == BearerAuth, AuthRouter == StripeAuthRouter {
        @Dependency(APIRouter.self) var router
        self = try .fromEnvironmentVariables(
            router: router
        ) { _ in buildClient() }
    }
}

extension Authenticated where APIRouter: Dependency.Key, APIRouter.Value == APIRouter {
    package init(
        _ buildClient:
            @escaping @Sendable (
                _ makeRequest: @escaping @Sendable (_ route: API) throws -> URLRequest
            ) -> Client
    ) throws where Auth == BearerAuth, AuthRouter == StripeAuthRouter {
        @Dependency(APIRouter.self) var router
        self = try .fromEnvironmentVariables(
            router: router,
            buildClient: buildClient
        )
    }
}

public struct StripeAuthRouter: ParserPrinter, Sendable {
    public typealias Input = URLRequestData
    public typealias Output = BearerAuth
    public typealias Failure = RFC_3986.URI.Routing.Error
    public typealias Body = Never

    public init() {}

    /// The fixed Stripe protocol headers (pinned API version + form content type).
    /// Kept as an opaque computed member so the router stays a stateless `Sendable`
    /// value; `Headers` unifies its field parsers' failures into the routing error
    /// domain, so this member's `Failure` is the plain domain error.
    private var stripeHeaders: some Parser.Bidirectional<URLRequestData, Void, Failure> {
        Headers {
            Field("Stripe-Version") { "2024-12-18.acacia" }

            ContentType { "application/x-www-form-urlencoded" }
        }
    }

    public func parse(_ input: inout Input) throws(Failure) -> Output {
        try stripeHeaders.parse(&input)
        return try BearerAuth.Router().parse(&input)
    }

    public func print(_ output: Output, into input: inout Input) throws(Failure) {
        // Reverse order, mirroring the sequential combinator's printer.
        try BearerAuth.Router().print(output, into: &input)
        try stripeHeaders.print((), into: &input)
    }
}
