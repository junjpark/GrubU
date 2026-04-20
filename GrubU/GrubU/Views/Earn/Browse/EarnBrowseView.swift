//
//  EarnBrowseView.swift
//
//  Scroll of open gigs; cards link to the accept-job screen.
//
//  Created by Julie Baguio on 4/7/26.
//

import SwiftUI

struct EarnBrowseView: View {
    @ObservedObject var marketController: MarketController
    @EnvironmentObject var tabState: TabState

    var body: some View {
        Group {
            if marketController.openOrders.isEmpty {
                earnBrowseEmptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(marketController.openOrders) { order in
                            NavigationLink(destination: OrderPreviewView(order: order)) {
                                OpenJobCard(order: order)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var earnBrowseEmptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 24)
            Image(systemName: "leaf.circle")
                .font(.system(size: 52))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("Nothing available right now.")
                .font(.title3)
            Text("Check back soon or try requesting help.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                tabState.selectedTab = 1
            } label: {
                Text("Need help instead? Switch to Request")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct OpenJobCard: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(order.restaurantName)
                .font(.headline)
                .foregroundStyle(.primary)

            HStack {
                Label("$\(order.bountyAmount, specifier: "%.2f")", systemImage: "dollarsign.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                Spacer()
                if let posted = relativePosted(order.createdAt) {
                    Text(posted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(locationLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var locationLine: String {
        if let loc = order.taskLocation, !loc.isEmpty {
            return loc
        }
        return "On campus"
    }

    private func relativePosted(_ date: Date?) -> String? {
        guard let date else { return nil }
        return Self.relFormatter.localizedString(for: date, relativeTo: Date())
    }

    private static let relFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()
}
