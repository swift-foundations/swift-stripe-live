//
//  Stripe Checkout Sessions Client.live.Compat_Swift_6_3.swift
//  swift-stripe-live
//
//  ┌───────────────────────────────────────────────────────────────────────────┐
//  │  6.3.x-COMPAT PATH — §A9-CLASS — RETIRES-OR-REDISPOSES AT THE 6.4 FLIP.    │
//  └───────────────────────────────────────────────────────────────────────────┘
//
//  Sibling of `Stripe Customers Client.live.Compat_Swift_6_3.swift` — same shape,
//  same contract. `create` works and is wire-identical to the ordinary path; every
//  other endpoint throws `Compat_Swift_6_3.Error.unsupportedRoute`.
//
//  NOTE — `retrieve` IS NOT AVAILABLE ON THIS PATH. The checkout-session STATUS read
//  (used by the post-payment return page) calls `checkoutSessions.retrieve`, which is
//  a THIRD endpoint and deliberately OUT OF SCOPE for this compat path (Ruling J,
//  constraint 1: two endpoints only; a third crashing site is a new ask). On 6.3.x
//  that read SIGSEGVs through the ordinary path anyway — here it throws a named error
//  instead. It is restored by the 6.4 flip.
//
//  Grep token: `Compat_Swift_6_3`.
//  Catalog: swift-institute/Research/swift-compiler-bug-catalog.md §A9.
//

import Foundation
import Stripe_Checkout_Types
import Stripe_Live_Shared

extension Stripe.Checkout.Sessions.Client {
    /// 6.3.x-compat (§A9) live client — `create` only.
    ///
    /// Identical to ``live(makeRequest:)`` in every respect except the request-maker.
    ///
    /// - Warning: 6.3.x-compat path, §A9-class. RETIRES-OR-REDISPOSES AT THE 6.4 FLIP.
    package static func compat_Swift_6_3() throws(Compat_Swift_6_3.Error) -> Self {
        let base = try Compat_Swift_6_3.baseRequestData()
        let router = Stripe.Checkout.Sessions.API.Router.Compat_Swift_6_3()

        return .live(makeRequest: { route in
            // Reject every non-`create` route BEFORE the router sees it.
            guard case .create = route else {
                throw Compat_Swift_6_3.Error.unsupportedRoute(
                    "Stripe.Checkout.Sessions.API.\(route)"
                )
            }
            return try Compat_Swift_6_3.makeRequest(router: router, base: base, route: route)
        })
    }
}

extension Stripe.Checkout.Sessions {
    /// 6.3.x-compat (§A9) `Authenticated` value — register this in the composition root
    /// in place of ``liveValue`` while on a 6.3.x toolchain.
    ///
    /// - Warning: 6.3.x-compat path, §A9-class. RETIRES-OR-REDISPOSES AT THE 6.4 FLIP.
    public static var compat_Swift_6_3: Stripe.Checkout.Sessions.Authenticated {
        // The supplied router-based `makeRequest` is deliberately DISCARDED (`_`).
        try! Stripe.Checkout.Sessions.Authenticated { _ in try! .compat_Swift_6_3() }
    }
}
