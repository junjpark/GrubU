//
//  ReportIssueView.swift
//
//  Support ticket form shown from the tracking screens. Writes to
//  `issueReports` and flips the underlying order to `issue_reported`.
//
//  Created by Julie Baguio on 4/20/26.
//

import SwiftUI

struct ReportIssueView: View {
    let order: Order
    let role: OrderStatusRole

    @Environment(\.dismiss) private var dismiss
    @StateObject private var controller = IssueReportController()
    @State private var description: String = ""
    @State private var submitted = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if submitted {
                        successCard
                    } else {
                        formCard
                    }
                }
                .padding(20)
                .padding(.bottom, AppTheme.tabBarBottomClearance)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.pageBackground)
            .navigationTitle("Report an Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(submitted ? "Close" : "Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Form

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What happened?")
                    .font(.headline)
                Text("Describe the problem as clearly as you can. Our team will review and follow up by email.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            descriptionEditor

            if let error = controller.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("This pauses the order's progress while we investigate.", systemImage: "pause.circle")
                Label("Payouts are held until the issue is resolved.", systemImage: "dollarsign.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Button(action: submit) {
                HStack {
                    if controller.isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 4)
                    }
                    Text(controller.isSubmitting ? "Submitting..." : "Submit report")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSubmit ? AppTheme.accent : Color(.separator).opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!canSubmit)
        }
    }

    private var descriptionEditor: some View {
        ZStack(alignment: .topLeading) {
            if description.isEmpty {
                Text("e.g. The wrong items were delivered, the restaurant cancelled, my Grubber never showed up...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary.opacity(0.7))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
            }
            TextEditor(text: $description)
                .frame(minHeight: 180)
                .padding(8)
                .scrollContentBackground(.hidden)
        }
        .background(AppTheme.pageBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.separator).opacity(0.45), lineWidth: 1)
        )
    }

    // MARK: - Success

    private var successCard: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.accent)
            Text("Report submitted")
                .font(.title3.bold())
            Text("Our team has been notified and will reach out by email. You can close this window.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
    }

    // MARK: - Helpers

    private var canSubmit: Bool {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return !controller.isSubmitting && trimmed.count >= 10
    }

    private func submit() {
        controller.submitReport(order: order, role: role, description: description) { success in
            if success { submitted = true }
        }
    }
}
