//
//  MarketFeedView.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI

struct MarketFeedView: View {
    // Grabbing the global authController to handle logouts
    @EnvironmentObject var authController: AuthController
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "bag.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.orange)
                
                Text("Welcome to the Market!")
                    .font(.title)
                    .bold()
                
                Text("Open student requests will appear here soon.")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Temporary Log Out button to test your Auth architecture
                Button(action: {
                    authController.signOut()
                }) {
                    Text("Log Out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
            .navigationTitle("Market Feed")
        }
    }
}

#Preview {
    MarketFeedView().environmentObject(AuthController())
}
