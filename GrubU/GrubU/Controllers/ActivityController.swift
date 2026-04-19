//
//  ActivityController.swift
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
    private var isFirstRequestSnapshot = true
    private var isFirstTaskSnapshot = true

    /// While set, status updates for this request are not treated as “unread” (user is on the detail screen).
    private var activeDetailRequestOrderId: String?
    /// While set, status updates for this task are not treated as “unread” (fulfiller is on the detail screen).
    private var activeDetailTaskOrderId: String?

    var hasAnyUnreadActivity: Bool {
        !unreadRequestOrderIds.isEmpty || !unreadTaskOrderIds.isEmpty
    }

    func fetchActivity(for uid: String) {
        guard listeners.isEmpty else { return }

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

    func markRequestOrderSeen(_ orderId: String) {
        var next = unreadRequestOrderIds
        next.remove(orderId)
        unreadRequestOrderIds = next
    }

    func markTaskOrderSeen(_ orderId: String) {
        var next = unreadTaskOrderIds
        next.remove(orderId)
        unreadTaskOrderIds = next
    }

    func setActiveRequestDetailOrderId(_ id: String?) {
        activeDetailRequestOrderId = id
    }

    func setActiveTaskDetailOrderId(_ id: String?) {
        activeDetailTaskOrderId = id
    }

    private func applyRequestSnapshot(_ orders: [Order]) {
        requestedOrders = orders
        let newMap = Dictionary(uniqueKeysWithValues: orders.compactMap { o -> (String, String)? in
            guard let id = o.id else { return nil }
            return (id, o.status)
        })

        if isFirstRequestSnapshot {
            lastRequestStatusById = newMap
            isFirstRequestSnapshot = false
            return
        }

        var unread = unreadRequestOrderIds
        for (id, status) in newMap {
            if let old = lastRequestStatusById[id], old != status, id != activeDetailRequestOrderId {
                unread.insert(id)
            }
        }
        unread = unread.filter { newMap[$0] != nil }
        unreadRequestOrderIds = unread
        lastRequestStatusById = newMap
    }

    private func applyTaskSnapshot(_ orders: [Order]) {
        fulfillingTasks = orders
        let newMap = Dictionary(uniqueKeysWithValues: orders.compactMap { o -> (String, String)? in
            guard let id = o.id else { return nil }
            return (id, o.status)
        })

        if isFirstTaskSnapshot {
            lastTaskStatusById = newMap
            isFirstTaskSnapshot = false
            return
        }

        var unread = unreadTaskOrderIds
        for (id, status) in newMap {
            if let old = lastTaskStatusById[id], old != status, id != activeDetailTaskOrderId {
                unread.insert(id)
            }
        }
        unread = unread.filter { newMap[$0] != nil }
        unreadTaskOrderIds = unread
        lastTaskStatusById = newMap
    }
}
