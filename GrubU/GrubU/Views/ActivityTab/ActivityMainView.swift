//
//  ActivityMainView.swift
//  
//
//  Created by Julie Baguio on 4/7/26.
//
import SwiftUI

struct ActivityMainView: View {
    @State private var activityType = 0 // 0 = Requested, 1 = Fulfilled
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Activity Type", selection: $activityType) {
                    Text("Requested").tag(0)
                    Text("Fulfilled").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                Spacer()
                
                if activityType == 0 {
                    Text("Orders you are waiting for will appear here.")
                        .foregroundColor(.secondary)
                } else {
                    Text("Orders you are currently delivering will appear here.")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .navigationTitle("Activity")
        }
    }
}
