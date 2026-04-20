//
//  RequestNavigationCoordinator.swift
//
//  After checkout, tracking is pushed on the hub’s outer stack so “back” returns
//  to the Request tab root instead of the review screen.
//

import Combine
import SwiftUI

final class RequestNavigationCoordinator: ObservableObject {
    /// Recreates the browse `NavigationStack` so checkout/review are not left underneath tracking.
    @Published var browseResetToken = 0
    /// Shown via the outer `NavigationStack` in `RequestHubView`.
    @Published var orderToTrackAfterPost: Order?

    func completeCheckoutNavigateToTracking(_ order: Order) {
        browseResetToken += 1
        orderToTrackAfterPost = order
    }
}
