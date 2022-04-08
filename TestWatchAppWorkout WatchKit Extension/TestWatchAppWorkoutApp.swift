//
//  TestWatchAppWorkoutApp.swift
//  TestWatchAppWorkout WatchKit Extension
//
//  Created by Romain RABOUAN on 06/04/2022.
//

import SwiftUI

@main
struct TestWatchAppWorkoutApp: App {
    @StateObject var workoutManager = WorkoutManager()
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                StartView()
            }
            .sheet(isPresented: $workoutManager.showingSummaryView, content: {
                SummaryView()
            })
            .environmentObject(workoutManager)
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
