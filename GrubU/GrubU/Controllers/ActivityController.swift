//
//  ActivityController.swift
//
//  Live Firestore lists for your requests & fulfiller jobs + unread dots.
//
//  Created by Julie Baguio on 4/7/26.
//
import Foundation
import FirebaseFirestore
import Combine
import SwiftUI

class ActivityController: ObservableObject {
    @Published var requestedOrders: [Order] = []
    @Published var fulfillingTasks: [Order] = []
    /// Orders in “My Requests” with a status change the user has not opened yet.
    @Published private(set) var unreadRequestOrderIds: Set<String> = []
    /// Orders in “My Tasks” with a status change the user has not opened yet.
    @Published private(set) var unreadTaskOrderIds: Set<String> = []

    private var db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []

    private var lastRequestStatusById: [String: String] = [:]
    private var lastTaskStatusById: [String: String] = [:]
    private var hasSeededRequest = false
    private var hasSeededTask = false

    /// While set, status updates for this request are not treated as “unread” (user is on the detail screen).
    private var activeDetailRequestOrderId: String?
    /// While set, status updates for this task are not treated as “unread” (fulfiller is on the detail screen).
    private var activeDetailTaskOrderId: String?

    private var currentUid: String?

    // MARK: - Persistence keys (scoped per signed-in user)

    private var requestStatusKey: String?  { currentUid.map { "activity.lastRequestStatusById.\($0)" } }
    private var taskStatusKey: String?     { currentUid.map { "activity.lastTaskStatusById.\($0)" } }
    private var unreadRequestKey: String?  { currentUid.map { "activity.unreadRequestIds.\($0)" } }
    private var unreadTaskKey: String?     { currentUid.map { "activity.unreadTaskIds.\($0)" } }

    var hasAnyUnreadActivity: Bool {
        !unreadRequestOrderIds.isEmpty || !unreadTaskOrderIds.isEmpty
    }

    func fetchActivity(for uid: String) {
        // If we’re re-attaching for the same user, do nothing.
        if currentUid == uid && !listeners.isEmpty { return }

        // If switching users, clear the previous session’s state first.
        if currentUid != uid { stopActivity() }
        currentUid = uid
        loadPersistedState()

        let reqListener = db.collection("orders")
            .whereField("requesterId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                let orders = snapshot?.documents.compactMap { try? $0.data(as: Order.self) } ?? []
                DispatchQueue.main.async {
                    self.applyRequestSnapshot(orders)
                }
            }

        let fulListener = db.collection("orders")
            .whereField("fulfillerId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                let orders = snapshot?.documents.compactMap { try? $0.data(as: Order.self) } ?? []
                DispatchQueue.main.async {
                    self.applyTaskSnapshot(orders)
                }
            }

        listeners.append(contentsOf: [reqListener, fulListener])
    }

    func stopActivity() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        requestedOrders = []
        fulfillingTasks = []
        unreadRequestOrderIds = []
        unreadTaskOrderIds = []
        lastRequestStatusById = [:]
        lastTaskStatusById = [:]
        hasSeededRequest = false
        hasSeededTask = false
        activeDetailRequestOrderId = nil
        activeDetailTaskOrderId = nil
        currentUid = nil
    }

    func markRequestOrderSeen(_ orderId: String) {
        guard unreadRequestOrderIds.contains(orderId) else { return }
        var next = unreadRequestOrderIds
        next.remove(orderId)
        unreadRequestOrderIds = next
        persistRequestUnread()
    }

    func markTaskOrderSeen(_ orderId: String) {
        guard unreadTaskOrderIds.contains(orderId) else { return }
        var next = unreadTaskOrderIds
        next.remove(orderId)
        unreadTaskOrderIds = next
        persistTaskUnread()
    }

    func setActiveRequestDetailOrderId(_ id: String?) {
        activeDetailRequestOrderId = id
    }

    func setActiveTaskDetailOrderId(_ id: String?) {
        activeDetailTaskOrderId = id
    }

    // MARK: - Snapshot handlers

    private func applyRequestSnapshot(_ orders: [Order]) {
        requestedOrders = Self.sortedByNewest(orders)
        let newMap = Dictionary(uniqueKeysWithValues: orders.compactMap { o -> (String, String)? in
            guard let id = o.id else { return nil }
            return (id, o.status)
        })

        // First snapshot AFTER a fresh sign-in (no persisted state) just seeds the map
        // so we don't dot every existing order. If we have persisted state, compare
        // against it so we catch updates that happened while the app was closed.
        if !hasSeededRequest && lastRequestStatusById.isEmpty {
            lastRequestStatusById = newMap
            hasSeededRequest = true
            persistRequestStatus()
            return
        }

        var unread = unreadRequestOrderIds
        for (id, newStatus) in newMap {
            if id == activeDetailRequestOrderId { continue }
            let oldStatus = lastRequestStatusById[id]
            if shouldDotRequestSide(oldStatus: oldStatus, newStatus: newStatus) {
                unread.insert(id)
            }
        }
        // Drop unread entries for orders that have disappeared.
        unread = unread.filter { newMap[$0] != nil }

        unreadRequestOrderIds = unread
        lastRequestStatusById = newMap
        hasSeededRequest = true
        persistRequestStatus()
        persistRequestUnread()
    }

    private func applyTaskSnapshot(_ orders: [Order]) {
        fulfillingTasks = Self.sortedByNewest(orders)
        let newMap = Dictionary(uniqueKeysWithValues: orders.compactMap { o -> (String, String)? in
            guard let id = o.id else { return nil }
            return (id, o.status)
        })

        if !hasSeededTask && lastTaskStatusById.isEmpty {
            lastTaskStatusById = newMap
            hasSeededTask = true
            persistTaskStatus()
            return
        }

        var unread = unreadTaskOrderIds
        for (id, newStatus) in newMap {
            if id == activeDetailTaskOrderId { continue }
            let oldStatus = lastTaskStatusById[id]
            if shouldDotTaskSide(oldStatus: oldStatus, newStatus: newStatus) {
                unread.insert(id)
            }
        }
        unread = unread.filter { newMap[$0] != nil }

        unreadTaskOrderIds = unread
        lastTaskStatusById = newMap
        hasSeededTask = true
        persistTaskStatus()
        persistTaskUnread()
    }

    /// Newest first. Orders without a `createdAt` (e.g. offline‑written docs that
    /// haven't resolved their server timestamp yet) are pushed to the bottom.
    private static func sortedByNewest(_ orders: [Order]) -> [Order] {
        orders.sorted { lhs, rhs in
            switch (lhs.createdAt, rhs.createdAt) {
            case let (l?, r?): return l > r
            case (_?, nil):    return true
            case (nil, _?):    return false
            case (nil, nil):   return false
            }
        }
    }

    // MARK: - Dot rules
    //
    // Order status flow:
    //   requester creates  -> "open"
    //   fulfiller accepts  -> "claimed"
    //   fulfiller orders   -> "ordered"
    //   fulfiller delivers -> "delivered"
    //   requester confirms -> "completed"
    //
    // The user only sees a red dot when the OTHER party advances the order.

    private func shouldDotRequestSide(oldStatus: String?, newStatus: String) -> Bool {
        // Brand-new orders on the requester side mean THEY just created it; no dot.
        guard let old = oldStatus, old != newStatus else { return false }
        // Status changes driven by the fulfiller.
        return newStatus == "claimed" || newStatus == "ordered" || newStatus == "delivered"
    }

    private func shouldDotTaskSide(oldStatus: String?, newStatus: String) -> Bool {
        // Brand-new tasks on the fulfiller side mean THEY just accepted; no dot.
        guard let old = oldStatus, old != newStatus else { return false }
        // Only the requester transitions an order to "completed".
        return newStatus == "completed"
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        let d = UserDefaults.standard
        if let k = requestStatusKey, let map = d.dictionary(forKey: k) as? [String: String] {
            lastRequestStatusById = map
            hasSeededRequest = true
        }
        if let k = taskStatusKey, let map = d.dictionary(forKey: k) as? [String: String] {
            lastTaskStatusById = map
            hasSeededTask = true
        }
        if let k = unreadRequestKey, let arr = d.array(forKey: k) as? [String] {
            unreadRequestOrderIds = Set(arr)
        }
        if let k = unreadTaskKey, let arr = d.array(forKey: k) as? [String] {
            unreadTaskOrderIds = Set(arr)
        }
    }

    private func persistRequestStatus() {
        guard let k = requestStatusKey else { return }
        UserDefaults.standard.set(lastRequestStatusById, forKey: k)
    }
    private func persistTaskStatus() {
        guard let k = taskStatusKey else { return }
        UserDefaults.standard.set(lastTaskStatusById, forKey: k)
    }
    private func persistRequestUnread() {
        guard let k = unreadRequestKey else { return }
        UserDefaults.standard.set(Array(unreadRequestOrderIds), forKey: k)
    }
    private func persistTaskUnread() {
        guard let k = unreadTaskKey else { return }
        UserDefaults.standard.set(Array(unreadTaskOrderIds), forKey: k)
    }
}
