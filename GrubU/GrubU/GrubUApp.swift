//
//  GrubUApp.swift
//  GrubU
//
//  Created by user287016 on 4/6/26.
//

// File: GrubU/GrubUApp.swift
import SwiftUI
import FirebaseCore

@main
struct GrubUApp: App {
  init() {
    FirebaseApp.configure()
  }
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
