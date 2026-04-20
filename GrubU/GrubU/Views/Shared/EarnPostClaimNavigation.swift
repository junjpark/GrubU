//
//  EarnPostClaimNavigation.swift
//
//  After accepting an order, push TaskTrackingView from the Earn stack.
//
//  Created by Julie Baguio on 4/20/26.
//

import SwiftUI
import Combine

final class EarnNavigationCoordinator: ObservableObject {
    @Published var postClaimOrder: Order?

    func clearPostClaimIfMatches(orderId: String?) {
        guard let id = orderId, !id.isEmpty, postClaimOrder?.id == id else { return }
        postClaimOrder = nil
    }
}

private struct EarnPostClaimNavigationKey: EnvironmentKey {
    static let defaultValue: EarnNavigationCoordinator? = nil
}

extension EnvironmentValues {
    var earnPostClaimNavigation: EarnNavigationCoordinator? {
        get { self[EarnPostClaimNavigationKey.self] }
        set { self[EarnPostClaimNavigationKey.self] = newValue }
    }
}
