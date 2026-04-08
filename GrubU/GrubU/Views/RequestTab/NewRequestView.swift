//
//  NewRequestView.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI

struct NewRequestView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Post a New Request")
                    .font(.title2)
                    .bold()
                
                Text("This is where students will enter their order details, restaurant, and bounty amount.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .navigationTitle("New Request")
        }
    }
}
