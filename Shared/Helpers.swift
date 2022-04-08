//
//  TrainingStatus.swift
//  TestWatchAppWorkout WatchKit Extension
//
//  Created by Romain RABOUAN on 06/04/2022.
//

import Foundation
import HealthKit

enum TrainingStatus: String {
    case stopped = "Stopped"
    case paused = "Paused"
    case started = "Started"
    case restarted = "Restarted"
}

struct TrainingStatusHelper {
    
    static let shared = TrainingStatusHelper()
    
    func getValueFromString(strValue: String) -> TrainingStatus {
        switch strValue {
            case "Stopped":
                return .stopped
            case "Paused":
                return .paused
            case "Started":
                return .started
            case "Restarted":
                return .restarted
            default:
                return .stopped
        }
    }
}

extension HKWorkoutActivityType: Identifiable {
    public var id: UInt {
        rawValue
    }
    
    var name: String {
        switch self {
            case .coreTraining:
                return "Simulate a Core Training workout 🏋️‍♂️"
            case .yoga:
                return "Simulate a Yoga workout 🧘‍♀️"
            default:
                return "-"
        }
    }
    
    var smallName: String {
        switch self {
            case .coreTraining:
                return "Core Training 🏋️‍♂️"
            case .yoga:
                return "Yoga 🧘‍♀️"
            default:
                return "-"
        }
    }
}

