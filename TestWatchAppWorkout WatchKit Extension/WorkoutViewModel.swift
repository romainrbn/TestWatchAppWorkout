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
    
    @Published var secondsElapsed: Int = 0
    
    var session: WCSession
    
    let countPerMinuteUnit = HKUnit(from: "count/min")
    
    var workoutSession: HKWorkoutSession?
    
    var healthStore: HKHealthStore?
    
    var builder: HKLiveWorkoutBuilder?
    
    var timer = Timer()
    
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
        } catch {
            print("Unable to create workout session...")
            return
        }
        
        self.builder = workoutSession!.associatedWorkoutBuilder()
        self.builder?.delegate = self
        self.builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore!, workoutConfiguration: workoutConfiguration)
        
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
    
    func resumeSession() {
        self.workoutSession?.resume()
        createTimer()
    }
    
    func pauseWorkout() {
        self.workoutSession?.pause()
        self.timer.invalidate()
    }
    
    func stopWorkout() {
        self.workoutSession?.stopActivity(with: Date())
        self.workoutSession?.end()
        self.timer.invalidate()
        self.secondsElapsed = 0
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
        
        builder?.beginCollection(withStart: workoutStartDate) { success, error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
        createTimer()
        
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
    
    private func createTimer() {
        var startTime = Date()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { time in
                let current = Date()
                let diffComponents = Calendar.current.dateComponents([.second, .nanosecond], from: startTime, to: current)
                let seconds = (diffComponents.second ?? 0) + (diffComponents.nanosecond ?? 0) / 1_000_000_000
                self.secondsElapsed += seconds
                startTime = current
            })
            
            self.timer.fire()
        }
    }
}

extension WorkoutViewModel: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let trainingStatusMessage = message["trainingStatus"] as? String
            
            if let trainingStatusMessage = trainingStatusMessage, let workoutSession = self.workoutSession {
                switch TrainingStatusHelper.shared.getValueFromString(strValue: trainingStatusMessage) {
                    case .stopped:
                        self.stopWorkout()
                    case .started:
                        workoutSession.startActivity(with: Date())
                    case .restarted:
                        self.resumeSession()
                    case .paused:
                        self.pauseWorkout()
                }
            }
        }
    }
}

extension WorkoutViewModel: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.trainingStatus = toState.statusValue()
            self.session.sendMessage(["trainingStatus": toState.statusValue().rawValue], replyHandler: nil) { error in
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
    }
}

extension WorkoutViewModel: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for sampleType in collectedTypes {
            if let quantityType = sampleType as? HKQuantityType {
                guard let statistic = workoutBuilder.statistics(for: quantityType) else {
                    continue
                }
                guard let quantity = statistic.mostRecentQuantity() else {
                    continue
                }
                
                // Update the UI with new statistics...
                DispatchQueue.main.async {
                    print("New sample quantity: \(quantity)")
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        
    }
}
