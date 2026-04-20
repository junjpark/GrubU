//
//  IntentRefreshSignal.swift
//
//  Observable bump so the app actually leaves the intent screen. (SwiftUI quirk.)
//
//  Created by Julie Baguio on 4/7/26.
//

import Foundation
import Combine

final class IntentRefreshSignal: ObservableObject {
    @Published private(set) var generation: Int = 0

    func bump() {
        generation += 1
    }
}
