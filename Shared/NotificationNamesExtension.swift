//
//  NotificationNamesExtension.swift
//  TestWatchAppWorkout
//
//  Created by Romain Rabouan on 08/04/2022.
//

import Foundation

extension Notification.Name {
    static let workoutDidStart = Notification.Name("WorkoutDidStart")
    static let workoutDidPause = Notification.Name("WorkoutDidPause")
    static let workoutDidResume = Notification.Name("WorkoutDidResume")
    static let workoutDidStop = Notification.Name("WorkoutDidStop")
}

extension String {
    static let trainingIsRunning = "trainingIsRunning"
    static let togglePause = "togglePause"
}
