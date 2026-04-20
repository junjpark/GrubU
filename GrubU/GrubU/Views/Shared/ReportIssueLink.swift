//
//  ReportIssueLink.swift
//
//  "Experiencing a problem with your order? Report an issue." footer used
//  at the bottom of every order tracking screen.
//
//  Created by Julie Baguio on 4/20/26.
//

import SwiftUI

/// Prominent banner replacing the normal tracking content while an order is
/// under review by the support team.
struct UnderInvestigationCard: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 52))
                .foregroundStyle(AppTheme.accent)

            Text("This order is currently being investigated.")
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            Text("Check back later — our team is reviewing this order and will reach out by email as soon as there's an update.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .profileModalCardStyle()
    }
}

struct ReportIssueLink: View {
    let order: Order
    let role: OrderStatusRole

    @State private var showingSheet = false

    var body: some View {
        Group {
            if order.status == IssueReportController.issueStatus {
                alreadyReportedBanner
            } else {
                reportButton
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var reportButton: some View {
        Button {
            showingSheet = true
        } label: {
            VStack(spacing: 2) {
                Text("Experiencing a problem with your order?")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Report an issue")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .underline()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSheet) {
            ReportIssueView(order: order, role: role)
        }
    }

    private var alreadyReportedBanner: some View {
        VStack(spacing: 4) {
            Label("Issue submitted — our team is on it.", systemImage: "checkmark.seal.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
            Text("We'll follow up by email.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}
