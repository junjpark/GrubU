//
//  ActivityMainView.swift
//  GrubU
//

import SwiftUI
import FirebaseAuth

struct ActivityMainView: View {
    @EnvironmentObject var authController: AuthController
    @ObservedObject var activityController: ActivityController
    @ObservedObject var tabState: TabState

    private var requestSegmentDot: Bool {
        !activityController.unreadRequestOrderIds.isEmpty
    }

    private var taskSegmentDot: Bool {
        !activityController.unreadTaskOrderIds.isEmpty
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    activitySegment(title: "My Requests", index: 0, showDot: requestSegmentDot)
                    activitySegment(title: "My Tasks", index: 1, showDot: taskSegmentDot)
                }
                .padding(4)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

                if tabState.activitySegment == 0 {
                    MyRequestsListView(orders: activityController.requestedOrders)
                } else {
                    MyTasksListView(orders: activityController.fulfillingTasks)
                }
            }
            .navigationTitle("Activity")
            .onAppear {
                if let uid = authController.userSession?.uid {
                    activityController.fetchActivity(for: uid)
                }
            }
        }
    }

    @ViewBuilder
    private func activitySegment(title: String, index: Int, showDot: Bool) -> some View {
        let selected = tabState.activitySegment == index
        Button {
            tabState.activitySegment = index
        } label: {
            ZStack(alignment: .topTrailing) {
                Text(title)
                    .font(.subheadline.weight(selected ? .semibold : .regular))
                    .foregroundColor(selected ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                if showDot {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: 4)
                        .accessibilityLabel("Unread updates")
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selected ? Color(UIColor.systemBackground) : Color.clear)
                    .shadow(color: selected ? Color.black.opacity(0.06) : .clear, radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
