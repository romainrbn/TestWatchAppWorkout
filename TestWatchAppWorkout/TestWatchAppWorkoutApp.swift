//
//  TestWatchAppWorkoutApp.swift
//  TestWatchAppWorkout
//
//  Created by Romain RABOUAN on 06/04/2022.
//

import SwiftUI

@main
struct TestWatchAppWorkoutApp: App {
    
    @StateObject var viewModel = ViewModel()
    
    var body: some Scene {
        WindowGroup {
            PhoneStartView()
                .environmentObject(viewModel)
        }
    }
}
