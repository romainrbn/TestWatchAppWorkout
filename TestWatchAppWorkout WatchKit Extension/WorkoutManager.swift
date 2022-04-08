//
//  WorkoutManager.swift
//  TestWatchAppWorkout WatchKit Extension
//
//  Created by Romain Rabouan on 07/04/2022.
//

import Foundation
import HealthKit
import WatchConnectivity

class WorkoutManager: NSObject, ObservableObject {
    var selectedWorkout: HKWorkoutActivityType? {
        didSet {
            guard let selectedWorkout = selectedWorkout else {
                return
            }
            
            startWorkout(workoutType: selectedWorkout)
        }
    }
    
  //  let watchConnectivity = WatchSessionManager.shared
    
    var watchConnectivity: WCSession
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    @Published var running = false
    @Published var showingSummaryView: Bool = false {
        didSet {
            // Sheet dismissed
            if showingSummaryView == false {
                resetWorkout()
            }
        }
    }
    
    // Workout Metrics
    @Published var averageHeartRate: Double = 0
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var distance: Double = 0
    @Published var workout: HKWorkout?
    
    override init() {
        let defaultSession: WCSession = .default
        self.watchConnectivity = defaultSession
        
        super.init()
        
        self.watchConnectivity.delegate = self
        watchConnectivity.activate()
        
        NotificationCenter.default.addObserver(self, selector: #selector(endWorkout), name: .workoutDidStop, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(startWorkoutFromiPhone), name: .workoutDidStart, object: nil)
    }
    
    func startWorkout(workoutType: HKWorkoutActivityType) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .indoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            /// - Warning: Handle exceptions here.
            print(error.localizedDescription)
            return
        }
        
        builder?.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )
        
        session?.delegate = self
        builder?.delegate = self
        
        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate, completion: { success, error in
            // The workout has started
        })
    }
    
    /// - Important: Here, pass the workout type as parameter.
    @objc
    func startWorkoutFromiPhone() {
        self.selectedWorkout = .coreTraining
    }
    
    func requestAuthorization() {
        
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.activitySummaryType()
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error = error {
                print("Not authorized: \(error.localizedDescription)")
                return
            }
        }
    }
    
    // MARK: - State Control
    
    func pause() {
        self.watchConnectivity.sendMessage([String.togglePause: true]) { replies in
            print(replies)
        } errorHandler: { error in
            print("Error on pause from AW: \(error.localizedDescription)")
        }
        session?.pause()
    }
    
    func resume() {
        self.watchConnectivity.sendMessage([String.togglePause: false]) { replies in
            print(replies)
        } errorHandler: { error in
            print("Error on resume from AW: \(error.localizedDescription)")
        }
        session?.resume()
    }
    
    func togglePause() {
        if running == true {
            pause()
        } else {
            resume()
        }
    }
    
    @objc
    func endWorkout() {
        self.watchConnectivity.sendMessage([String.trainingIsRunning: false]) { replies in
            print(replies)
        } errorHandler: { error in
            print("Error on end from AW: \(error.localizedDescription)")
        }
        session?.end()
        showingSummaryView = true
    }
    
    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else {
            return
        }
        
        DispatchQueue.main.async {
            switch statistics.quantityType {
                case HKQuantityType.quantityType(forIdentifier: .heartRate):
                    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                    self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                    
                case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                    let energyUnit = HKUnit.kilocalorie()
                    self.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
                    
                case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
                    HKQuantityType.quantityType(forIdentifier: .distanceCycling):
                    let meterUnit = HKUnit.meter()
                    self.distance = statistics.sumQuantity()?.doubleValue(for: meterUnit) ?? 0
                    
                default:
                    return
            }
        }
    }
    
    func resetWorkout() {
        selectedWorkout = nil
        builder = nil
        session = nil
        workout = nil
        activeEnergy = 0
        averageHeartRate = 0
        heartRate = 0
        distance = 0
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
        
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.running = toState == .running
        }
        
        // Wait for the session to transition states before ending the builder.
        if toState == .ended {
            builder?.endCollection(withEnd: date, completion: { [weak self] (success, error) in
                guard let self = self else { return }
                // Save the workout to the HealthKit Database
                self.builder?.finishWorkout(completion: { workout, error in
                    DispatchQueue.main.async {
                        self.workout = workout
                    }
                })
            })
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { return }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            // Update the published values.
            updateForStatistics(statistics)
        }
    }
}

extension WorkoutManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession Activation complete for Apple Watch!")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        print("DID RECEIVE MESSAGE ON AW")
        
        DispatchQueue.main.async { [weak self] in
            
            var replyValues = Dictionary<String, Any>()
            
            guard let self = self else { return }
            
            if let trainingStatus = message[String.trainingIsRunning] as? Bool {
                if trainingStatus {
                    self.sendNotification(with: .workoutDidStart)
                    replyValues["watchStatus"] = "workoutDidStart"
                } else {
                    self.sendNotification(with: .workoutDidStop)
                    replyValues["watchStatus"] = "workoutDidStop"
                }
            }
            
            
            replyHandler(replyValues)
        }
    }
    
    private func sendNotification(with name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }
    
}
