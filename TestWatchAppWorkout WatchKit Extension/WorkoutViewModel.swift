//
//  WorkoutViewModel.swift
//  TestWatchAppWorkout WatchKit Extension
//
//  Created by Romain RABOUAN on 06/04/2022.
//

import Foundation
import SwiftUI
import HealthKit
import WatchConnectivity

class WorkoutViewModel: NSObject, ObservableObject {
    
    @Published var heartRateLabelText: String = "- bpm"
    
    @Published var isWorkoutStarted = false
    @Published var isWorkoutPaused = false
    
    @Published var trainingStatus = TrainingStatus.stopped
    
    var session: WCSession
    
    let countPerMinuteUnit = HKUnit(from: "count/min")
    
    var workoutSession: HKWorkoutSession?
    
    var healthStore: HKHealthStore?
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        self.session.delegate = self
        session.activate()
    }
    
    func startWorkout() {
        healthStore = HKHealthStore()
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .coreTraining
        workoutConfiguration.locationType = .indoor
        
        let workoutStartDate: Date = Date()
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore!, configuration: workoutConfiguration)
            self.workoutSession?.delegate = self
            self.workoutSession?.startActivity(with: workoutStartDate)
        //    self.changeTrainingStatus(to: .started)
        } catch {
            print("Unable to create workout session...")
        }
        
        requestHealthKitAuthorization(healthStore: healthStore!) { [weak self] (result) in
            
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("Error while requesting HealthKit data: \(error.localizedDescription)")
                return
            case .success(_):
                self.createStreamingHeartRateQuery(workoutStartDate: workoutStartDate)
            }
        }
    }
    
    func pauseWorkout() {
        self.workoutSession?.pause()
      //  self.changeTrainingStatus(to: .paused)
    }
    
    func stopWorkout() {
        self.workoutSession?.stopActivity(with: Date())
        self.workoutSession?.end()
     //   self.changeTrainingStatus(to: .stopped)
    }
    
    private func requestHealthKitAuthorization(healthStore: HKHealthStore, completion: @escaping (Result<Bool, Error>) -> ()) {
        let typesToShare = Set([HKObjectType.workoutType()])
        let typesToRead = Set([
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ])
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { granted, error in
            guard granted, error == nil else {
                completion(.failure(error!))
                return
            }
            completion(.success(true))
        }
    }
    
    private func createStreamingHeartRateQuery(workoutStartDate: Date) {
        
        print("Create stream for heart rate")
        
        let predicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictStartDate)
        let type = HKObjectType.quantityType(forIdentifier: .heartRate)
        let heartRateQuery = HKAnchoredObjectQuery(type: type!, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { query, samples, deletedObjects, anchor, error in
        }
        
        heartRateQuery.updateHandler = {
            (query, samples, deletedObjects, anchor, error) -> Void in
            self.getHeartRateSamples(samples: samples)
        }
        
        healthStore?.execute(heartRateQuery)
    }
    
    private func getHeartRateSamples(samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {
            print("No samples for heart rate...")
            return
        }
        
        for sample in heartRateSamples {
            let heartRate = sample.quantity
            let heartRateDouble = heartRate.doubleValue(for: countPerMinuteUnit)
            
            DispatchQueue.main.async { [weak self] in
                self?.session.sendMessage(["heartRate": heartRateDouble], replyHandler: nil)
                self?.heartRateLabelText = "\(heartRateDouble) bpm"
            }
        }
    }
    
//    private func changeTrainingStatus(to status: TrainingStatus) {
//        self.trainingStatus = status
//
//        self.session.sendMessage(["trainingStatus": status.rawValue], replyHandler: nil)
//    }
}

extension WorkoutViewModel: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if message["message"] as? String == "" {
                self.heartRateLabelText = "- bpm"
            } else {
                self.heartRateLabelText = message["message"] as? String ?? "Unknown"
            }
        }
    }
}

extension WorkoutViewModel: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.trainingStatus = toState.statusValue()
            self.session.sendMessage(["trainingStatus": toState.statusValue()], replyHandler: nil) { error in
                print("Error sending message: \(error.localizedDescription)")
            }

            
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
    }
}

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
