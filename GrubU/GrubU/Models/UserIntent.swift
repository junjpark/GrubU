//
//  UserIntent.swift
//
//  Stores the first-run "earn vs help" pick in UserDefaults.
//
//  Created by Julie Baguio on 4/7/26.
//

import Foundation

enum PrimaryUserIntent: String, Codable {
    case earn
    case requestHelp
    case both

    var analyticsLabel: String { rawValue }
}

enum UserIntentStore {
    private static func storageKey(uid: String) -> String {
        "grubu.primaryUserIntent.\(uid)"
    }

    static func intent(for uid: String) -> PrimaryUserIntent? {
        guard let raw = UserDefaults.standard.string(forKey: storageKey(uid: uid)) else { return nil }
        return PrimaryUserIntent(rawValue: raw)
    }

    static func setIntent(_ intent: PrimaryUserIntent, for uid: String) {
        UserDefaults.standard.set(intent.rawValue, forKey: storageKey(uid: uid))
    }

    static func hasChosenIntent(for uid: String) -> Bool {
        intent(for: uid) != nil
    }

    /// Earn tab = 0, Request = 1, Profile = 2
    static func defaultTabIndex(for intent: PrimaryUserIntent) -> Int {
        switch intent {
        case .earn, .both:
            return 0
        case .requestHelp:
            return 1
        }
    }
}
