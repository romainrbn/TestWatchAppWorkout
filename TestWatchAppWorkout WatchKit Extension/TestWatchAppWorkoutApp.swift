//
//  TestWatchAppWorkoutApp.swift
//  TestWatchAppWorkout WatchKit Extension
//
//  Created by Romain RABOUAN on 06/04/2022.
//

import SwiftUI

@main
struct TestWatchAppWorkoutApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
