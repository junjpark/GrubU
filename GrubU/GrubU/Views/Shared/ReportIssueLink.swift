//
//  ReportIssueLink.swift
//
//  "Experiencing a problem with your order? Report an issue." footer used
//  at the bottom of every order tracking screen.
//
//  Created by Julie Baguio on 4/20/26.
//

import SwiftUI

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
