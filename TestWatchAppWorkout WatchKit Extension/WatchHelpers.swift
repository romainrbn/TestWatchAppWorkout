//
//  WatchHelpers.swift
//  TestWatchAppWorkout WatchKit Extension
//
//  Created by Romain Rabouan on 07/04/2022.
//

import Foundation
import HealthKit

extension HKWorkoutSessionState {
    func statusValue() -> TrainingStatus {
        switch self {
        case .notStarted:
            return .stopped
        case .running:
            return .started
        case .ended:
            return .stopped
        case .paused:
            return .paused
        case .prepared:
            return .stopped
        case .stopped:
            return .stopped
        @unknown default:
            return .stopped
        }
    }
}
